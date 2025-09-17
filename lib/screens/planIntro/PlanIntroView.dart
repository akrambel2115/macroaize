import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/screens/planIntro/PlanIntroController.dart';
import 'package:foodcalorietracker/widgets/AnimatedBackground.dart';
import 'package:foodcalorietracker/widgets/ContinueButton.dart';

// Intro screen for the plan flow with animated visuals and continue CTA.
class PlanIntroView extends GetView<PlanIntroController> {
  const PlanIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PlanIntroController>(
      init: PlanIntroController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              const AnimatedBackground(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      AnimatedBuilder(
                        animation: controller.lottieAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: controller.lottieAnimation.value,
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 64,
                                height: 280,
                                child: Transform.scale(
                                  scale: 1.4,
                                  child: Lottie.asset(
                                    AppAssets.diet,
                                    fit: BoxFit.fitWidth,
                                    repeat: true,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: controller.headingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, controller.headingAnimation.value),
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: Text(
                                'plan_intro_title'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                  color: context.theme.primaryColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: controller.subtitleAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, controller.subtitleAnimation.value),
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: Text(
                                'plan_intro_subtitle'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: context.theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(flex: 2),
                      AnimatedBuilder(
                        animation: controller.buttonAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: controller.buttonAnimation.value,
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: ContinueButton(
                                pressAnimation: controller.buttonPressAnimation,
                                onTapDown: controller.onButtonPressed,
                                onTapUp: controller.onButtonReleased,
                                onTapCancel: controller.onButtonReleased,
                                onTap: controller.navigateToGenderChoice,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
