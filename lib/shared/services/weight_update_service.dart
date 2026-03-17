import 'package:get/get.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart'
    as cum_helpers;
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/screens/HomeScreen/home_controller.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/screens/leadingScreen/leading_controller.dart';
import 'package:macroaize/shared/services/notification_service.dart';

class WeightUpdateService {
  const WeightUpdateService._();

  static final DatabaseHelper _dbHelper = DatabaseHelper();

  static Future<void> updateWeight(int newWeight) async {
    if (newWeight <= 0) return;

    if (Get.isRegistered<AnalyticsController>()) {
      await Get.find<AnalyticsController>().updateCurrentWeight(newWeight);
      return;
    }

    await _updateWeightWithoutAnalyticsController(newWeight);
  }

  static Future<void> updateWeightAndOpenOverview(int newWeight) async {
    await updateWeight(newWeight);

    if (Get.isRegistered<LeadingController>()) {
      final leadingController = Get.find<LeadingController>();
      leadingController.changeTabIndex(3);
    }
  }

  static Future<void> _updateWeightWithoutAnalyticsController(
    int newWeight,
  ) async {
    ConstantUserMaster.weight = newWeight;
    await SharedPref.saveInt(SharePrefKey.weight, newWeight);
    await _dbHelper.insertWeightEntry(newWeight.toDouble(), DateTime.now());
    await _recalculateAndSaveGoals(newWeight, ConstantUserMaster.desiredGoal);

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().getAllData();
    }

    NotificationService.showSuccess('update_targets_body');
  }

  static Future<void> _recalculateAndSaveGoals(int weight, int goal) async {
    final bmr = cum_helpers.estimateBMR(
      ConstantUserMaster.height,
      weight,
      ConstantUserMaster.age,
      ConstantUserMaster.gender,
    );
    final activity = cum_helpers.getActivityFactor(ConstantUserMaster.workOutDay);
    final tdee = bmr * activity;

    final adjustedCalories = cum_helpers.adjustCaloriesForGoal(
      tdee,
      weight,
      goal,
      ConstantUserMaster.goalWeight,
    );

    final macros = cum_helpers.calculateMacrosFromTDEE(
      adjustedCalories.toDouble(),
      weight,
    );

    await SharedPref.saveInt(SharePrefKey.calorie, macros['calories']!);
    await SharedPref.saveInt(SharePrefKey.protein, macros['protein']!);
    await SharedPref.saveInt(SharePrefKey.carbs, macros['carbs']!);
    await SharedPref.saveInt(SharePrefKey.fat, macros['fat']!);

    ConstantUserMaster.calorieGoal = macros['calories']!;
    ConstantUserMaster.proteinGoal = macros['protein']!;
    ConstantUserMaster.carbGoal = macros['carbs']!;
    ConstantUserMaster.fatsGoal = macros['fat']!;
  }
}
