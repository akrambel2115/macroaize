import 'package:macroaize/screens/ChatHistoryScreen/chat_history_controller.dart';
import 'package:get/get.dart';

class ChatHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChatHistoryController());
  }
}
