import 'package:macroaize/screens/ChatHistoryScreen/ChatHistoryController.dart';
import 'package:get/get.dart';

class ChatHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChatHistoryController());
  }
}
