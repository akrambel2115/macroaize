import 'package:foodcalorietracker/screens/SettingScreen/SettingController.dart';
import 'package:get/get.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => SettingController(),);
  }
}