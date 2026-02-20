import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';

class PrimaryCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;
  final Animation<double>? pressAnimation;
  final IconData? icon;

  const PrimaryCTA({
    super.key,
    required this.label,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.pressAnimation,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner = Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryOrange,
            AppColor.primaryOrange.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 12),
            Icon(icon, color: Colors.white, size: 24),
          ],
        ],
      ),
    );

    if (pressAnimation != null) {
      inner = AnimatedBuilder(
        animation: pressAnimation!,
        builder: (ctx, child) {
          return Transform.scale(scale: pressAnimation!.value, child: child);
        },
        child: inner,
      );
    }

    return GestureDetector(
      onTapDown: (_) => onTapDown?.call(),
      onTapUp: (_) => onTapUp?.call(),
      onTapCancel: () => onTapCancel?.call(),
      onTap: onTap,
      child: inner,
    );
  }
}
