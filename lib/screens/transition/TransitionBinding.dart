import 'package:get/get.dart';
import 'TransitionController.dart';

class TransitionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransitionController>(() => TransitionController());
  }
}
