import 'package:macroaize/screens/ScanFoodView/scan_food_controller.dart';
import 'package:get/get.dart';

class ScanFoodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScanFoodController());
  }
}
