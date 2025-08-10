
import 'package:get/get.dart';

import 'OnBoardingController.dart';

class OnBoardingBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(
      () => OnBoardingController(),
    );
  }
}
