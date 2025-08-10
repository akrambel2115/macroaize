
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:get/get.dart';

class AnalyticsBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => AnalyticsController());
  }
}