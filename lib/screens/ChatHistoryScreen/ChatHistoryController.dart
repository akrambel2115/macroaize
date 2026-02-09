import 'package:macroaize/Model/MainChatModel.dart';
import 'package:macroaize/constant/DatabaseHelper.dart';
import 'package:get/get.dart';

class ChatHistoryController extends GetxController {
  List<MainChatModel> history = [];
  final dbHelper = DatabaseHelper();
  @override
  void onInit() {
    super.onInit();
    getHistory();
  }

  getHistory() async {
    history = await dbHelper.getMainChat();
    history = history.reversed.toList();
    update();
  }

  deleteChatHistory(int id) async {
    await dbHelper.deleteMainChat(id);
    getHistory();
  }
}
