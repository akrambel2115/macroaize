import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieController.dart';
import 'package:get/get.dart';

class ScanCalorieBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => ScanCalorieController(),);
  }
}