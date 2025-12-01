import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:get/get.dart';

class AdjustGoalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AdjustGoalsController());
  }
}
