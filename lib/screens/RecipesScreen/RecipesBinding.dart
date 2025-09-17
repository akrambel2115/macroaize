import 'package:get/get.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesController.dart';

class RecipesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<RecipesController>(RecipesController(), permanent: false);
  }
}
