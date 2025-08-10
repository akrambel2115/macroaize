class MainChatModel {
  int? id;
  String question;
  String answer;
  String date;

  MainChatModel({
    this.id,
    required this.question,
    required this.answer,
    required this.date,
  });

  // Convert a Art object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Question': question,
      'Answer': answer,
      'Date': date,
    };
  }

  // Extract a Art object from a Map object
  factory MainChatModel.fromMap(Map<String, dynamic> map) {
    return MainChatModel(
      id: map['id'],
      question: map['Question'],
      answer: map['Answer'],
      date: map['Date'],

    );
  }
}