import 'package:macroaize/SharePrefHelper/ConstantUserMaster.dart';
import 'package:macroaize/SharePrefHelper/SharePref.dart';
import 'package:macroaize/SharePrefHelper/SharePrefKey.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/screens/HomeScreen/HomeController.dart';
import 'package:intl/intl.dart';

/// managing personal details editing (weight, height, DOB, gender, goal).
class PersonalDetailsController extends GetxController {
  int selectedDesiredWeight = 51;
  int selectedView = 0;
  String selectedGender = "";
  bool isMetric = true;
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 165;
  int selectedWeightLb = 119;
  int selectedWeightKg = 54;
  int selectedMonth = 0;
  int selectedDay = 1;
  int selectedYear = 2012;
  List<int> days = List.generate(31, (index) => index + 1);

  @override
  void onInit() {
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

  List<int> years = List.generate(50, (index) => 1975 + index);

  bool hasChanges = false;

  void setHasChanges(bool v) {
    hasChanges = v;
    update();
  }

  void onChangeDesiredWeight(int value) {
    selectedDesiredWeight = value;
    setHasChanges(true);
  }

  void onChangeSelectedView(int value) {
    selectedView = value;
    update();
  }

  void onChangeMetric(bool value) {
    isMetric = value;
    selectedWeightKg = ConstantUserMaster.weight;
    selectedWeightLb = (selectedWeightKg * 2.20462).round();
    setHasChanges(true);
  }

  void updateWeight() {
    if (isMetric) {
      ConstantUserMaster.weight = selectedWeightKg;
      SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
      update();
    } else {
      selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
      ConstantUserMaster.weight = selectedWeightKg;
      SharedPref.saveInt(SharePrefKey.weight, ConstantUserMaster.weight);
      update();
    }
  }

  void updateHeight() {
    if (isMetric) {
      ConstantUserMaster.height = selectedCm;
      SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
      update();
    } else {
      selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
      ConstantUserMaster.height = selectedCm;
      SharedPref.saveInt(SharePrefKey.height, ConstantUserMaster.height);
      update();
    }
  }

  void updateBornDay() {
    DateTime selectedDate = DateTime(
      selectedYear,
      selectedMonth + 1,
      selectedDay,
    );
    String formattedDate =
        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    ConstantUserMaster.bornDay = formattedDate;
    SharedPref.saveString(SharePrefKey.bornDay, formattedDate);
    DateTime today = DateTime.now();
    int birthYear = selectedYear;
    int age = today.year - birthYear;
    SharedPref.saveInt(SharePrefKey.age, age);
    ConstantUserMaster.age = age;
    update();
  }

  void updateGender() {
    ConstantUserMaster.gender = selectedGender;
    SharedPref.saveString(SharePrefKey.gender, ConstantUserMaster.gender);
    update();
  }

  /// Save the currently edited view and reset change state
  void saveCurrentView() {
    switch (selectedView) {
      case 1:
        ConstantUserMaster.desiredGoal = selectedDesiredWeight;
        SharedPref.saveInt(
          SharePrefKey.desiredWeight,
          ConstantUserMaster.desiredGoal,
        );
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
    }
    setHasChanges(false);

    if (selectedView == 2 || selectedView == 1) {
      final bmr = _estimateBMR(
        ConstantUserMaster.height,
        ConstantUserMaster.weight,
        ConstantUserMaster.age,
        ConstantUserMaster.gender,
      );
      final activity = _getActivityFactor(ConstantUserMaster.workOutDay);
      final tdee = bmr * activity;
      final adjustedCalories = adjustCaloriesForGoal(
        tdee,
        ConstantUserMaster.weight,
        ConstantUserMaster.desiredGoal,
        ConstantUserMaster.goalWeight,
      );
      final macros = calculateMacrosFromTDEE(
        adjustedCalories.toDouble(),
        ConstantUserMaster.weight,
      );
      SharedPref.saveInt(SharePrefKey.calorie, macros['calories']!);
      SharedPref.saveInt(SharePrefKey.protein, macros['protein']!);
      SharedPref.saveInt(SharePrefKey.carbs, macros['carbs']!);
      SharedPref.saveInt(SharePrefKey.fat, macros['fat']!);
      ConstantUserMaster.calorieGoal = macros['calories']!;
      ConstantUserMaster.proteinGoal = macros['protein']!;
      ConstantUserMaster.carbGoal = macros['carbs']!;
      ConstantUserMaster.fatsGoal = macros['fat']!;
      try {
        Get.find<HomeController>().getAllData();
      } catch (_) {}
    }

    NotificationService.showSuccess('Saved successfully');
    onChangeSelectedView(0);
  }

  double _estimateBMR(int heightCm, int weightKg, int age, String gender) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
  }

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

  void updateDaysInMonth() {
    int daysInMonth = getDaysInMonth(selectedMonth, selectedYear);
    days = List.generate(daysInMonth, (index) => index + 1);
    update();
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth;
    }
  }

  void onChangeGender(String value) {
    selectedGender = value;
    setHasChanges(true);
    update();
  }

  int getDaysInMonth(int month, int year) {
    if (month == 1) {
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      } else {
        return 28;
      }
    }
    if ([3, 5, 8, 10].contains(month)) {
      return 30;
    }
    return 31;
  }
}
