import 'package:foodcalorietracker/screens/ChatScreen/ChatController.dart';
import 'package:get/get.dart';

class ChatBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => ChatController(),);
  }
}