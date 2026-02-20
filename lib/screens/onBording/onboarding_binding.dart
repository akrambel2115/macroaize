
import 'package:get/get.dart';

import 'onboarding_controller.dart';

class OnBoardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OnBoardingController(),
    );
  }
}
