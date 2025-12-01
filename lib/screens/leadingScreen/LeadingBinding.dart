import 'package:foodcalorietracker/screens/leadingScreen/LeadingController.dart';
import 'package:get/get.dart';

class LeadingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeadingController());
  }
}
