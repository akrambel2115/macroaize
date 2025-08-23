import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
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
        child: GetBuilder<SignUpController>(builder: (controller) {
          // Map the selectedView into a 6-step progress (gender..stoppingGoal)
          final int stepIndex = controller.selectedView.clamp(0, 5);
          final bool forward = stepIndex >= _prevStep;

          // Update prev step for next build (no setState required)
          _prevStep = stepIndex;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step progress indicator (6 steps) — show above the back button on all pages
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: _StepProgressIndicator(
                  currentStep: stepIndex,
                  total: 6,
                  activeColor: AppColor.primaryOrange,
                ),
              ),
              // Top left back button (use shared AppWidgets.backButton for consistent look)
              AppWidgets.backButton(context, () {
                if (controller.selectedView > 0) {
                  controller.selectedView = controller.selectedView - 1;
                  controller.update();
                } else {
                  Get.back();
                }
              }),
              const SizedBox(height: 8),

              // The active screen with smooth animated transitions
              Expanded(
                child: AnimatedSwitcher(
                  // Increased duration for a slower, smoother transition
                  duration: const Duration(milliseconds: 700),
                  // Use symmetric easeInOut curves for smoother entrance/exit
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    // Combine slide + fade for a smoother transition.
                    // When the app is in RTL (e.g., Arabic) we need to flip the
                    // slide direction so forward/back navigation feels natural.
                    final textDir = Directionality.of(context);
                    final bool isRtl = textDir == TextDirection.rtl;

                    // Determine the animation start offset based on directionality
                    // and whether the navigation is forward.
                    final Offset begin = forward
                        ? (isRtl ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0))
                        : (isRtl ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0));

                    final offsetAnimation = animation.drive(Tween<Offset>(
                      begin: begin,
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeInOut)));

                    final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

                    return FadeTransition(
                      opacity: fadeAnim,
                      child: SlideTransition(position: offsetAnimation, child: child),
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
        }),
      ),
    );
  }
}

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep; // 0-based
  final int total;
  final Color? activeColor;

  const _StepProgressIndicator({required this.currentStep, required this.total, this.activeColor});

  @override
  Widget build(BuildContext context) {
  final primary = activeColor ?? context.theme.primaryColor;
    final inactive = Colors.grey.shade300;
    const duration = Duration(milliseconds: 420);
    const curve = Curves.easeInOut;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total * 2 - 1, (i) {
        if (i.isEven) {
          final idx = i ~/ 2;
          final active = idx <= currentStep;
          final double size = active ? 34 : 28;
          return AnimatedContainer(
            duration: duration,
            curve: curve,
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: active ? primary : Colors.white,
              border: Border.all(color: active ? primary : Colors.grey.shade400, width: 2),
              shape: BoxShape.circle,
              boxShadow: active
                  ? [BoxShadow(color: (primary).withOpacity(0.18), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              child: Text('${idx + 1}'),
            ),
          );
        } else {
          final leftIdx = (i - 1) ~/ 2;
          final active = leftIdx < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: active ? primary : inactive,
            ),
          );
        }
      }),
    );
  }
}
