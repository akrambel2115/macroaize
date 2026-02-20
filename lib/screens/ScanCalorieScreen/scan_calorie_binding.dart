import 'package:macroaize/screens/ScanCalorieScreen/scan_calorie_controller.dart';
import 'package:get/get.dart';

class ScanCalorieBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ScanCalorieController());
  }
}
