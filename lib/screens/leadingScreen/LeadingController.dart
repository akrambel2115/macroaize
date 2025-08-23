import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesController.dart';
import 'package:get/get.dart';

import '../HomeScreen/HomeController.dart';

class LeadingController extends GetxController{
  Map<String,dynamic>? argument = Get.arguments;
  int currentIndex = 0;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    if(argument != null)
    {
      Get.delete<HomeController>();
      Get.delete<RecipesController>();
      Get.delete<AnalyticsController>();
      // Get.delete<MyGardenController>();
      // Get.delete<AskBotanistController>();
      currentIndex = argument!['index'];
      update();
    }
  }
  void changeTabIndex(int index) {
    currentIndex = index;
    Get.delete<HomeController>();
    Get.delete<RecipesController>();
    Get.delete<AnalyticsController>();
    // Get.delete<MyGardenController>();
    // Get.delete<AskBotanistController>();
    update();
  }


}