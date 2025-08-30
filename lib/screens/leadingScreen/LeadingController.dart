import 'package:flutter/material.dart';
import 'package:foodcalorietracker/shared/widgets/PremiumRequiredDialog.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesController.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
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
  void changeTabIndex(int index) async {
    // Gate access to recipes tab (index 1) for premium users only
    if (index == 1) {
      try {
        final appUserService = Get.find<AppUserService>();
        final isPremium = await appUserService.isPremiumNow();
        if (!isPremium) {
          _showPremiumRequiredDialog();
          return;
        }
      } catch (_) {
        // Fail closed on any error
        _showPremiumRequiredDialog();
        return;
      }
    }
    currentIndex = index;
    Get.delete<HomeController>();
    Get.delete<RecipesController>();
    Get.delete<AnalyticsController>();
    // Get.delete<MyGardenController>();
    // Get.delete<AskBotanistController>();
    update();
  }

  void _showPremiumRequiredDialog() {
    Get.dialog(
      PremiumRequiredDialog(
        title: 'Premium Required'.tr,
        message: 'Access to recipes requires a premium subscription. Upgrade now to unlock this feature.'.tr,
        badge: Text(
          'Unlock all recipes and features with Premium',
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        onUpgrade: () {
          Get.back();
          Get.toNamed(Routes.premiumView);
        },
        onCancel: () => Get.back(),
      ),
    );
  }


}