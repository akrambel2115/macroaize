import 'package:get/get.dart';
import 'PlanIntroController.dart';

class PlanIntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlanIntroController>(() => PlanIntroController());
  }
}
