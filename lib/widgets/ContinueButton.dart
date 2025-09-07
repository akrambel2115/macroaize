import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/widgets/PrimaryCTA.dart';

/// Reusable Continue button used across onboarding / plan intro flows.
///
/// This wraps `PrimaryCTA` and provides a localized default label so callers
/// can use a single widget for the 'Continue' CTA.
class ContinueButton extends StatelessWidget {
  final String? labelKey; // localization key, default 'continue_cta'
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final Animation<double>? pressAnimation;
  final IconData? icon;

  const ContinueButton({
    super.key,
    this.labelKey,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.pressAnimation,
  this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final label = (labelKey ?? 'continue_cta').tr;
    return PrimaryCTA(
      label: label,
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      pressAnimation: pressAnimation,
      icon: icon,
    );
  }
}
