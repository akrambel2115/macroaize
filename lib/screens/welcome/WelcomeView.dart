import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/welcome/WelcomeController.dart';
import 'package:foodcalorietracker/widgets/AnimatedBackground.dart';

class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WelcomeController>(
      init: WelcomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              const AnimatedBackground(),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Mascot Animation
                      AnimatedBuilder(
                        animation: controller.mascotAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: controller.mascotAnimation.value,
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: SizedBox(
                                height: 280,
                                child: Lottie.asset(
                                  AppAssets.mascot,
                                  fit: BoxFit.contain,
                                  repeat: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: controller.textAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, controller.textAnimation.value),
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: Text(
                                'welcome_hi'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  fontFamily:
                                      (Get.locale?.languageCode ??
                                                  Get
                                                      .deviceLocale
                                                      ?.languageCode) ==
                                              'ar'
                                          ? 'NotoSansArabic'
                                          : 'Poppins',
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
                            offset: Offset(
                              0,
                              controller.subtitleAnimation.value,
                            ),
                            child: Opacity(
                              opacity: controller.fadeAnimation.value,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    fontFamily:
                                        (Get.locale?.languageCode ??
                                                    Get
                                                        .deviceLocale
                                                        ?.languageCode) ==
                                                'ar'
                                            ? 'NotoSansArabic'
                                            : 'Poppins',
                                    color:
                                        context
                                            .theme
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'welcome_subtitle_prefix'.tr,
                                    ),
                                    TextSpan(
                                      text: 'welcome_subtitle_highlight'.tr,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontFamily:
                                            (Get.locale?.languageCode ??
                                                        Get
                                                            .deviceLocale
                                                            ?.languageCode) ==
                                                    'ar'
                                                ? 'NotoSansArabic'
                                                : 'Poppins',
                                        color: AppColor.primaryOrange,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 2),
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
