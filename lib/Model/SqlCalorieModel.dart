class SqlCalorieModel {
  int? id;
  String date;
  int totalGoal;
  int calorie;
  int protein;
  int carbs;
  int fats;

  SqlCalorieModel({
    this.id,
    required this.date,
    required this.totalGoal,
    required this.calorie,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  // Convert a Art object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'totalGoal': totalGoal,
      'calorie': calorie,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  // Extract a Art object from a Map object
  factory SqlCalorieModel.fromMap(Map<String, dynamic> map) {
    return SqlCalorieModel(
      id: map['id'],
      date: map['date'],
      totalGoal: map['totalGoal'],
      calorie: map['calorie'],
      protein: map['protein'],
      carbs: map['carbs'],
      fats: map['fats'],
    );
  }
}