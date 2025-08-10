

class CalorieHistoryModel {
  final int? id;

  final int calorie;
  final String date;
  final int protein;
  final int carbs;
  final int fats;
  final String type;
   var image;

  CalorieHistoryModel({
    this.id,

    required this.calorie,
    required this.date,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.type,
    this.image,
  });

  // Convert a History object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'calorie': calorie,
      'date': date,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'type': type,
      'image': image,
    };
  }

  // Extract a History object from a Map object
  factory CalorieHistoryModel.fromMap(Map<String, dynamic> map) {
    return CalorieHistoryModel(
      id: map['id'],

      calorie: map['calorie'],
      date: map['date'],
      protein: map['protein'],
      carbs: map['carbs'],
      fats: map['fats'],
      type: map['type'],
      image: map['image'],
    );
  }
}
