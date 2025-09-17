
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:get/get.dart';

class AnalyticsBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => AnalyticsController());
  }
}