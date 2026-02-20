import 'package:get/get.dart';
import 'transition_controller.dart';

class TransitionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransitionController>(() => TransitionController());
  }
}
