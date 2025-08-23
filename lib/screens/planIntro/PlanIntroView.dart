import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/planIntro/PlanIntroController.dart';
import 'package:foodcalorietracker/widgets/AnimatedBackground.dart';

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
              // Animated Background
              const AnimatedBackground(),
              
              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      
                      // Diet Lottie Animation
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
                      
                      // Main Heading
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
                      
                      // Subtitle
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
                      
                      // Continue Button
                      AnimatedBuilder(
                        animation: controller.buttonAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: controller.buttonAnimation.value,
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: _buildContinueButton(context, controller),
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

  Widget _buildContinueButton(BuildContext context, PlanIntroController controller) {
    return GestureDetector(
      onTapDown: (_) => controller.onButtonPressed(),
      onTapUp: (_) => controller.onButtonReleased(),
      onTapCancel: () => controller.onButtonReleased(),
      onTap: () => controller.navigateToGenderChoice(),
      child: AnimatedBuilder(
        animation: controller.buttonPressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: controller.buttonPressAnimation.value,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColor.primaryOrange,
                    AppColor.primaryOrange.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'continue_cta'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
