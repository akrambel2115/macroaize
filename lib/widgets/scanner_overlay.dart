import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/utils.dart';

class ScannerOverlay extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color borderColor;
  final String? hintText;
  final int? remainingScans;
  final int? scanLimit;
  final VoidCallback? onUpgradeTap;

  const ScannerOverlay({
    super.key,
    this.width = 280,
    this.height = 280,
    this.borderRadius = 40,
    this.borderColor = AppColor.primaryOrange,
    this.hintText,
    this.remainingScans,
    this.scanLimit,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.42)),
        ),

        Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(borderRadius - 6),
                        border: Border.all(
                          color: AppColor.primaryOrange.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const Center(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top:
              MediaQuery.of(context).padding.top +
              70, // Clear the status bar + back buttons perfectly
          left: 20,
          right: 20,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hint Text
                Text(
                  hintText ?? 'Center food in the frame and tap to scan'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Remaining Scans Row (conditionally rendered but styling preserved)
                if (remainingScans != null && scanLimit != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$remainingScans ${'scans_remaining'.tr}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                remainingScans! > 0
                                    ? Colors.white
                                    : AppColor.primaryOrange,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onUpgradeTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColor.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Add".tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
