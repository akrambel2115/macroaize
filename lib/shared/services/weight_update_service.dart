import 'package:get/get.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/screens/leadingScreen/leading_controller.dart';

class WeightUpdateService {
  const WeightUpdateService._();

  static Future<void> updateWeight(int newWeight) async {
    if (newWeight <= 0) return;

    final analyticsController =
        Get.isRegistered<AnalyticsController>()
            ? Get.find<AnalyticsController>()
            : Get.put(AnalyticsController());

    await analyticsController.updateCurrentWeight(newWeight);
  }

  static Future<void> updateWeightAndOpenOverview(int newWeight) async {
    await updateWeight(newWeight);

    if (Get.isRegistered<LeadingController>()) {
      final leadingController = Get.find<LeadingController>();
      leadingController.changeTabIndex(3);
    }
  }
}
