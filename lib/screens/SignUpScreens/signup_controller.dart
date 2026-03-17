import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:async';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/shared/services/rate_us_service.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/born_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/gender_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/theme_choice_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/goal_screen.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/height_width_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/plan_review_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/promo_code_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/auth_required_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/setup_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/stopping_goal_view.dart';
import 'package:macroaize/screens/SignUpScreens/SignUpViews/workout_view.dart';
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
  String? promoCode; // promo code
  Timer? _setupTransitionTimer;

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

  List<int> years = List.generate(50, (index) => 1975 + index); // years range
  List<int> days = List.generate(31, (index) => index + 1); // days range
  bool isMetric = true; // metric toggle
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 170;
  int selectedWeightLb = 132;
  int selectedWeightKg = 60;

  // calculated plan values
  RxInt calculatedCalories = 0.obs;
  RxInt calculatedProtein = 0.obs;
  RxInt calculatedCarbs = 0.obs;
  RxInt calculatedFat = 0.obs;

  List<Widget> screens = [
    const ThemeChoiceView(),
    GenderView(),
    WorkoutView(),
    HeightWidth(),
    GoalScreen(),
    BornView(),
    StoppingGoalView(),
    const AuthRequiredView(), // Login required before promo code
    PromoCodeView(),
    SetupView(),
    const PlanReviewView(),
  ];

  @override
  void onInit() {
    super.onInit();
    // default selection
    selectedStoppingGoal = 'Lack of consistency'.tr;
  }

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
    if (selectedView < 8) {
      // Regular step-by-step flow up to PromoCodeView.
      selectedView = selectedView + 1;
    } else if (selectedView == 8) {
      // PromoCodeView -> SetupView (loading) -> PlanReviewView
      selectedView = 9; // Show SetupView loading
      saveOnSql();
      _startSetupTransition();
    } else if (selectedView == 10) {
      // go to premium
      navigateToPremium();
    }
    update();
  }

  // Skip auth and promo code - go directly to setup
  void skipToSetup() {
    selectedView = 9; // Go to SetupView loading
    saveOnSql();
    _startSetupTransition();
    update();
  }

  void _startSetupTransition() {
    _setupTransitionTimer?.cancel();
    _setupTransitionTimer = Timer(const Duration(seconds: 3), () async {
      if (isClosed) return;
      await SharedPref.saveBool(SharePrefKey.onboardingCompleted, true);
      if (isClosed) return;
      selectedView = 10;
      update();
    });
  }

  // Skip auth but show promo code page
  void skipToPromoCode() {
    selectedView = 8; // Go to PromoCodeView
    update();
  }

  // navigate to premium
  Future<void> navigateToPremium() async {
    // save values
    SharedPref.saveInt(SharePrefKey.calorie, calculatedCalories.value);
    SharedPref.saveInt(SharePrefKey.protein, calculatedProtein.value);
    SharedPref.saveInt(SharePrefKey.carbs, calculatedCarbs.value);
    SharedPref.saveInt(SharePrefKey.fat, calculatedFat.value);

    // show rate us popup before premium screen (first-time onboarding only)
    await RateUsService.showRateUsForOnboarding();

    Get.toNamed(
      Routes.premiumView,
      arguments: {
        'delayClose': true,
        'fromOnboarding': true,
        'promoCode': promoCode,
      },
    );
  }

  saveOnSql() {
    if (!isMetric) {
      selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
      selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
    }
    DateTime selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    String formattedDate =
        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}";
    // save user data
    SharedPref.saveString(SharePrefKey.gender, selectedGender);
    SharedPref.saveString(SharePrefKey.workOutDay, selectedWorkOut);
    SharedPref.saveInt(SharePrefKey.height, selectedCm);
    SharedPref.saveInt(SharePrefKey.weight, selectedWeightKg);
    SharedPref.saveString(SharePrefKey.goalWeight, selectedWGoal);
    SharedPref.saveInt(SharePrefKey.desiredWeight, selectedDesiredWeight);
    SharedPref.saveString(SharePrefKey.bornDay, formattedDate);
    SharedPref.saveString(SharePrefKey.stoppingGoal, selectedStoppingGoal);
    SharedPref.saveBool(SharePrefKey.isLogin, true);

    DateTime today = DateTime.now();
    int birthYear = selectedYear;
    int age = today.year - birthYear;
    SharedPref.saveInt(SharePrefKey.age, age);

    double bmr = calculateBMR(
      selectedCm,
      selectedWeightKg,
      age,
      selectedGender,
    );
    double activityFactor = getActivityFactor(selectedWorkOut);
    double tdee = bmr * activityFactor;

    Map<String, int> macros = calculateMacros(tdee, selectedWeightKg);

    if (kDebugMode) {
      print("Daily Calories: ${macros["calories"]?.toStringAsFixed(2)} kcal");
    }
    SharedPref.saveInt(SharePrefKey.calorie, macros["calories"]);
    SharedPref.saveInt(SharePrefKey.protein, macros["protein"]);
    SharedPref.saveInt(SharePrefKey.carbs, macros["carbs"]);
    SharedPref.saveInt(SharePrefKey.fat, macros["fat"]);

    // store for plan review
    calculatedCalories.value = macros["calories"] ?? 0;
    calculatedProtein.value = macros["protein"] ?? 0;
    calculatedCarbs.value = macros["carbs"] ?? 0;
    calculatedFat.value = macros["fat"] ?? 0;
  }

  double calculateBMR(int heightCm, int weightKg, int age, String gender) {
    if (gender.toLowerCase() == "male") {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  Map<String, int> calculateMacros(double tdee, int weightKg) {
    double protein = weightKg * 2.0; // protein per kg
    double fat = (tdee * 0.25) / 9; // fat calories
    double carbs = (tdee - ((protein * 4) + (fat * 9))) / 4; // remaining carbs

    return {
      "calories": tdee.toInt(),
      "protein": protein.toInt(),
      "fat": fat.toInt(),
      "carbs": carbs.toInt(),
    };
  }

  double getActivityFactor(String workOutDays) {
    switch (workOutDays) {
      case "0-2":
        return 1.2; // sedentary
      case "3-5":
        return 1.55; // moderate
      case "6+":
        return 1.725; // active
      default:
        return 1.2; // default
    }
  }

  @override
  void onClose() {
    _setupTransitionTimer?.cancel();
    super.onClose();
  }

  // update days per month
  void updateDaysInMonth() {
    int daysInMonth = getDaysInMonth(selectedMonth, selectedYear);

    days = List.generate(daysInMonth, (index) => index + 1);
    update();
    if (selectedDay > daysInMonth) {
      selectedDay = daysInMonth; // adjust if invalid
    }
  }

  // days in month
  int getDaysInMonth(int month, int year) {
    if (month == 1) {
      // february leap year
      if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) {
        return 29;
      } else {
        return 28;
      }
    }
    // 30 day months
    if ([3, 5, 8, 10].contains(month)) {
      return 30;
    }
    return 31; // default 31
  }
}
