import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';

class PlanIntroController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController mainController;
  late AnimationController buttonPressController;
  
  late Animation<double> fadeAnimation;
  late Animation<double> lottieAnimation;
  late Animation<double> headingAnimation;
  late Animation<double> subtitleAnimation;
  late Animation<double> buttonAnimation;
  late Animation<double> buttonPressAnimation;
  
  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _startAnimationSequence();
  }
  
  void _initializeAnimations() {
    // Main animation controller
    mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Button press animation controller
    buttonPressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Fade in animation
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    // Lottie scale animation
    lottieAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    // Heading slide animation
    headingAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));
    
    // Subtitle slide animation
    subtitleAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    ));
    
    // Button slide animation
    buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));
    
    // Button press animation
    buttonPressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: buttonPressController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _startAnimationSequence() {
    mainController.forward();
  }
  
  void onButtonPressed() {
    buttonPressController.forward();
  }
  
  void onButtonReleased() {
    buttonPressController.reverse();
  }
  
  void navigateToGenderChoice() {
    // Navigate to existing gender choice screen with a smooth transition
  Get.toNamed(Routes.signUpView);
  }
  
  @override
  void onClose() {
    mainController.dispose();
    buttonPressController.dispose();
    super.onClose();
  }
}
