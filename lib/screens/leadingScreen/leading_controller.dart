import 'package:flutter/material.dart';
import 'package:macroaize/shared/widgets/premium_required_dialog.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_controller.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:macroaize/shared/services/email_verification_guard.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:get/get.dart';

import '../HomeScreen/home_controller.dart';

class LeadingController extends GetxController {
  Map<String, dynamic>? argument = Get.arguments;
  int currentIndex = 0;
  final EmailVerificationGuard _verificationGuard = EmailVerificationGuard();

  @override
  void onInit() {
    super.onInit();

    // Check email verification
    _checkVerificationAsync();
  }

  void _checkVerificationAsync() async {
    if (!_verificationGuard.isSecurelyAuthenticated()) {
      final needsVerification = await _verificationGuard.needsVerification();
      if (needsVerification) {
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
    // access to recipes tab (index 1) for premium users
    if (index == 1) {
      try {
        final appUserService = Get.find<AppUserService>();
        final isPremium = await appUserService.isPremiumNow();
        if (!isPremium) {
          _showPremiumRequiredDialog();
          return;
        }
      } catch (_) {
        _showPremiumRequiredDialog();
        return;
      }
    }
    currentIndex = index;
    Get.delete<HomeController>();
    Get.delete<RecipesController>();
    Get.delete<AnalyticsController>();
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
