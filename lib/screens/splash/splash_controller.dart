import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/shared/services/app_config_service.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'dart:async';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  late AnimationController mainController;
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;

  List<AnimationController> letterControllers = [];
  List<Animation<double>> letterAnimations = [];

  List<Map<String, dynamic>> appNameLetters = [];
  final List<Timer> _letterDropTimers = [];
  Timer? _postLettersTimer;
  Timer? _navigateTimer;

  @override
  void onInit() {
    super.onInit();
    _setupAppName();
    _initializeAnimations();
  }

  bool _started = false;

  // start when visible
  void startAnimations() {
    if (_started) return;
    _started = true;
    _startAnimationSequence();
  }

  void _setupAppName() {
    final name = Get.find<AppConfigService>().appName;
    // setup letters
    for (int i = 0; i < name.length; i++) {
      appNameLetters.add({'letter': name[i], 'color': AppColor.primaryOrange});
    }
  }

  void _initializeAnimations() {
    // main controller
    mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // scale bounce
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.elasticOut),
    );

    // staggered letters
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

  void _startAnimationSequence() {
    for (final t in _letterDropTimers) {
      t.cancel();
    }
    _letterDropTimers.clear();
    _postLettersTimer?.cancel();
    _navigateTimer?.cancel();

    // staggered letter drop
    for (int i = 0; i < letterControllers.length; i++) {
      _letterDropTimers.add(
        Timer(Duration(milliseconds: 120 * i), () {
          if (isClosed) return;
          letterControllers[i].forward();
        }),
      );
    }

    _postLettersTimer = Timer(
      Duration(milliseconds: 120 * letterControllers.length + 500),
      () {
        if (isClosed) return;

        // scale bounce
        scaleController.forward().then((_) {
          if (isClosed) return;
          scaleController.reverse();
        });

        // navigate next
        _navigateTimer = Timer(const Duration(milliseconds: 1200), () {
          if (isClosed) return;
          _navigateToNext();
        });
      },
    );
  }

  void _navigateToNext() async {
    // check onboarding
    final onboardingCompleted =
        await SharedPref.readBool(SharePrefKey.onboardingCompleted) ?? false;

    if (onboardingCompleted) {
      // go to home
      Get.offAllNamed(Routes.leadingView);
    } else {
      // go to welcome
      Get.offAllNamed(Routes.welcomeView);
    }
  }

  @override
  void onClose() {
    for (final t in _letterDropTimers) {
      t.cancel();
    }
    _letterDropTimers.clear();
    _postLettersTimer?.cancel();
    _navigateTimer?.cancel();
    mainController.dispose();
    scaleController.dispose();
    for (var controller in letterControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
