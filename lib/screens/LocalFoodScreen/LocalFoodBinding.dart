import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodController.dart';
import 'package:get/get.dart';

class LocalFoodBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => LocalFoodController(),);
  }
}