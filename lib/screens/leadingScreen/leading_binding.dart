import 'package:macroaize/screens/leadingScreen/leading_controller.dart';
import 'package:get/get.dart';

class LeadingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeadingController());
  }
}
