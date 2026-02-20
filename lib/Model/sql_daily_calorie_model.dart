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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'calorie': calorie,
      'calorieId': calorieId,
      'date': date
    };
  }

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