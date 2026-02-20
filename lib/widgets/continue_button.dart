import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/primary_cta.dart';

/// Continue button with a localized default label.
class ContinueButton extends StatelessWidget {
  final String? labelKey;
  final String? text; // Custom text override
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final Animation<double>? pressAnimation;
  final IconData? icon;

  const ContinueButton({
    super.key,
    this.labelKey,
    this.text,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.pressAnimation,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final label = text ?? (labelKey ?? 'continue_cta').tr;
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
