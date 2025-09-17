import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController mainController;
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  List<AnimationController> letterControllers = [];
  List<Animation<double>> letterAnimations = [];

  List<Map<String, dynamic>> appNameLetters = [];

  @override
  void onInit() {
    super.onInit();
    _setupAppName();
    _initializeAnimations();
    // View triggers `startAnimations()` when visible
  }

  bool _started = false;

  /// Called by the view to begin animations when visible
  void startAnimations() {
    if (_started) return;
    _started = true;
    _startAnimationSequence();
  }

  void _setupAppName() {
    final name = Get.find<AppConfigService>().appName;
    // Use orange for letters
    for (int i = 0; i < name.length; i++) {
      appNameLetters.add({
        'letter': name[i],
        'color': AppColor.primaryOrange,
      });
    }
  }

  void _initializeAnimations() {
    // Main animation controller
    mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

  // Scale animation for final bounce
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.elasticOut),
    );

  // Individual letter animations (staggered)
    for (int i = 0; i < appNameLetters.length; i++) {
      AnimationController letterController = AnimationController(
  duration: const Duration(milliseconds: 450),
        vsync: this,
      );

      Animation<double> letterAnimation = Tween<double>(
  begin: -60.0,
  end: 0.0,
      ).animate(
        CurvedAnimation(parent: letterController, curve: Curves.easeOutBack),
      );

      letterControllers.add(letterController);
      letterAnimations.add(letterAnimation);
    }
  }

  void _startAnimationSequence() async {
    // Start letter animations with staggered delay - don't await each one
    for (int i = 0; i < letterControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        letterControllers[i].forward();
      });
    }

    // Wait for all letters to finish dropping
    await Future.delayed(
      Duration(milliseconds: 120 * letterControllers.length + 500),
    );

    // Start scale animation
    scaleController.forward().then((_) {
      scaleController.reverse();
    });

    // Navigate to next screen after animations
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Check if onboarding is completed
    final onboardingCompleted =
        await SharedPref.readBool(SharePrefKey.onboardingCompleted) ?? false;

    if (onboardingCompleted) {
      // User has completed onboarding, play the transition Lottie then go home
      Get.offAllNamed(Routes.transitionView);
    } else {
      // User hasn't completed onboarding, go to welcome flow
      Get.offAllNamed(Routes.welcomeView);
    }
  }

  @override
  void onClose() {
    mainController.dispose();
    scaleController.dispose();
    for (var controller in letterControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
