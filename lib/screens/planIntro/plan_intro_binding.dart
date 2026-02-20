import 'package:get/get.dart';
import 'plan_intro_controller.dart';

class PlanIntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanIntroController>(() => PlanIntroController());
  }
}
