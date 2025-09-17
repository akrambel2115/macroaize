import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
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
  int get totalPages => _cachedAllRecipes != null
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
      final filtered = _cachedAllRecipes!.where((r) {
        return r.title.toLowerCase().contains(q) || r.description.toLowerCase().contains(q);
      }).toList();
      _allRecipes.assignAll(filtered);
    }
    try {
      update();
    } catch (_) {
    }
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
    final mockData = _generateMockData();
    
    _cachedTopRecipes = mockData['top']!;
    _cachedAllRecipes = mockData['all']!;
    _lastLoadTime = DateTime.now();
    
    _topRecipes.assignAll(_cachedTopRecipes!);
  }

  void _handleLoadingError(dynamic error, [StackTrace? stackTrace]) {
    // Detailed debug logging (kept out of user-facing notifications)
    try {
      debugPrint('Recipes load failed. Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: ${stackTrace.toString()}');
    } catch (_) {
      // ignore logging failures
    }

    // Show user-friendly, localized error message
    NotificationService.showError('failed_to_load_recipes');
  }

  Map<String, List<Recipe>> _generateMockData() {
    // Optimized mock data generation - create objects once and reuse
    final mockTopRecipes = [
      const Recipe(
        id: '1',
        title: 'Blueberry Almond Smoothie',
        imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400&h=300&fit=crop',
        duration: 10,
        calories: 400,
        carbs: 45,
        protein: 14,
        fat: 12,
        difficulty: 'Easy',
        tags: ['Healthy', 'Quick'],
        description: 'A refreshing and nutritious smoothie packed with antioxidants and protein.',
        instructions: ['Combine blueberries, almond milk, almond butter and ice.', 'Blend until smooth and serve.'],
      ),
      const Recipe(
        id: '2',
        title: 'Chicken & Quinoa Stuffed Peppers',
        imageUrl: 'https://images.unsplash.com/photo-1604909052743-94e838986d24?w=400&h=300&fit=crop',
        duration: 40,
        calories: 700,
        carbs: 60,
        protein: 42,
        fat: 20,
        difficulty: 'Medium',
        tags: ['Protein', 'Healthy'],
        description: 'Colorful bell peppers stuffed with a protein-rich quinoa and chicken mixture.',
        instructions: ['Cook quinoa and shred chicken.', 'Mix with spices and stuff into halved peppers.', 'Bake until peppers are tender.'],
      ),
      const Recipe(
        id: '3',
        title: 'Peanut Butter Banana Toast',
        imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&h=300&fit=crop',
        duration: 10,
        calories: 350,
        carbs: 36,
        protein: 10,
        fat: 18,
        difficulty: 'Easy',
        tags: ['Quick', 'Breakfast'],
        description: 'Simple and satisfying toast with natural peanut butter and fresh banana slices.',
        instructions: ['Toast bread.', 'Spread peanut butter and top with sliced banana.'],
      ),
      const Recipe(
        id: '4',
        title: 'Veggie & Turkey Stir-Fry',
        imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop',
        duration: 30,
        calories: 750,
        carbs: 55,
        protein: 48,
        fat: 22,
        difficulty: 'Medium',
        tags: ['Protein', 'Vegetables'],
        description: 'A colorful and flavorful stir-fry with lean turkey and fresh vegetables.',
        instructions: ['Sear turkey strips until browned.', 'Stir-fry vegetables and combine with turkey and sauce.'],
      ),
    ];

    // Base set for all recipes
    final baseAll = [
      ...mockTopRecipes,
      const Recipe(
        id: '5',
        title: 'Greek Yogurt Parfait',
        imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&h=300&fit=crop',
        duration: 5,
        calories: 280,
        carbs: 32,
        protein: 18,
        fat: 6,
        difficulty: 'Easy',
        tags: ['Healthy', 'Quick'],
        description: 'Layered parfait with Greek yogurt, berries, and granola.',
        instructions: ['Layer yogurt, berries and granola in a glass.', 'Serve chilled.'],
      ),
      const Recipe(
        id: '6',
        title: 'Salmon with Roasted Vegetables',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&h=300&fit=crop',
        duration: 45,
        calories: 650,
        carbs: 30,
        protein: 40,
        fat: 28,
        difficulty: 'Medium',
        tags: ['Omega-3', 'Healthy'],
        description: 'Baked salmon with a colorful medley of roasted seasonal vegetables.',
        instructions: ['Season salmon and roast vegetables.', 'Bake salmon until flaky and serve with vegetables.'],
      ),
      const Recipe(
        id: '7',
        title: 'Avocado Toast Supreme',
        imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=400&h=300&fit=crop',
        duration: 15,
        calories: 420,
        carbs: 32,
        protein: 8,
        fat: 24,
        difficulty: 'Easy',
        tags: ['Healthy', 'Breakfast'],
        description: 'Elevated avocado toast with cherry tomatoes, feta, and a drizzle of olive oil.',
        instructions: ['Toast bread.', 'Top with mashed avocado, tomatoes and feta.'],
      ),
      const Recipe(
        id: '8',
        title: 'Chocolate Protein Balls',
        imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&h=300&fit=crop',
        duration: 20,
        calories: 180,
        carbs: 20,
        protein: 10,
        fat: 8,
        difficulty: 'Easy',
        tags: ['Protein', 'Snack'],
        description: 'No-bake protein balls with dates, nuts, and dark chocolate.',
        instructions: ['Mix dates, nuts and cocoa.', 'Roll into balls and chill.'],
      ),
    ];

    // Expand to a larger mock list for pagination by creating variants
    final mockAllRecipes = <Recipe>[];
    for (int i = 0; i < 6; i++) { // 6 batches ~ 6 * 8 = 48 items
      for (final r in baseAll) {
        mockAllRecipes.add(Recipe(
          id: '${r.id}-${i + 1}',
          title: '${r.title} #${i + 1}',
          imageUrl: r.imageUrl,
          duration: r.duration + (i % 3) * 5,
          calories: r.calories + (i % 4) * 20,
          difficulty: r.difficulty,
          tags: r.tags,
          description: r.description,
        ));
      }
    }

    return {
      'top': mockTopRecipes,
      'all': mockAllRecipes,
    };
  }
}
