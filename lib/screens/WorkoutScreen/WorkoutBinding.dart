import 'package:get/get.dart';
import 'package:macroaize/screens/WorkoutScreen/WorkoutController.dart';

class WorkoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkoutController>(() => WorkoutController());
  }
}
