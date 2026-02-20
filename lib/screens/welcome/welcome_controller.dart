import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/routes/app_routes.dart';

class WelcomeController extends GetxController
    with GetTickerProviderStateMixin {
  late AnimationController mainController;
  late Animation<double> fadeAnimation;
  late Animation<double> mascotAnimation;
  late Animation<double> textAnimation;
  late Animation<double> subtitleAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // fde in animation
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // ascot scale animation
    mascotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    // text slide up animation
    textAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: mainController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle slide up animation
    subtitleAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _startAnimationSequence() async {
    mainController.forward();

    // Auto-transition after 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    await Future.delayed(const Duration(milliseconds: 300));
    _navigateToNext();
  }

  void _navigateToNext() {
    // continue into onboarding flow without showing the transition screen
    Get.offAllNamed(Routes.planIntroView);
  }

  @override
  void onClose() {
    mainController.dispose();
    super.onClose();
  }
}
