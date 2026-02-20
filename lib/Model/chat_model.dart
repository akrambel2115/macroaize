

class ChatModel {
  final bool isUser;
  final String text;
  final String? file;
  final bool isFeed;

  ChatModel(this.isUser, this.text,this.file, this.isFeed);

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'file' : file,
      'isFeed': isFeed,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      json['isUser'] as bool,
      json['text'] as String,
      json['file'] as String,
      json['isFeed'] as bool,
    );
  }
}
