import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:lottie/lottie.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'transition_controller.dart';

class TransitionView extends GetView<TransitionController> {
  const TransitionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TransitionController>(
      init: TransitionController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              FadeTransition(
                opacity: controller.fadeAnim,
                child: Builder(
                  builder: (ctx) {
                    if (controller.assetPath == AppAssets.loadingClock ||
                        controller.assetPath == AppAssets.loader) {
                      return Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Lottie.asset(
                            controller.assetPath,
                            controller: controller.lottieController,
                            onLoaded: (composition) {
                              controller.lottieController
                                .duration = composition.duration;
                              controller.lottieController
                                  .forward()
                                  .whenComplete(
                                    () => controller.onLottieComplete(),
                                  );
                            },
                            fit: BoxFit.contain,
                            repeat: false,
                          ),
                        ),
                      );
                    }

                    // transition for first time flow
                    return SizedBox.expand(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scaleByVector3(Vector3(-1.0, 1.0, 1.0)),
                        child: Lottie.asset(
                          controller.assetPath,
                          controller: controller.lottieController,
                          onLoaded: (composition) {
                            controller.lottieController
                              ..duration = composition.duration
                              ..forward().whenComplete(
                                () => controller.onLottieComplete(),
                              );
                          },
                          fit: BoxFit.cover,
                          repeat: false,
                        ),
                      ),
                    );
                  },
                ),
              ),

              SafeArea(child: Container()),
            ],
          ),
        );
      },
    );
  }
}
