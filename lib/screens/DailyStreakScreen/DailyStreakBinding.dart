import 'package:get/get.dart';
import 'DailyStreakController.dart';

class DailyStreakBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DailyStreakController>(() => DailyStreakController());
  }
}
