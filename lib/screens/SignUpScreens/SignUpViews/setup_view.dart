import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../signup_controller.dart';

class SetupView extends GetView<SignUpController> {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Block back button during plan generation
      onPopInvokedWithResult: (didPop, result) {
        // Intentionally empty — plan generation must complete.
        // This handler prevents iOS from freezing the gesture
        // recogniser when a swipe-back attempt is blocked.
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "We're setting everything up for you".tr,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Customizing health plan....".tr,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColor.neutralGrey600,
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Lottie.asset(
                    'assets/lottie/loader.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
