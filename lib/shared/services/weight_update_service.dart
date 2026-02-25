import 'package:get/get.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';

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
}
