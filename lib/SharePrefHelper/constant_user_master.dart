class ConstantUserMaster {
  static int calorieGoal = 0;
  static int proteinGoal = 1;
  static int carbGoal = 1;
  static int fatsGoal = 1;
  static int todayCalorie = 0;
  static int todayProtein = 0;
  static int todayCarbs = 0;
  static int todayFats = 0;

  static String gender = "";
  static String workOutDay = "";
  static int height = 0;
  static int weight = 0;
  static String goalWeight = "";
  static int desiredGoal = 0;
  static int age = 0;
  static String bornDay = "";
  static String stoppedGoal = "";
  static int stepGoal = 10000;
  static int waterGoalMl = 2000;
}

Map<String, int> calculateMacrosFromTDEE(double tdee, int weightKg) {
  final protein = (weightKg * 2.0).toInt();
  final fat = ((tdee * 0.25) / 9).toInt();
  final carbs = ((tdee - ((protein * 4) + (fat * 9))) / 4).toInt();
  return {
    'calories': tdee.toInt(),
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
  };
}

double adjustCaloriesForGoal(
  double tdee,
  int currentWeight,
  int desiredGoal,
  String goalType,
) {
  final goal = goalType.trim();

  if (goal == 'Maintain Weight' || goal.isEmpty) return tdee;

  if (goal == 'Lose Weight') {
    if (desiredGoal < currentWeight) {
      final diff = (currentWeight - desiredGoal).abs();
      final pct = (diff >= 10) ? 0.20 : 0.15;
      return (tdee * (1 - pct)).clamp(1200, double.infinity);
    }
    return (tdee * (1 - 0.10)).clamp(1200, double.infinity);
  }

  if (goal == 'Gain Weight') {
    if (desiredGoal > currentWeight) {
      final diff = (desiredGoal - currentWeight).abs();
      final pct = (diff >= 10) ? 0.20 : 0.10;
      return (tdee * (1 + pct));
    }
    return (tdee * (1 + 0.10));
  }

  return tdee;
}

double estimateBMR(int heightCm, int weightKg, int age, String gender) {
  if (gender.toLowerCase() == 'male') {
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }
  return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
}

double getActivityFactor(String workOutDays) {
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
