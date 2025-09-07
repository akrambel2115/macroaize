import 'package:flutter/material.dart';
import 'package:foodcalorietracker/shared/widgets/PremiumRequiredDialog.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesController.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/shared/services/email_verification_guard.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:get/get.dart';

import '../HomeScreen/HomeController.dart';

class LeadingController extends GetxController {
  Map<String, dynamic>? argument = Get.arguments;
  int currentIndex = 0;
  final EmailVerificationGuard _verificationGuard = EmailVerificationGuard();

  @override
  void onInit() {
    super.onInit();

    // CRITICAL: Check email verification on main screen access
    _checkVerificationAsync();
  }

  void _checkVerificationAsync() async {
    if (!_verificationGuard.isSecurelyAuthenticated()) {
      final needsVerification = await _verificationGuard.needsVerification();
      if (needsVerification) {
        // Use post-frame callback to avoid navigation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute != Routes.emailVerificationView) {
            Get.offNamed(Routes.emailVerificationView);
          }
        });
        return;
      }
    }

    if (argument != null) {
      Get.delete<HomeController>();
      Get.delete<RecipesController>();
      Get.delete<AnalyticsController>();
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
        title: 'premium_required'.tr,
        message: 'recipes_premium_message'.tr,
        badge: Text(
          'recipes_premium_badge'.tr,
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
