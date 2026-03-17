import 'package:get/get.dart';
import 'package:macroaize/screens/DailyStreakScreen/daily_streak_controller.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/screens/HomeScreen/home_controller.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_controller.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_controller.dart';
import 'package:macroaize/screens/SettingScreen/setting_controller.dart';
import 'package:macroaize/screens/leadingScreen/leading_controller.dart';

class LeadingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LeadingController>()) {
      Get.lazyPut(() => LeadingController());
    }
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut(() => HomeController());
    }
    if (!Get.isRegistered<RecipesController>()) {
      Get.lazyPut(() => RecipesController());
    }
    if (!Get.isRegistered<AnalyticsController>()) {
      Get.lazyPut(() => AnalyticsController());
    }
    if (!Get.isRegistered<ScanFoodController>()) {
      Get.lazyPut(() => ScanFoodController());
    }
    if (!Get.isRegistered<SettingController>()) {
      Get.lazyPut(() => SettingController());
    }
    if (!Get.isRegistered<DailyStreakController>()) {
      Get.lazyPut(() => DailyStreakController());
    }
  }
}
