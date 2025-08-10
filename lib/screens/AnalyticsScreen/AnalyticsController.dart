

import 'package:foodcalorietracker/Model/SqlCalorieModel.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AnalyticsController extends GetxController {
  List<SalesData> weeklyData = [];
  List<SalesData> monthData = [];
  List<SalesData> yearData = [];
  int yourWeeklyGoal = 0;
  int yourMonthGoal = 0;
  int yourYearGoal = 0;
  final dbHelper = DatabaseHelper();
  List<SqlCalorieModel> calorieList = [];

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
    calorieList = await dbHelper.getCalorieData();
    await getWeeklyData();
    await getMonthlyData();
    await getYearlyData();
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
      String dayName = DateFormat('EE').format(dataDate);
      print(dayName);
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
    print(monthlyWaterData);
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
      1: 0, // January
      2: 0, // February
      3: 0, // March
      4: 0, // April
      5: 0, // May
      6: 0, // June
      7: 0, // July
      8: 0, // August
      9: 0, // September
      10: 0, // October
      11: 0, // November
      12: 0, // December
    };
    for (var dayData in yearlyWaterData) {
      DateTime dataDate = DateFormat('dd-MM-yyyy').parse(dayData.date);
      int monthOfYear = dataDate.month;
      if (yearlyConsumption.containsKey(monthOfYear)) {
        yearlyConsumption[monthOfYear] =
            yearlyConsumption[monthOfYear]! + dayData.calorie;
      }
    }

    // Clear existing yearly data
    yourYearGoal = 0;

    // Add new yearly data
    yearlyConsumption.forEach((month, amount) {
      String monthName = DateFormat.MMMM().format(
        DateTime(today.year, month),
      ); // Convert month number to name (e.g., January)
      yearData.add(SalesData(monthName.substring(0,3), amount));
      yourYearGoal = yourYearGoal + amount;
    });

    update();
  }
}

class SalesData {
  SalesData(this.time, this.ml);

  final String time;
  final int ml;
}
