import 'package:flutter/foundation.dart';
import 'package:macroaize/Model/sql_calorie_model.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/screens/HomeScreen/home_controller.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart'
    as cum_helpers;

class AnalyticsController extends GetxController {
  List<SalesData> weeklyData = [];
  List<SalesData> monthData = [];
  List<SalesData> yearData = [];
  int yourWeeklyGoal = 0;
  int yourMonthGoal = 0;
  int yourYearGoal = 0;
  final dbHelper = DatabaseHelper();
  List<SqlCalorieModel> calorieList = [];

  // Weight history data
  List<WeightData> weeklyWeightData = [];
  List<WeightData> monthlyWeightData = [];
  List<WeightData> yearlyWeightData = [];

  // Workout history data
  List<WorkoutData> workoutWeeklyData = [];
  List<WorkoutData> workoutMonthData = [];
  List<WorkoutData> workoutYearData = [];
  int yourWeeklyWorkoutTotal = 0;
  int yourMonthlyWorkoutTotal = 0;
  int yourYearlyWorkoutTotal = 0;

  @override
  Future<void> onInit() async {
    super.onInit();
    calorieList = await dbHelper.getCalorieData();
    await getWeeklyData();
    await getMonthlyData();
    await getYearlyData();
    await loadWeightHistory();
    await loadWorkoutHistory();
  }

  Future<void> loadWeightHistory() async {
    final now = DateTime.now();
    final currentWeight = ConstantUserMaster.weight.toDouble();

    // Use the very first recorded weight as baseline for days before tracking
    final firstWeight = await dbHelper.getFirstWeightEntry();
    double baselineWeight = firstWeight ?? currentWeight;

    // Weekly: last 7 days
    final weekStart = now.subtract(const Duration(days: 6));
    final weekDataRaw = await dbHelper.getWeightHistory(
      startDate: weekStart,
      endDate: now,
    );

    final Map<String, double> weekMap = {};
    for (final e in weekDataRaw) {
      weekMap[e['date'] as String] = (e['weight'] as num).toDouble();
    }

    // Fill all 7 days, carrying forward from baseline or previous entry
    List<WeightData> newWeeklyWeightData = [];
    double lastWeight = baselineWeight;
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = DateFormat('E').format(date);

      if (weekMap.containsKey(dateStr)) {
        lastWeight = weekMap[dateStr]!;
      }
      newWeeklyWeightData.add(WeightData(dayLabel, lastWeight, date));
    }
    weeklyWeightData = newWeeklyWeightData;

    // Monthly: last 30 days
    final monthStart = now.subtract(const Duration(days: 29));
    final monthDataRaw = await dbHelper.getWeightHistory(
      startDate: monthStart,
      endDate: now,
    );

    final Map<String, double> monthMap = {};
    for (final e in monthDataRaw) {
      monthMap[e['date'] as String] = (e['weight'] as num).toDouble();
    }

    List<WeightData> newMonthlyWeightData = [];
    lastWeight = baselineWeight;
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = DateFormat('d').format(date);

      if (monthMap.containsKey(dateStr)) {
        lastWeight = monthMap[dateStr]!;
      }
      newMonthlyWeightData.add(WeightData(dayLabel, lastWeight, date));
    }
    monthlyWeightData = newMonthlyWeightData;

    // Yearly: last 12 months
    final yearStart = DateTime(now.year - 1, now.month, now.day);
    final yearDataRaw = await dbHelper.getWeightHistory(
      startDate: yearStart,
      endDate: now,
    );

    final Map<String, double> yearMap = {};
    for (final e in yearDataRaw) {
      final date = DateTime.parse(e['date'] as String);
      final monthKey = DateFormat('MMM').format(date);
      yearMap[monthKey] = (e['weight'] as num).toDouble();
    }

    List<WeightData> newYearlyWeightData = [];
    lastWeight = baselineWeight;
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat('MMM').format(date);

      if (yearMap.containsKey(monthLabel)) {
        lastWeight = yearMap[monthLabel]!;
      }
      newYearlyWeightData.add(WeightData(monthLabel, lastWeight, date));
    }
    yearlyWeightData = newYearlyWeightData;

    update();
  }

  Future<void> loadWorkoutHistory() async {
    final now = DateTime.now();

    // Weekly: last 7 days
    final weekStart = now.subtract(const Duration(days: 6));
    final weekDurationMap = await dbHelper.getWorkoutDurationByDate(
      startDate: weekStart,
      endDate: now,
    );

    workoutWeeklyData.clear();
    yourWeeklyWorkoutTotal = 0;
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = weekDays[date.weekday % 7];
      final minutes = weekDurationMap[dateStr] ?? 0;
      workoutWeeklyData.add(WorkoutData(dayLabel, minutes));
      yourWeeklyWorkoutTotal += minutes;
    }

    // Monthly: last 30 days
    final monthStart = now.subtract(const Duration(days: 29));
    final monthDurationMap = await dbHelper.getWorkoutDurationByDate(
      startDate: monthStart,
      endDate: now,
    );

    workoutMonthData.clear();
    yourMonthlyWorkoutTotal = 0;
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = date.day.toString();
      final minutes = monthDurationMap[dateStr] ?? 0;
      workoutMonthData.add(WorkoutData(dayLabel, minutes));
      yourMonthlyWorkoutTotal += minutes;
    }

    // Yearly: 12 months
    final yearStart = DateTime(now.year - 1, now.month, now.day);
    final yearDurationMap = await dbHelper.getWorkoutDurationByDate(
      startDate: yearStart,
      endDate: now,
    );

    // Group by month for yearly view
    Map<String, int> monthlyTotals = {};
    yearDurationMap.forEach((dateStr, minutes) {
      final date = DateTime.parse(dateStr);
      final monthKey = DateFormat('yyyy-MM').format(date);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + minutes;
    });

    workoutYearData.clear();
    yourYearlyWorkoutTotal = 0;
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final monthLabel = DateFormat('MMM').format(date);
      final minutes = monthlyTotals[monthKey] ?? 0;
      workoutYearData.add(WorkoutData(monthLabel, minutes));
      yourYearlyWorkoutTotal += minutes;
    }

    update();
  }

  Future<void> getWeeklyData() async {
    DateTime today = DateTime.now();
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    DateTime endOfWeek = today;

    List<SqlCalorieModel> filteredData =
        calorieList.where((entry) {
          DateTime entryDate = DateFormat('dd-MM-yyyy').parse(entry.date);
          DateTime formattedStartDate = DateFormat(
            'dd-MM-yyyy',
          ).parse(DateFormat('dd-MM-yyyy').format(startOfWeek));
          DateTime formattedEndDate = DateFormat(
            'dd-MM-yyyy',
          ).parse(DateFormat('dd-MM-yyyy').format(endOfWeek));

          return entryDate.isAfter(
                formattedStartDate.subtract(Duration(days: 1)),
              ) &&
              entryDate.isBefore(formattedEndDate.add(Duration(days: 1)));
        }).toList();
    Map<String, int> weeklyConsumption = {
      'Sun': 0,
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
    };

    for (var dayData in filteredData) {
      DateTime dataDate = DateFormat('dd-MM-yyyy').parse(dayData.date);
      // 1=Mon,7=Sun
      const dowMap = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun',
      };
      final int wd = dataDate.weekday;
      final String dayName = dowMap[wd]!;
      if (weeklyConsumption.containsKey(dayName)) {
        weeklyConsumption[dayName] = dayData.calorie;
      }
    }
    weeklyData.clear();
    yourWeeklyGoal = 0;
    weeklyConsumption.forEach((day, amount) {
      weeklyData.add(SalesData(day, amount));
      yourWeeklyGoal = yourWeeklyGoal + amount;
    });
    update();
  }

  Future<void> getMonthlyData() async {
    DateTime today = DateTime.now();
    DateTime firstDayOfMonth = DateTime(today.year, today.month, 1);
    DateTime lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    List<SqlCalorieModel> monthlyWaterData = await dbHelper
        .getCalorieDataForMonth(firstDayOfMonth, lastDayOfMonth);
    if (kDebugMode) {
      print(monthlyWaterData);
    }
    Map<int, int> monthlyConsumption = {};
    int daysInMonth = lastDayOfMonth.day;

    for (int i = 1; i <= daysInMonth; i++) {
      monthlyConsumption[i] = 0;
    }
    update();
    for (var dayData in monthlyWaterData) {
      DateTime dataDate = DateFormat('dd-MM-yyyy').parse(dayData.date);
      int dayOfMonth = dataDate.day;
      if (monthlyConsumption.containsKey(dayOfMonth)) {
        monthlyConsumption[dayOfMonth] = dayData.calorie;
      }
    }
    monthData.clear();
    monthlyConsumption.forEach((day, amount) {
      monthData.add(SalesData(day.toString(), amount));
      yourMonthGoal = yourMonthGoal + amount;
    });
    update();
  }

  Future<void> getYearlyData() async {
    DateTime today = DateTime.now();
    DateTime firstDayOfYear = DateTime(today.year, 1, 1);
    DateTime lastDayOfYear = DateTime(today.year, 12, 31);
    List<SqlCalorieModel> yearlyWaterData =
        calorieList.where((entry) {
          DateTime entryDate = DateFormat('dd-MM-yyyy').parse(entry.date);
          DateTime formattedStartDate = DateFormat(
            'dd-MM-yyyy',
          ).parse(DateFormat('dd-MM-yyyy').format(firstDayOfYear));
          DateTime formattedEndDate = DateFormat(
            'dd-MM-yyyy',
          ).parse(DateFormat('dd-MM-yyyy').format(lastDayOfYear));
          return entryDate.isAfter(
                formattedStartDate.subtract(Duration(days: 1)),
              ) &&
              entryDate.isBefore(formattedEndDate.add(Duration(days: 1)));
        }).toList();
    Map<int, int> yearlyConsumption = {
      1: 0, // january
      2: 0, // february
      3: 0, // march
      4: 0, // april
      5: 0, // may
      6: 0, // june
      7: 0, // july
      8: 0, // august
      9: 0, // september
      10: 0, // october
      11: 0, // november
      12: 0, // december
    };
    for (var dayData in yearlyWaterData) {
      DateTime dataDate = DateFormat('dd-MM-yyyy').parse(dayData.date);
      int monthOfYear = dataDate.month;
      if (yearlyConsumption.containsKey(monthOfYear)) {
        yearlyConsumption[monthOfYear] =
            yearlyConsumption[monthOfYear]! + dayData.calorie;
      }
    }

    // reset and add yearly data
    yearlyConsumption.forEach((month, amount) {
      String monthName = DateFormat.MMMM().format(DateTime(today.year, month));
      yearData.add(SalesData(monthName.substring(0, 3), amount));
      yourYearGoal = yourYearGoal + amount;
    });

    update();
  }

  Future<void> updateCurrentWeight(int newWeight) async {
    ConstantUserMaster.weight = newWeight;
    update();
    await SharedPref.saveInt(SharePrefKey.weight, newWeight);

    // Record weight history
    await dbHelper.insertWeightEntry(newWeight.toDouble(), DateTime.now());
    await loadWeightHistory();

    await _recalculateAndSaveGoals(newWeight, ConstantUserMaster.desiredGoal);

    NotificationService.showSuccess('update_targets_body');
    _refreshHome();
  }

  Future<void> updateDesiredGoal(int newGoal) async {
    ConstantUserMaster.desiredGoal = newGoal;
    update();
    await SharedPref.saveInt(SharePrefKey.desiredWeight, newGoal);

    await _recalculateAndSaveGoals(ConstantUserMaster.weight, newGoal);

    NotificationService.showSuccess('update_targets_body');
    _refreshHome();
  }

  Future<void> _recalculateAndSaveGoals(int weight, int goal) async {
    final bmr = cum_helpers.estimateBMR(
      ConstantUserMaster.height,
      weight,
      ConstantUserMaster.age,
      ConstantUserMaster.gender,
    );
    final activity = cum_helpers.getActivityFactor(
      ConstantUserMaster.workOutDay,
    );
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

  void _refreshHome() {
    try {
      Get.find<HomeController>().getAllData();
    } catch (_) {}
  }
}

class SalesData {
  SalesData(this.time, this.ml);

  final String time;
  final int ml;
}

class WeightData {
  WeightData(this.label, this.weight, this.date);

  final String label;
  final double weight;
  final DateTime date;
}

class WorkoutData {
  WorkoutData(this.label, this.minutes);

  final String label;
  final int minutes; // workout duration in minutes
}
