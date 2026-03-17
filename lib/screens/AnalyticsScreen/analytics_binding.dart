import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:get/get.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AnalyticsController>()) {
      Get.lazyPut(() => AnalyticsController());
    }
  }
}
