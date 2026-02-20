import 'package:macroaize/screens/LocalFoodScreen/local_food_controller.dart';
import 'package:get/get.dart';

class LocalFoodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocalFoodController());
  }
}
