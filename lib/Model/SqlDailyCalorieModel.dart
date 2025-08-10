class DailyCalorieModel {
  int? id;
  String time;
  int calorie;
  int calorieId;
  String date;


  DailyCalorieModel({
    this.id,
    required this.time,
    required this.calorie,
    required this.calorieId,
    required this.date,
  });

  // Convert a Art object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'calorie': calorie,
      'calorieId': calorieId,
      'date': date
    };
  }

  // Extract a Art object from a Map object
  factory DailyCalorieModel.fromMap(Map<String, dynamic> map) {
    return DailyCalorieModel(
      id: map['id'],
      time: map['time'],
      calorie: map['calorie'],
      calorieId: map['calorieId'],
      date: map['date'],

    );
  }
}