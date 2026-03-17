import 'package:macroaize/screens/SettingScreen/setting_controller.dart';
import 'package:get/get.dart';

class SettingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SettingController>()) {
      Get.lazyPut(() => SettingController());
    }
  }
}
