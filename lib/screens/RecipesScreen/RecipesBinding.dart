import 'package:get/get.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesController.dart';

class RecipesBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put instead of lazyPut to ensure controller is available immediately
    // This prevents null pointer exceptions when navigating to the page
    Get.put<RecipesController>(RecipesController(), permanent: false);
  }
}
