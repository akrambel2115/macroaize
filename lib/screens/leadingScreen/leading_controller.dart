import 'package:flutter/material.dart';
import 'package:macroaize/shared/widgets/premium_required_dialog.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:macroaize/shared/services/email_verification_guard.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:get/get.dart';

class LeadingController extends GetxController {
  late final Map<String, dynamic> argument;
  int currentIndex = 0;
  final EmailVerificationGuard _verificationGuard = EmailVerificationGuard();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    argument = args is Map<String, dynamic> ? args : <String, dynamic>{};

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

    if (argument.isNotEmpty) {
      final argIndex = argument['index'];
      if (argIndex is int && argIndex >= 0 && argIndex <= 4) {
        currentIndex = argIndex;
      }
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
          safeBackAndNavigate(Routes.premiumView);
        },
        onCancel: () => safeBack(),
      ),
    );
  }
}
