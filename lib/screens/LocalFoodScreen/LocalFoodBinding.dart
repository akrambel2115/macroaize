import 'package:macroaize/screens/LocalFoodScreen/LocalFoodController.dart';
import 'package:get/get.dart';

class LocalFoodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocalFoodController());
  }
}
