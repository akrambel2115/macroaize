import 'package:macroaize/screens/AdjustGoals/adjust_goals_controller.dart';
import 'package:get/get.dart';

class AdjustGoalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdjustGoalsController());
  }
}
