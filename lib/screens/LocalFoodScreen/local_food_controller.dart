import 'package:flutter/material.dart';
import 'dart:async';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../Model/calorie_history_model.dart';
import '../../Model/sql_calorie_model.dart';
import '../../Model/sql_daily_calorie_model.dart';
import '../../SharePrefHelper/constant_user_master.dart';
import '../../constant/font_family.dart';
import '../../routes/app_routes.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/premium_required_dialog.dart';
import '../../shared/services/rate_us_service.dart';
import '../../shared/services/widget_promotion_service.dart';
import '../../shared/services/meal_sync_service.dart';
import '../HomeScreen/home_controller.dart';
import '../leadingScreen/leading_controller.dart';

class LocalFoodController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  TextEditingController textController = TextEditingController();
  List<FoodItem> filteredItems = [];
  Timer? _searchDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  bool isFiltering = false;
  final dbHelper = DatabaseHelper();
  final _appUserService = AppUserService();
  List<FoodItem> breakfastFoods = [];

  List<FoodItem> lunchFoods = [];

  List<FoodItem> snackFoods = [];

  List<FoodItem> dinnerFoods = [];

  // load food library
  Future<void> _loadFoodLibrary() async {
    try {
      final foodLibraryUrl = dotenv.env['FOOD_LIBRARY'] ?? '';
      String jsonStr;

      if (foodLibraryUrl.isNotEmpty) {
        // Fetch from remote URL
        final response = await http.get(Uri.parse(foodLibraryUrl));
        if (response.statusCode == 200) {
          jsonStr = response.body;
        } else {
          // Fallback to local file if remote fails
          jsonStr = await rootBundle.loadString(
            'lib/constant/foodLibrary.json',
          );
        }
      } else {
        // Fallback to local file if URL not set
        jsonStr = await rootBundle.loadString('lib/constant/foodLibrary.json');
      }

      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      final locale = Get.locale?.languageCode ?? 'en';

      final mapped =
          data.map((e) {
            final m = e as Map<String, dynamic>;
            String name = _pickByLocale(m, 'name', locale);
            String quantity = _pickByLocale(m, 'quantity', locale);
            int calories = _toInt(m['calories']);
            int carbs = _toInt(m['carbs']);
            int protein = _toInt(m['protein']);
            int fats = _toInt(m['fats']);
            return FoodItem(
              name: name,
              calories: calories,
              carbs: carbs,
              protein: protein,
              fats: fats,
              quantity: quantity,
            );
          }).toList();

      final List<FoodItem> all = mapped;
      breakfastFoods = all;
      lunchFoods = all;
      snackFoods = all;
      dinnerFoods = all;
      if (type == "Breakfast" || type == "BreakFast") {
        filteredItems = breakfastFoods;
      } else if (type == "Lunch") {
        filteredItems = lunchFoods;
      } else if (type == "snack(s)") {
        filteredItems = snackFoods;
      } else {
        filteredItems = dinnerFoods;
      }
      update();
    } catch (_) {}
  }

  String _pickByLocale(Map<String, dynamic> m, String key, String locale) {
    final en = m['${key}_en']?.toString() ?? '';
    final fr = m['${key}_fr']?.toString() ?? en;
    final ar = m['${key}_ar']?.toString() ?? en;
    switch (locale) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    final s = v.toString();
    return double.tryParse(s)?.round() ?? 0;
  }

  String type = "";
  bool isEditing = false;
  // selected items
  final Set<int> selectedIndices = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    type = argument['value'];
    if (type == "Breakfast" || type == "BreakFast") {
      filteredItems = breakfastFoods;
    } else if (type == "Lunch") {
      filteredItems = lunchFoods;
    } else if (type == "snack(s)") {
      filteredItems = snackFoods;
    } else {
      filteredItems = dinnerFoods;
    }
    await _loadFoodLibrary();
    await _loadPersistedFoodsFromDb();
  }

  void toggleEditMode() {
    isEditing = !isEditing;
    if (!isEditing) selectedIndices.clear();
    update();
  }

  void toggleSelect(int index) {
    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
    }
    update();
  }

  /// enter edit mode
  void selectAndEnterEdit(int index) {
    if (!isEditing) isEditing = true;
    selectedIndices.clear();
    selectedIndices.add(index);
    update();
  }

  void addCustomFood(FoodItem item) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    filteredItems.insert(0, item);
    update();
    NotificationService.showSuccess('food_added_success');
    _saveCurrentFoodsToDb();
  }

  void editFoodAt(int index, FoodItem item) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (index >= 0 && index < filteredItems.length) {
      filteredItems[index] = item;
      update();
      NotificationService.showSuccess('food_updated_success');
      _saveCurrentFoodsToDb();
    }
  }

  void deleteSelected(BuildContext context) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (selectedIndices.isEmpty) return;
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.theme.cardColor,
            title: Text('delete_items_title'.tr),
            content: Text(
              'delete_items_message'.trParams({
                'count': selectedIndices.length.toString(),
              }),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'delete'.tr,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final indices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        filteredItems.removeAt(i);
      }
      selectedIndices.clear();
      isEditing = false;
      update();
      NotificationService.showSuccess(
        'food_deleted_success',
        params: {'count': indices.length.toString()},
      );
      _saveCurrentFoodsToDb();
    }
  }

  Future<void> _saveCurrentFoodsToDb() async {
    try {
      final t = type;
      await dbHelper.deleteLocalFoodsByType(t);
      for (final f in filteredItems) {
        await dbHelper.insertLocalFood({
          'name': f.name,
          'quantity': f.quantity,
          'calories': f.calories,
          'carbs': f.carbs,
          'protein': f.protein,
          'fats': f.fats,
          'type': t,
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPersistedFoodsFromDb() async {
    try {
      final t = type;
      final rows = await dbHelper.getLocalFoods(t);
      if (rows.isEmpty) return;
      final items = rows.map((r) => FoodItem.fromJson(r)).toList();
      if (type == "Breakfast" || type == "BreakFast") {
        breakfastFoods = items;
      } else if (type == "Lunch") {
        lunchFoods = items;
      } else if (type == "snack(s)") {
        snackFoods = items;
      } else {
        dinnerFoods = items;
      }
      filteredItems = items;
      update();
    } catch (_) {}
  }

  /// filter with debounce
  void searchFilter(String query, {bool immediate = false}) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    void runFilter() {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        if (type == "Breakfast" || type == "BreakFast") {
          filteredItems = breakfastFoods;
        } else if (type == "Lunch") {
          filteredItems = lunchFoods;
        } else if (type == "snack(s)") {
          filteredItems = snackFoods;
        } else {
          filteredItems = dinnerFoods;
        }
      } else {
        if (type == "Breakfast" || type == "BreakFast") {
          filteredItems =
              breakfastFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else if (type == "Lunch") {
          filteredItems =
              lunchFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else if (type == "snack(s)") {
          filteredItems =
              snackFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        } else {
          filteredItems =
              dinnerFoods
                  .where((item) => item.name.toLowerCase().contains(q))
                  .toList();
        }
      }

      isFiltering = false;
      update();
    }

    if (immediate) {
      isFiltering = true;
      update();
      runFilter();
      return;
    }

    isFiltering = true;
    update();
    _searchDebounce = Timer(_debounceDuration, runFilter);
  }

  addSqlData(String type, FoodItem item) async {
    dbHelper.insertCalorieHistory(
      CalorieHistoryModel(
        calorie: item.calories,
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        protein: item.protein,
        carbs: item.carbs,
        fats: item.fats,
        type: type,
        title: item.name,
      ),
    );
  }

  onAddButton(BuildContext context, FoodItem item) async {
    List<SqlCalorieModel> calorieData = await dbHelper.getCalorieData();
    if (!context.mounted) return;
    addSqlData(type, item);

    if (calorieData.isEmpty) {
      int id = await dbHelper.insertCalorie(
        SqlCalorieModel(
          date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
          totalGoal: ConstantUserMaster.calorieGoal,
          calorie: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fats: item.fats,
        ),
      );
      await dbHelper.insertDailyWater(
        DailyCalorieModel(
          date: DateTime.now().toString(),
          time: DateFormat('hh:mm a').format(DateTime.now()),
          calorie: item.calories,
          calorieId: id,
        ),
      );
      // Sync to Firestore for notifications
      MealSyncService().syncMealLog(
        mealType: type,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fats: item.fats,
        dailyGoal: ConstantUserMaster.calorieGoal,
      );
      Get.until((route) => route.settings.name == Routes.leadingView);
      _switchToHomeTab();
      RateUsService.showRateUsIfEligible(RateUsService.actionFoodLog);
      WidgetPromotionService().showPromotionIfNeeded();
    } else {
      if (calorieData.last.date ==
          DateFormat('dd-MM-yyyy').format(DateTime.now())) {
        if (calorieData.last.calorie + item.calories >
            ConstantUserMaster.calorieGoal) {
          showCalorieCompleteDialog(context, calorieData, item);
        } else {
          await dbHelper.updateCalorie(
            SqlCalorieModel(
              id: calorieData.last.id,
              date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
              totalGoal: ConstantUserMaster.calorieGoal,
              calorie: calorieData.last.calorie + item.calories,
              protein: calorieData.last.protein + item.protein,
              carbs: calorieData.last.carbs + item.carbs,
              fats: calorieData.last.fats + item.fats,
            ),
          );
          await dbHelper.insertDailyWater(
            DailyCalorieModel(
              date: DateTime.now().toString(),
              time: DateFormat('hh:mm a').format(DateTime.now()),
              calorie: calorieData.last.calorie + item.calories,
              calorieId: calorieData.last.id!,
            ),
          );
          // Sync to Firestore for notifications
          MealSyncService().syncMealLog(
            mealType: type,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fats: item.fats,
            dailyGoal: ConstantUserMaster.calorieGoal,
          );
          Get.until((route) => route.settings.name == Routes.leadingView);
          _switchToHomeTab();
          RateUsService.showRateUsIfEligible(RateUsService.actionFoodLog);
          WidgetPromotionService().showPromotionIfNeeded();
        }
      } else {
        int id = await dbHelper.insertCalorie(
          SqlCalorieModel(
            date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
            totalGoal: ConstantUserMaster.calorieGoal,
            calorie: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fats: item.fats,
          ),
        );
        await dbHelper.insertDailyWater(
          DailyCalorieModel(
            date: DateTime.now().toString(),
            time: DateFormat('hh:mm a').format(DateTime.now()),
            calorie: item.calories,
            calorieId: id,
          ),
        );
        // Sync to Firestore for notifications
        MealSyncService().syncMealLog(
          mealType: type,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fats: item.fats,
          dailyGoal: ConstantUserMaster.calorieGoal,
        );
        Get.until((route) => route.settings.name == Routes.leadingView);
        _switchToHomeTab();
        RateUsService.showRateUsIfEligible(RateUsService.actionFoodLog);
        WidgetPromotionService().showPromotionIfNeeded();
      }
    }
  }

  void _switchToHomeTab() async {
    try {
      if (Get.isRegistered<LeadingController>()) {
        final lc = Get.find<LeadingController>();
        lc.currentIndex = 0;
        lc.update();
      }
      if (Get.isRegistered<HomeController>()) {
        final hc = Get.find<HomeController>();
        await hc.getSqlCalorie();
        await hc.getRecentHistory();
        hc.update();
      }
    } catch (_) {}
  }

  showCalorieCompleteDialog(
    BuildContext context,
    List<SqlCalorieModel> calorieData,
    FoodItem item,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.theme.cardColor,
          title: Text(
            "Calorie Goal Reached".tr,
            style: context.textTheme.headlineMedium,
          ),
          content: Text(
            "You've completed your calorie goal for today. Would you like to add more?"
                .tr,
            style: context.textTheme.titleSmall,
          ),
          actions: [
            TextButton(
              child: Text(
                "Done".tr,
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontFamily: poppins,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
            TextButton(
              onPressed: () async {
                await dbHelper.updateCalorie(
                  SqlCalorieModel(
                    id: calorieData.last.id,
                    date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
                    totalGoal: ConstantUserMaster.calorieGoal,
                    calorie: calorieData.last.calorie + item.calories,
                    protein: calorieData.last.protein + item.protein,
                    carbs: calorieData.last.carbs + item.carbs,
                    fats: calorieData.last.fats + item.fats,
                  ),
                );
                await dbHelper.insertDailyWater(
                  DailyCalorieModel(
                    date: DateTime.now().toString(),
                    time: DateFormat('hh:mm a').format(DateTime.now()),
                    calorie: calorieData.last.calorie + item.calories,
                    calorieId: calorieData.last.id!,
                  ),
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                Get.until((route) => route.settings.name == Routes.leadingView);
                _switchToHomeTab();
                RateUsService.showRateUsIfEligible(RateUsService.actionFoodLog);
                WidgetPromotionService().showPromotionIfNeeded();
              },
              child: Text(
                "Add More Calories".tr,
                style: TextStyle(
                  color: context.theme.focusColor,
                  fontFamily: poppins,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPremiumRequiredDialog() {
    Get.dialog(
      PremiumRequiredDialog(
        title: 'premium_feature'.tr,
        message: 'local_food_premium_message'.tr,
        badge: Text(
          'local_food_premium_badge'.tr,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        onUpgrade: () {
          Get.back();
          Get.toNamed(Routes.premiumView);
        },
        onCancel: () => Get.back(),
      ),
      barrierDismissible: false,
    );
  }
}

class FoodItem {
  final String name;
  final String quantity;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;

  FoodItem({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.quantity,
    required this.fats,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0) as int,
      carbs: (json['carbs'] ?? 0) as int,
      protein: (json['protein'] ?? 0) as int,
      quantity: json['quantity'] ?? '',
      fats: (json['fats'] ?? 0) as int,
    );
  }
}
