import 'package:flutter/material.dart';
import 'dart:async';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/data/local_food/local_food_db.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../Model/calorie_history_model.dart';
import '../../Model/sql_calorie_model.dart';
import '../../Model/sql_daily_calorie_model.dart';
import '../../SharePrefHelper/constant_user_master.dart';
import '../../constant/font_family.dart';
import '../../routes/app_routes.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/premium_required_dialog.dart';
import '../../shared/widgets/delete_dialog.dart';
import '../../shared/services/rate_us_service.dart';
import '../../shared/services/widget_promotion_service.dart';
import '../../shared/services/meal_sync_service.dart';
import '../../shared/utils/navigation_helpers.dart';
import '../HomeScreen/home_controller.dart';
import '../leadingScreen/leading_controller.dart';

class LocalFoodController extends GetxController {
  Map<String, dynamic> argument = Get.arguments;
  TextEditingController textController = TextEditingController();
  List<FoodItem> filteredItems = [];
  List<FoodItem> _allItems = [];
  Timer? _searchDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  bool isFiltering = false;
  final dbHelper = DatabaseHelper();
  final localFoodDb = LocalFoodDb.instance;
  final _appUserService = AppUserService();

  String type = "";
  bool isEditing = false;
  // selected items
  final Set<int> selectedIndices = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    type = argument['value'] ?? 'Dinner';
    await _refreshFoods();
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
    if (index < 0 || index >= filteredItems.length) return;
    if (!filteredItems[index].isCustom) {
      NotificationService.showInfo('Only custom foods can be edited');
      return;
    }
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

    await localFoodDb.insertUserFood(
      mealType: type,
      entry: LocalFoodUserEntry(
        id: 0,
        mealType: type,
        name: item.name,
        quantity: item.quantity,
        calories: item.calories,
        carbs: item.carbs,
        protein: item.protein,
        fats: item.fats,
      ),
    );
    await _refreshFoods(query: textController.text);
    NotificationService.showSuccess('food_added_success');
  }

  void editFoodAt(int index, FoodItem item) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (index < 0 || index >= filteredItems.length) return;

    final existing = filteredItems[index];
    if (!existing.isCustom || existing.id == null) {
      NotificationService.showInfo('Only custom foods can be edited');
      return;
    }

    await localFoodDb.updateUserFood(
      id: existing.id!,
      entry: LocalFoodUserEntry(
        id: existing.id!,
        mealType: type,
        name: item.name,
        quantity: item.quantity,
        calories: item.calories,
        carbs: item.carbs,
        protein: item.protein,
        fats: item.fats,
      ),
    );
    await _refreshFoods(query: textController.text);
    NotificationService.showSuccess('food_updated_success');
  }

  void deleteSelected(BuildContext context) async {
    final isPremium = await _appUserService.isPremiumNow();
    if (!isPremium) {
      _showPremiumRequiredDialog();
      return;
    }

    if (selectedIndices.isEmpty) return;
    if (!context.mounted) return;

    final deletableIds =
        selectedIndices
            .where((i) => i >= 0 && i < filteredItems.length)
            .map((i) => filteredItems[i])
            .where((item) => item.isCustom && item.id != null)
            .map((item) => item.id!)
            .toList();

    if (deletableIds.isEmpty) {
      NotificationService.showInfo('Select custom foods to delete');
      return;
    }

    showDeleteDialog(
      context: context,
      onDelete: () async {
        await localFoodDb.deleteUserFoodsByIds(deletableIds);
        await _refreshFoods(query: textController.text);
        selectedIndices.clear();
        isEditing = false;
        update();
        NotificationService.showSuccess(
          'food_deleted_success',
          params: {'count': deletableIds.length.toString()},
        );
      },
    );
  }

  Future<void> _refreshFoods({String query = ''}) async {
    final locale = Get.locale?.languageCode ?? 'en';
    final trimmed = query.trim();

    try {
      final customItems =
          trimmed.isEmpty
              ? await localFoodDb.getUserFoodsByMealType(type)
              : await localFoodDb.searchUserFoodsByMealType(type, trimmed);
      final catalogItems = await localFoodDb.searchCatalog(
        query: trimmed,
        locale: locale,
        limit: 100,
      );

      _allItems = [
        ...customItems.map(
          (item) => FoodItem(
            id: item.id,
            name: item.name,
            calories: item.calories,
            carbs: item.carbs,
            protein: item.protein,
            quantity: item.quantity,
            fats: item.fats,
            source: FoodSource.custom,
          ),
        ),
        ...catalogItems.map(
          (item) => FoodItem(
            id: item.id,
            name: item.name,
            calories: item.calories,
            carbs: item.carbs,
            protein: item.protein,
            quantity: item.quantity,
            fats: item.fats,
            source: FoodSource.catalog,
          ),
        ),
      ];

      final seen = <String>{};
      _allItems =
          _allItems.where((item) {
            final key =
                '${item.source.name}:${item.id ?? item.name.toLowerCase()}';
            return seen.add(key);
          }).toList();

      filteredItems = _allItems;
      isFiltering = false;
      selectedIndices.clear();
      update();
    } catch (_) {
      isFiltering = false;
      update();
    }
  }

  /// filter with debounce
  void searchFilter(String query, {bool immediate = false}) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    Future<void> runFilter() async {
      await _refreshFoods(query: query);
    }

    if (immediate) {
      isFiltering = true;
      update();
      runFilter();
      return;
    }

    isFiltering = true;
    update();
    _searchDebounce = Timer(_debounceDuration, () {
      runFilter();
    });
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
          safeBackAndNavigate(Routes.premiumView);
        },
        onCancel: () => safeBack(),
      ),
      barrierDismissible: false,
    );
  }
}

class FoodItem {
  final int? id;
  final FoodSource source;
  final String name;
  final String quantity;
  final int calories;
  final int carbs;
  final int protein;
  final int fats;

  FoodItem({
    this.id,
    this.source = FoodSource.catalog,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.quantity,
    required this.fats,
  });

  bool get isCustom => source == FoodSource.custom;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
      'source': source.name,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0) as int,
      carbs: (json['carbs'] ?? 0) as int,
      protein: (json['protein'] ?? 0) as int,
      quantity: json['quantity'] ?? '',
      fats: (json['fats'] ?? 0) as int,
      source:
          (json['source'] as String?) == FoodSource.custom.name
              ? FoodSource.custom
              : FoodSource.catalog,
    );
  }
}

enum FoodSource { catalog, custom }
