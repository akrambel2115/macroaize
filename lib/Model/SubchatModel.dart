

class SubChatModel {
  int? id;
  int? mainCharId;
  String question;
  String answer;
  String date;
  String? image;

  SubChatModel({
    this.id,
    required this.question,
    required this.mainCharId,
    required this.answer,
    required this.date,
    this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Question': question,
      'MainChatID': mainCharId,
      'Answer': answer,
      'Date': date,
      'image': image,
    };
  }

  factory SubChatModel.fromMap(Map<String, dynamic> map) {
    return SubChatModel(
      id: map['id'],
      question: map['Question'],
      mainCharId: map['MainChatID'],
      answer: map['Answer'],
      date: map['Date'],
      image: map['image'],

    );
  }
}