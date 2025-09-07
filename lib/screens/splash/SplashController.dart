import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/Appkey.dart';
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
    // Do not auto-start here. The view will call startAnimations()
  }

  bool _started = false;

  /// Call from the view after the splash is visible to begin animations.
  void startAnimations() {
    if (_started) return;
    _started = true;
    _startAnimationSequence();
  }

  void _setupAppName() {
    // Use orange color for all letters in the app name
    for (int i = 0; i < appName.length; i++) {
      appNameLetters.add({
        'letter': appName[i],
        'color': AppColor.primaryOrange,
      });
    }
  }

  void _initializeAnimations() {
    // Main controller for overall timing
    mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Scale animation for final bounce (stronger pop)
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.elasticOut),
    );

    // Individual letter animations
    for (int i = 0; i < appNameLetters.length; i++) {
      AnimationController letterController = AnimationController(
        duration: const Duration(milliseconds: 450), // Faster animation
        vsync: this,
      );

      Animation<double> letterAnimation = Tween<double>(
        begin: -60.0, // Start above screen (less distance for smoother feel)
        end: 0.0, // End at normal position
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
