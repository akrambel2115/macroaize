import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';

class TransitionController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController fadeController;
  late Animation<double> fadeAnim;
  late AnimationController lottieController;

  @override
  void onInit() {
    super.onInit();
  _selectAsset();
    fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    fadeAnim = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    lottieController = AnimationController(vsync: this);

    fadeController.forward();
  }

  String assetPath = AppAssets.transition;

  void _selectAsset() async {
    final onboardingCompleted = await SharedPref.readBool(SharePrefKey.onboardingCompleted) ?? false;

  assetPath = onboardingCompleted ? AppAssets.loader : AppAssets.transition;
    update();
  }

  void onLottieComplete() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final onboardingCompleted = await SharedPref.readBool(SharePrefKey.onboardingCompleted) ?? false;
    if (onboardingCompleted) {
      Get.offAllNamed(Routes.leadingView);
    } else {
      Get.offAllNamed(Routes.planIntroView);
    }
  }

  @override
  void onClose() {
    fadeController.dispose();
    lottieController.dispose();
    super.onClose();
  }
}
