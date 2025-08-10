
import 'package:foodcalorietracker/screens/ChatHistoryScreen/ChatHistoryController.dart';
import 'package:get/get.dart';

class ChatHistoryBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => ChatHistoryController(),);
  }
}