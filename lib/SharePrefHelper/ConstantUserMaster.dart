class ConstantUserMaster{
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
  static int  height = 0;
  static int  weight = 0;
  static String goalWeight = "";
  static int desiredGoal = 0;
  static int age = 0;
  static String bornDay = "";
  static String stoppedGoal = "";

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