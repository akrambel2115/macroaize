import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:foodcalorietracker/Model/Recipe.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipeDetailScreen.dart';

class RecipesController extends GetxController {
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingPage = false.obs;
  final RxList<Recipe> _topRecipes = <Recipe>[].obs;
  final RxList<Recipe> _allRecipes = <Recipe>[].obs;
  final RxInt _currentPageIndex = 0.obs;

  List<Recipe>? _cachedTopRecipes;
  List<Recipe>? _cachedAllRecipes;
  DateTime? _lastLoadTime;

  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const int _recipesPerPage = 8;

  bool get isLoading => _isLoading.value;
  bool get isLoadingPage => _isLoadingPage.value;
  List<Recipe> get topRecipes => _topRecipes;
  List<Recipe> get allRecipes => _allRecipes;
  int get currentPageIndex => _currentPageIndex.value;
  int get currentPageNumber => _currentPageIndex.value + 1;
  int get totalPages =>
      _cachedAllRecipes != null
          ? ((_cachedAllRecipes!.length - 1) ~/ _recipesPerPage) + 1
          : 0;
  bool get hasPreviousPage => _currentPageIndex.value > 0;
  bool get hasNextPage => _currentPageIndex.value < totalPages - 1;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadRecipes();
    });
  }

  @override
  void onClose() {
    _isLoading.close();
    _isLoadingPage.close();
    _topRecipes.close();
    _allRecipes.close();
    _currentPageIndex.close();
    _debounce?.cancel();
    super.onClose();
  }

  void filterRecipes(String query, {bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _applyFilter(query);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _applyFilter(query);
    });
  }

  void clearSearch() {
    filterRecipes('', immediate: true);
  }

  void _applyFilter(String query) {
    if (_cachedAllRecipes == null) return;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _loadCurrentPage();
    } else {
      final filtered =
          _cachedAllRecipes!.where((r) {
            return r.title.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q);
          }).toList();
      _allRecipes.assignAll(filtered);
    }
    try {
      update();
    } catch (_) {}
  }

  Future<void> loadRecipes({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid()) {
      _topRecipes.assignAll(_cachedTopRecipes!);
      _loadCurrentPage();
      update();
      return;
    }

    try {
      _isLoading(true);
      update();

      await Future.delayed(const Duration(milliseconds: 500));

      await _loadAndCacheData();

      _currentPageIndex(0);
      _loadCurrentPage();
    } catch (e, st) {
      debugPrint('Error loading recipes: $e');
      debugPrint(st.toString());
      _handleLoadingError(e, st);
    } finally {
      _isLoading(false);
      update();
    }
  }

  Future<void> refreshRecipes() async {
    await loadRecipes(forceRefresh: true);
  }

  Future<void> goToNextPage() async {
    if (!hasNextPage) return;
    await _changePage(_currentPageIndex.value + 1);
  }

  Future<void> goToPreviousPage() async {
    if (!hasPreviousPage) return;
    await _changePage(_currentPageIndex.value - 1);
  }

  Future<void> goToPage(int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= totalPages) return;
    await _changePage(pageIndex);
  }

  Future<void> _changePage(int newPageIndex) async {
    if (_isLoadingPage.value) return;

    try {
      _isLoadingPage(true);
      update();

      await Future.delayed(const Duration(milliseconds: 200));

      _currentPageIndex(newPageIndex);
      _loadCurrentPage();
    } catch (e) {
      debugPrint('Error changing page: $e');
    } finally {
      _isLoadingPage(false);
      update();
    }
  }

  void _loadCurrentPage() {
    if (_cachedAllRecipes == null) return;

    final start = _currentPageIndex.value * _recipesPerPage;
    final end = (start + _recipesPerPage).clamp(0, _cachedAllRecipes!.length);

    if (start < _cachedAllRecipes!.length) {
      final pageRecipes = _cachedAllRecipes!.sublist(start, end);
      _allRecipes.assignAll(pageRecipes);
    } else {
      _allRecipes.clear();
    }
  }

  void openRecipeDetails(Recipe recipe) {
    Get.to(() => RecipeDetailScreen(recipe: recipe));
  }

  bool _isCacheValid() {
    return _cachedTopRecipes != null &&
        _cachedAllRecipes != null &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheTimeout;
  }

  Future<void> _loadAndCacheData() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'lib/constant/recipeLibrary.json',
      );
      final List<dynamic> data = json.decode(jsonStr);

      final all =
          data.map((e) {
            final Map<String, dynamic> item = Map<String, dynamic>.from(
              e as Map,
            );

            // Prefer explicit English keys
            if (item['title_en'] != null &&
                (item['title'] == null || item['title'].toString().isEmpty)) {
              item['title'] = item['title_en'];
            }
            if (item['difficulty_en'] != null &&
                (item['difficulty'] == null ||
                    item['difficulty'].toString().isEmpty)) {
              item['difficulty'] = item['difficulty_en'];
            }
            if (item['tags_en'] != null &&
                (item['tags'] == null || (item['tags'] as List).isEmpty)) {
              item['tags'] = item['tags_en'];
            }
            if (item['description_en'] != null &&
                (item['description'] == null ||
                    item['description'].toString().isEmpty)) {
              item['description'] = item['description_en'];
            }
            if (item['instructions_en'] != null &&
                (item['instructions'] == null ||
                    (item['instructions'] as List).isEmpty)) {
              item['instructions'] = item['instructions_en'];
            }
            if (item['ingredients_en'] != null &&
                (item['ingredients'] == null ||
                    (item['ingredients'] as List).isEmpty)) {
              item['ingredients'] = item['ingredients_en'];
            }

            return Recipe.fromJson(item);
          }).toList();

      // pick the first <= 8items from the list
      final top = all.length <= 8 ? List<Recipe>.from(all) : all.sublist(0, 8);

      _cachedTopRecipes = top;
      _cachedAllRecipes = all;
      _lastLoadTime = DateTime.now();

      _topRecipes.assignAll(_cachedTopRecipes!);
    } catch (e, st) {
      debugPrint('Failed to load recipeLibrary.json: $e');
      debugPrint(st.toString());

      // Fallback to existing mock generator
      final mockData = _generateMockData();
      _cachedTopRecipes = mockData['top']!;
      _cachedAllRecipes = mockData['all']!;
      _lastLoadTime = DateTime.now();
      _topRecipes.assignAll(_cachedTopRecipes!);
    }
  }

  void _handleLoadingError(dynamic error, [StackTrace? stackTrace]) {
    try {
      debugPrint('Recipes load failed. Error: $error');
      if (stackTrace != null)
        debugPrint('StackTrace: ${stackTrace.toString()}');
    } catch (_) {}

    NotificationService.showError('failed_to_load_recipes');
  }

  Map<String, List<Recipe>> _generateMockData() {
    return {'top': <Recipe>[], 'all': <Recipe>[]};
  }
}
