import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PersonalDetailsController extends GetxController{

  int selectedDesiredWeight = 51;
  int selectedView = 0;
  String selectedGender = "";
  bool isMetric = true; // Toggle state
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 165;
  int selectedWeightLb = 119;
  int selectedWeightKg = 54;
  int selectedMonth = 0; // January
  int selectedDay = 1; // 1st
  int selectedYear = 2012; // Default Year
  List<int> days = List.generate(31, (index) => index + 1); // Days 1-31

@override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    selectedDesiredWeight = ConstantUserMaster.desiredGoal;
    selectedWeightKg = ConstantUserMaster.weight;
    selectedWeightLb = (selectedWeightKg * 2.20462).round();
    selectedCm = ConstantUserMaster.height;
    DateTime date = DateFormat("dd-MM-yyyy").parse(ConstantUserMaster.bornDay);
    selectedDay = date.day;
    selectedMonth = date.month;
    selectedYear = date.year;
    selectedGender = ConstantUserMaster.gender;
    update();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<int> years = List.generate(
    50,(index) => 1975 + index,
  ); //

  // tracks whether current edit view has unsaved changes
  bool hasChanges = false;

  void setHasChanges(bool v) {
    hasChanges = v;
    update();
  }

  onChangeDesiredWeight(int value) {
    selectedDesiredWeight = value;
  setHasChanges(true);
  }
  onChangeSelectedView(int value)
  {
    selectedView = value;
    update();
  }
  onChangeMetric(bool value) {
    isMetric = value;
    selectedWeightKg = ConstantUserMaster.weight;
    selectedWeightLb = (selectedWeightKg * 2.20462).round();
  setHasChanges(true);
  }

  updateWeight()
  {
    if(isMetric)
      {
        ConstantUserMaster.weight = selectedWeightKg;
        SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
    update();
      }else{
      // selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
      selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
      ConstantUserMaster.weight = selectedWeightKg;
      SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
  update();
    }
  }
  updateHeight()
  {
    if(isMetric)
  {
    ConstantUserMaster.height = selectedCm;
    SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
    update();
  }else{
    selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
    ConstantUserMaster.height = selectedCm;
    SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
    update();
  }


  }
  updateBornDay()
  {
    DateTime selectedDate = DateTime(selectedYear, selectedMonth+1, selectedDay);
    String formattedDate = "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    ConstantUserMaster.bornDay = formattedDate;
    SharedPref.saveString(SharePrefKey.bornDay,formattedDate);
    DateTime today = DateTime.now();
    int birthYear = selectedYear;
    int age = today.year - birthYear;
    SharedPref.saveInt(SharePrefKey.age,age);
    ConstantUserMaster.age = age;
    update();
  }
  updateGender()
  {
    ConstantUserMaster.gender = selectedGender;
    SharedPref.saveString(SharePrefKey.gender, ConstantUserMaster.gender);
    update();
  }

  /// Save currently edited view and reset change state
  void saveCurrentView() {
    switch (selectedView) {
      case 1: // Goal
        ConstantUserMaster.desiredGoal = selectedDesiredWeight;
        SharedPref.saveInt(SharePrefKey.desiredWeight, ConstantUserMaster.desiredGoal);
        break;
      case 2:
        updateWeight();
        break;
      case 3:
        updateHeight();
        break;
      case 4:
        updateBornDay();
        break;
  // case 5 (Gender) removed — gender editing moved/disabled in Personal Details
    }
    setHasChanges(false);
    // Recalculate daily calorie/macros when weight or goal changed to match Overview behavior
    if (selectedView == 2 || selectedView == 1) {
      // estimate BMR and activity using same helpers as AnalyticsView
      final bmr = _estimateBMR(ConstantUserMaster.height, ConstantUserMaster.weight, ConstantUserMaster.age, ConstantUserMaster.gender);
      final activity = _getActivityFactor(ConstantUserMaster.workOutDay);
      final tdee = bmr * activity;
      final adjustedCalories = _adjustCaloriesForGoal(tdee, ConstantUserMaster.weight, ConstantUserMaster.desiredGoal);
      final macros = calculateMacrosFromTDEE(adjustedCalories.toDouble(), ConstantUserMaster.weight);
      // persist
      SharedPref.saveInt(SharePrefKey.calorie, macros['calories']!);
      SharedPref.saveInt(SharePrefKey.protein, macros['protein']!);
      SharedPref.saveInt(SharePrefKey.carbs, macros['carbs']!);
      SharedPref.saveInt(SharePrefKey.fat, macros['fat']!);
      ConstantUserMaster.calorieGoal = macros['calories']!;
      ConstantUserMaster.proteinGoal = macros['protein']!;
      ConstantUserMaster.carbGoal = macros['carbs']!;
      ConstantUserMaster.fatsGoal = macros['fat']!;
      // Refresh Home screen data if HomeController is available so UI updates immediately
      try {
        Get.find<HomeController>().getAllData();
      } catch (_) {
        // HomeController not registered; nothing to do. Home will pick up values on next load.
      }
    }

    // show a success notification then return to main view
    try {
      Get.snackbar(
        'Success'.tr,
        'Saved successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (_) {
      // fall back to simple snackbar without styling if anything fails
      Get.snackbar('Success'.tr, 'Saved successfully'.tr, snackPosition: SnackPosition.BOTTOM);
    }

    onChangeSelectedView(0);
  }

  // Helper: estimate BMR (same formula used in AnalyticsView)
  double _estimateBMR(int heightCm, int weightKg, int age, String gender) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }

  // Helper: activity factor based on stored workout frequency
  double _getActivityFactor(String workOutDays) {
    switch (workOutDays) {
      case '0-2':
        return 1.2;
      case '3-5':
        return 1.55;
      case '6+':
        return 1.725;
      default:
        return 1.2;
    }
  }

  // Helper: adjust calories based on goal (deficit or surplus)
  double _adjustCaloriesForGoal(double tdee, int currentWeight, int desiredGoal) {
    if (desiredGoal < currentWeight) {
      final diff = (currentWeight - desiredGoal).abs();
      final pct = (diff >= 10) ? 0.20 : 0.15;
      return (tdee * (1 - pct)).clamp(1200, double.infinity);
    }
    if (desiredGoal > currentWeight) {
      final diff = (desiredGoal - currentWeight).abs();
      final pct = (diff >= 10) ? 0.20 : 0.10;
      return (tdee * (1 + pct));
    }
    return tdee;
  }
  void updateDaysInMonth() {
    int daysInMonth = getDaysInMonth(selectedMonth, selectedYear);

    days = List.generate(daysInMonth, (index) => index + 1);
    update();
    if (selectedDay > daysInMonth) {
      selectedDay =
          daysInMonth; // Adjust if previously selected day is now invalid
    }
  }
  onChangeGender(String value) {
  selectedGender = value;
  setHasChanges(true);
  update();
  }
  int getDaysInMonth(int month, int year) {
    if (month == 1) {
      // February (check leap year)
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      } else {
        return 28;
      }
    }
    // Months with 30 days: April, June, September, November
    if ([3, 5, 8, 10].contains(month)) {
      return 30;
    }
    return 31; // Default months have 31 days
  }
}