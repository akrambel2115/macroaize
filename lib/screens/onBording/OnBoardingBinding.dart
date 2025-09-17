
import 'package:get/get.dart';

import 'OnBoardingController.dart';

class OnBoardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OnBoardingController(),
    );
  }
}
