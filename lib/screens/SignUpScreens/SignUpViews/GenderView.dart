import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class GenderView extends GetView<SignUpController> {
  const GenderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

  // Back button moved to the SignUp scaffold to keep layout consistent
        Text(
          "Choose Your Gender".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20),
        Text(
          "This Will be used to calibrate your custom plan".tr,
          style: context.theme.textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 10),
        GetBuilder<SignUpController>(
          builder: (c) {
            return Row(
              children: [
                Expanded(
                  child: _AvatarCard(
                    label: 'Male'.tr,
                    assetPath: 'assets/lottie/male.json',
                    selected: c.selectedGender == 'Male',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      c.onChangeGender('Male');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AvatarCard(
                    label: 'Female'.tr,
                    assetPath: 'assets/lottie/female.json',
                    selected: c.selectedGender == 'Female',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      c.onChangeGender('Female');
                    },
                  ),
                ),
              ],
            ).paddingOnly(top: 8, bottom: 8);
          },
        ),
  // Removed third gender option (Other) per August 2025 policy update.
        Spacer(),
        GetBuilder<SignUpController>(
          builder: (controller) {
            return GestureDetector(
              onTap: () {
                if(controller.selectedGender.isNotEmpty)
                  {
                    controller.onChangeView();
                  }
              },
              child: Container(
                alignment: Alignment.center,
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      controller.selectedGender.isNotEmpty
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Continue".tr,
                  style: context.theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AvatarCard extends StatefulWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarCard({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Duration _compDuration = const Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _compDuration);
    // Idle loop by default
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playActionOnce() async {
    try {
      await _controller.animateTo(1.0, duration: _compDuration * 0.6, curve: Curves.easeOut);
    } catch (_) {}
    if (mounted) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
  final isSelected = widget.selected;
  final baseLabelStyle = Theme.of(context).textTheme.titleMedium;
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
          _controller.reset();
          _playActionOnce();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            // Simple solid orange background when selected; no outline/glow
            color: isSelected ? AppColor.primaryOrange : Theme.of(context).cardColor,
            // keep a neutral shadow for depth, same for both states
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final double h = (constraints.maxWidth).clamp(120.0, 220.0);
                  return SizedBox(
                    height: h,
                    child: Lottie.asset(
                      widget.assetPath,
                      controller: _controller,
                      onLoaded: (comp) {
                        setState(() {
                          _compDuration = comp.duration;
                          _controller.duration = _compDuration;
                          if (!_controller.isAnimating) {
                            _controller.repeat();
                          }
                        });
                      },
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: baseLabelStyle?.copyWith(color: isSelected ? Colors.white : baseLabelStyle.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
