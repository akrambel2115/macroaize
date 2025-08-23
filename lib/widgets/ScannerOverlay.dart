import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:get/utils.dart';

/// Reusable scanner overlay widget.
/// Draws a darkened backdrop with a centered rounded scanning frame.
class ScannerOverlay extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color borderColor;

  const ScannerOverlay({
    super.key,
    this.width = 280,
    this.height = 280,
    this.borderRadius = 40,
    this.borderColor = AppColor.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft dark backdrop
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.42),
          ),
        ),

        // Center scanning frame — rounded and smooth (no square corner blocks)
        Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                children: [
                  // subtle inner tint to indicate active area
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(borderRadius - 6),
                        border: Border.all(
                          color: AppColor.primaryOrange.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Center icon / affordance
                  const Center(
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Instruction pill
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Center food in the frame and tap to scan'.tr,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
