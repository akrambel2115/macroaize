import 'package:get/get.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_controller.dart';

class RecipesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RecipesController>()) {
      Get.lazyPut(() => RecipesController());
    }
  }
}
