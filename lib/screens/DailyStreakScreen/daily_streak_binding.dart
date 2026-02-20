import 'package:get/get.dart';
import 'daily_streak_controller.dart';

class DailyStreakBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DailyStreakController>(() => DailyStreakController());
  }
}
