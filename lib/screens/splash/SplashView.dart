import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/screens/splash/SplashController.dart';
import 'package:foodcalorietracker/constant/AppFonts.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late SplashController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SplashController());
    // Start animations shortly after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 80));
      controller.startAnimations();
    });
  }

  @override
  void dispose() {
    Get.delete<SplashController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App name letter-drop animation
                SizedBox(
                  height: 80,
                  child: Row(
                    // Force LTR so animated letters keep original ordering
                    textDirection: TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: controller.appNameLetters.map((letterData) {
                      int index = controller.appNameLetters.indexOf(letterData);
                      return AnimatedBuilder(
                        animation: controller.letterAnimations[index],
                        builder: (context, child) {
                          // Calculate opacity: 0 when above screen, 1 when at position
                          double opacity = controller.letterAnimations[index].status == AnimationStatus.dismissed ? 0.0 : 
                                         (controller.letterAnimations[index].value + 60.0) / 60.0;
                          opacity = opacity.clamp(0.0, 1.0);
                          
                          return Transform.translate(
                            offset: Offset(0, controller.letterAnimations[index].value),
                            child: Opacity(
                              opacity: opacity,
                              child: AnimatedBuilder(
                                animation: controller.scaleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: controller.scaleAnimation.value,
                                    child: Text(
                                      letterData['letter'],
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: AppFonts.splashFont,
                                        color: letterData['color'],
                                        letterSpacing: letterData['letter'] == ' ' ? 0 : 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
