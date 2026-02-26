import 'package:flutter/material.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/widgets/app_widgets.dart';
import 'package:get/get.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  int _prevStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom + 10,
          right: 10,
          left: 10,
        ),
        child: GetBuilder<SignUpController>(
          builder: (controller) {
            // map to 7 steps (theme choice prepended)
            final int stepIndex = controller.selectedView.clamp(0, 6);
            final bool forward = stepIndex >= _prevStep;

            // update prev step
            _prevStep = stepIndex;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // step progress
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: _StepProgressIndicator(
                    currentStep: stepIndex,
                    total: 7,
                    activeColor: AppColor.primaryOrange,
                  ),
                ),
                // back button
                if (controller.selectedView < 8) // hide on setup/review
                  AppWidgets.backButton(context, () {
                    if (controller.selectedView > 0) {
                      controller.selectedView = controller.selectedView - 1;
                      controller.update();
                    } else {
                      Get.back();
                    }
                  }),
                const SizedBox(height: 8),

                // active screen
                Expanded(
                  child: AnimatedSwitcher(
                    // smooth transition
                    duration: const Duration(milliseconds: 700),
                    // ease in out
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      // slide fade rtl aware
                      final textDir = Directionality.of(context);
                      final bool isRtl = textDir == TextDirection.rtl;

                      // animation offset
                      final Offset begin =
                          forward
                              ? (isRtl
                                  ? const Offset(-1.0, 0.0)
                                  : const Offset(1.0, 0.0))
                              : (isRtl
                                  ? const Offset(1.0, 0.0)
                                  : const Offset(-1.0, 0.0));

                      final offsetAnimation = animation.drive(
                        Tween<Offset>(
                          begin: begin,
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOut)),
                      );

                      final fadeAnim = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );

                      return FadeTransition(
                        opacity: fadeAnim,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(controller.selectedView),
                      child: controller.screens[controller.selectedView],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep; // current index
  final int total;
  final Color? activeColor;

  const _StepProgressIndicator({
    required this.currentStep,
    required this.total,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = activeColor ?? context.theme.primaryColor;
    final track = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.14)
        : AppColor.neutralGrey200;
    final progress = ((currentStep + 1) / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 10,
          color: track,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
