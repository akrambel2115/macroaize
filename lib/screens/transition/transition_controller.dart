import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'dart:async';

class TransitionController extends GetxController
    with GetTickerProviderStateMixin {
  late AnimationController fadeController;
  late Animation<double> fadeAnim;
  late AnimationController lottieController;
  Timer? _completeTimer;
  bool _hasCompletedFlow = false;

  @override
  void onInit() {
    super.onInit();
    _selectAsset();
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnim = CurvedAnimation(parent: fadeController, curve: Curves.easeIn);

    lottieController = AnimationController(vsync: this);

    fadeController.forward();
  }

  String assetPath = AppAssets.transition;

  void _selectAsset() async {
    assetPath = AppAssets.transition;
    update();
  }

  void onLottieComplete() async {
    if (_hasCompletedFlow) return;
    _hasCompletedFlow = true;

    _completeTimer?.cancel();
    _completeTimer = Timer(const Duration(milliseconds: 250), () async {
      if (isClosed) return;
      final onboardingCompleted =
          await SharedPref.readBool(SharePrefKey.onboardingCompleted) ?? false;
      if (isClosed) return;
      if (onboardingCompleted) {
        Get.offAllNamed(Routes.leadingView);
      } else {
        Get.offAllNamed(Routes.planIntroView);
      }
    });
  }

  @override
  void onClose() {
    _completeTimer?.cancel();
    fadeController.dispose();
    lottieController.dispose();
    super.onClose();
  }
}
