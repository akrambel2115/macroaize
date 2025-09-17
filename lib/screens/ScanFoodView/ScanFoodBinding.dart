
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodController.dart';
import 'package:get/get.dart';

class ScanFoodBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => ScanFoodController(),);
  }
}