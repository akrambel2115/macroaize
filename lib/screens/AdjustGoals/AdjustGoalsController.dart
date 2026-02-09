import 'package:macroaize/SharePrefHelper/ConstantUserMaster.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

class AdjustGoalsController extends GetxController {
  String selectedWorkOut = "";
  bool isAutoGenerate = false;
  int selectedUpdateGoalView = 1;
  bool isMetric = true;
  int selectedFeet = 5;
  int selectedInches = 5;
  int selectedCm = 121;
  int selectedWeightLb = 119;
  int selectedWeightKg = 51;
  String selectedWGoal = "";
  int selectedDesiredWeight = 51;
  bool hasChanges = false;

  void setHasChanges(bool v) {
    hasChanges = v;
    update();
  }

  void showSaveNotification() {
    NotificationService.showSuccess('Goal updated successfully');
  }

  void updateCalorieGoal(int value) async {
    ConstantUserMaster.calorieGoal = value;
    await SharedPref.saveInt(
      SharePrefKey.calorie,
      ConstantUserMaster.calorieGoal,
    );
    showSaveNotification();
    update();
  }

  void updateProteinGoal(int value) async {
    ConstantUserMaster.proteinGoal = value;
    await SharedPref.saveInt(
      SharePrefKey.protein,
      ConstantUserMaster.proteinGoal,
    );
    showSaveNotification();
    update();
  }

  void updateCarbGoal(int value) async {
    ConstantUserMaster.carbGoal = value;
    await SharedPref.saveInt(SharePrefKey.carbs, ConstantUserMaster.carbGoal);
    showSaveNotification();
    update();
  }

  void updateFatGoal(int value) async {
    ConstantUserMaster.fatsGoal = value;
    await SharedPref.saveInt(SharePrefKey.fat, ConstantUserMaster.fatsGoal);
    showSaveNotification();
    update();
  }

  onChangeWorkout(String value) {
    selectedWorkOut = value;
    setHasChanges(true);
  }

  onChangeAutoGenerate(bool value) {
    isAutoGenerate = value;
    update();
  }

  onChangeView(int value) {
    selectedUpdateGoalView = value;
    update();
  }

  onChangeMetric(bool value) {
    isMetric = value;
    setHasChanges(true);
  }

  onChangeGoal(String value) {
    selectedWGoal = value;
    setHasChanges(true);
  }

  onChangeDesiredWeight(int value) {
    selectedDesiredWeight = value;
    setHasChanges(true);
  }

  saveOnSql() {
    if (isAutoGenerate) {
      // auto-generate: recalculate macros from user params
      if (!isMetric) {
        selectedCm = ((selectedFeet * 30.48) + (selectedInches * 2.54)).toInt();
        selectedWeightKg = (selectedWeightLb * 0.453592).toInt();
      }

      SharedPref.saveString(SharePrefKey.workOutDay, selectedWorkOut);
      SharedPref.saveInt(SharePrefKey.height, selectedCm);
      SharedPref.saveInt(SharePrefKey.weight, selectedWeightKg);
      SharedPref.saveString(SharePrefKey.goalWeight, selectedWGoal);
      SharedPref.saveInt(SharePrefKey.desiredWeight, selectedDesiredWeight);

      double bmr = calculateBMR(
        selectedCm,
        selectedWeightKg,
        ConstantUserMaster.age,
        ConstantUserMaster.gender,
      );
      double activityFactor = getActivityFactor(selectedWorkOut);
      double tdee = bmr * activityFactor;
      double adjusted = adjustCaloriesForGoal(
        tdee,
        selectedWeightKg,
        selectedDesiredWeight,
        selectedWGoal,
      );
      Map<String, int> macros = calculateMacros(adjusted, selectedWeightKg);
      SharedPref.saveInt(SharePrefKey.calorie, macros["calories"]);
      SharedPref.saveInt(SharePrefKey.protein, macros["protein"]);
      SharedPref.saveInt(SharePrefKey.carbs, macros["carbs"]);
      SharedPref.saveInt(SharePrefKey.fat, macros["fat"]);
      ConstantUserMaster.calorieGoal = macros['calories']!;
      ConstantUserMaster.proteinGoal = macros['protein']!;
      ConstantUserMaster.carbGoal = macros['carbs']!;
      ConstantUserMaster.fatsGoal = macros['fat']!;
      ConstantUserMaster.workOutDay = selectedWorkOut;
      ConstantUserMaster.height = selectedCm;
      ConstantUserMaster.weight = selectedWeightKg;
      ConstantUserMaster.goalWeight = selectedWGoal;
      ConstantUserMaster.desiredGoal = selectedDesiredWeight;
      selectedUpdateGoalView = 1;

      onChangeAutoGenerate(false);
    } else {
      // manual edits: save current goal values
      SharedPref.saveInt(SharePrefKey.calorie, ConstantUserMaster.calorieGoal);
      SharedPref.saveInt(SharePrefKey.protein, ConstantUserMaster.proteinGoal);
      SharedPref.saveInt(SharePrefKey.carbs, ConstantUserMaster.carbGoal);
      SharedPref.saveInt(SharePrefKey.fat, ConstantUserMaster.fatsGoal);
    }
    // show success and reset changes flag
    showSaveNotification();
    setHasChanges(false);
    update();
  }

  double calculateBMR(int heightCm, int weightKg, int age, String gender) {
    if (gender.toLowerCase() == "male") {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
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

  Map<String, int> calculateMacros(double tdee, int weightKg) {
    double protein = weightKg * 2.0; // 2g protein per kg
    double fat = (tdee * 0.25) / 9; // 25% of calories from fat (1g fat = 9 cal)
    double carbs =
        (tdee - ((protein * 4) + (fat * 9))) /
        4; // Remaining calories for carbs (1g = 4 cal)

    return {
      "calories": tdee.toInt(),
      "protein": protein.toInt(),
      "fat": fat.toInt(),
      "carbs": carbs.toInt(),
    };
  }
}
