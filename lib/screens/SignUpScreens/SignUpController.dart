import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/BornView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/GenderView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/GoalScreen.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/HeightWidthView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/SetupView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/StoppingGoalView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/WorkoutView.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  int selectedView = 0;
  String selectedGender = "";
  String selectedWorkOut = "";
  String selectedStoppingGoal = "";
  String selectedWGoal = "";
  int selectedDesiredWeight = 51;
  int selectedMonth = 0; // January
  int selectedDay = 1; // 1st
  int selectedYear = 2012; // Default Year
  int selectedHour = 9;
  int selectedMinute = 40;
  String selectedPeriod = "AM";

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
    50,
    (index) => 1975 + index,
  ); // Years 1975-2025
  List<int> days = List.generate(31, (index) => index + 1); // Days 1-31
  bool isMetric = true; // Toggle state
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 121;
  int selectedWeightLb = 119;
  int selectedWeightKg = 51;

  List<Widget> screens = [
    GenderView(),
    WorkoutView(),
    HeightWidth(),
    GoalScreen(),
    BornView(),
    StoppingGoalView(),
    SetupView(),
  ];

  onChangeGender(String value) {
    selectedGender = value;
    update();
  }

  onChangeGoal(String value) {
    selectedWGoal = value;
    update();
  }

  onChangeWorkout(String value) {
    selectedWorkOut = value;
    update();
  }

  onChangeStoppingGoal(String value) {
    selectedStoppingGoal = value;
    update();
  }

  onChangeMetric(bool value) {
    isMetric = value;
    update();
  }

  onChangeDesiredWeight(int value) {
    selectedDesiredWeight = value;
    update();
  }

  onChangeView() {
    if (selectedView == 0) {
      selectedView = 1;
    } else if (selectedView == 1) {
      selectedView = 2;
    } else if (selectedView == 2) {
      selectedView = 3;
    } else if (selectedView == 3) {
      selectedView = 4;
    } else if (selectedView == 4) {
      selectedView = 5;
    } else if (selectedView == 5) {
      selectedView = 6;
      saveOnSql();
      Future.delayed(Duration(seconds: 3)).then((value) {
        Get.toNamed(Routes.leadingView);
      },);
    }
    update();
  }

  saveOnSql() {
    if (!isMetric) {
      selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
      selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
    }
    DateTime selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    String formattedDate = "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    print(selectedCm);
    print(selectedWeightKg);
    print(selectedWGoal);
    SharedPref.saveString(SharePrefKey.gender, selectedGender);
    SharedPref.saveString(SharePrefKey.workOutDay, selectedWorkOut);
    SharedPref.saveInt(SharePrefKey.height, selectedCm);
    SharedPref.saveInt(SharePrefKey.weight, selectedWeightKg);
    SharedPref.saveString(SharePrefKey.goalWeight, selectedWGoal);
    SharedPref.saveInt(SharePrefKey.desiredWeight,selectedDesiredWeight);
    SharedPref.saveString(SharePrefKey.bornDay,formattedDate);
    SharedPref.saveString(SharePrefKey.stoppingGoal, selectedStoppingGoal);
    SharedPref.saveBool(SharePrefKey.isLogin,true);

    DateTime today = DateTime.now();
    int birthYear = selectedYear;
    int age = today.year - birthYear;
    SharedPref.saveInt(SharePrefKey.age,age);

    double bmr = calculateBMR(selectedCm, selectedWeightKg, age, selectedGender);
    double activityFactor = getActivityFactor(selectedWorkOut);
    double tdee = bmr * activityFactor;

    Map<String, int> macros = calculateMacros(tdee, selectedWeightKg);

    if (kDebugMode) {
      print("Daily Calories: ${macros["calories"]?.toStringAsFixed(2)} kcal");
      print("Protein: ${macros["protein"]?.toStringAsFixed(2)} g");
      print("Fat: ${macros["fat"]?.toStringAsFixed(2)} g");
      print("Carbs: ${macros["carbs"]?.toStringAsFixed(2)} g");
    }
    SharedPref.saveInt(SharePrefKey.calorie, macros["calories"]);
    SharedPref.saveInt(SharePrefKey.protein, macros["protein"]);
    SharedPref.saveInt(SharePrefKey.carbs, macros["carbs"]);
    SharedPref.saveInt(SharePrefKey.fat, macros["fat"]);
  }

  double calculateBMR(int heightCm, int weightKg, int age, String gender) {
    if (gender.toLowerCase() == "male") {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  Map<String, int> calculateMacros(double tdee, int weightKg) {
    double protein = weightKg * 2.0; // 2g protein per kg
    double fat = (tdee * 0.25) / 9; // 25% of calories from fat (1g fat = 9 cal)
    double carbs = (tdee - ((protein * 4) + (fat * 9))) / 4; // Remaining calories for carbs (1g = 4 cal)

    return {
      "calories": tdee.toInt(),
      "protein": protein.toInt(),
      "fat": fat.toInt(),
      "carbs": carbs.toInt()
    };
  }
  double getActivityFactor(String workOutDays) {
    switch (workOutDays) {
      case "0-2":
        return 1.2; // Sedentary
      case "3-5":
        return 1.55; // Moderate activity
      case "6+":
        return 1.725; // Active
      default:
        return 1.2; // Default to sedentary
    }
  }
  // Method to update days based on selected month & year
  void updateDaysInMonth() {
    int daysInMonth = getDaysInMonth(selectedMonth, selectedYear);

    days = List.generate(daysInMonth, (index) => index + 1);
    update();
    if (selectedDay > daysInMonth) {
      selectedDay =
          daysInMonth; // Adjust if previously selected day is now invalid
    }
  }

  // Get number of days in a given month & year
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
