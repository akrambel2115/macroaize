import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class PremiumRequiredDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget badge;
  final VoidCallback? onUpgrade;
  final VoidCallback? onCancel;

  const PremiumRequiredDialog({
    super.key,
    this.title = 'Premium Feature',
    required this.message,
    required this.badge,
    this.onUpgrade,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Get.theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.star, color: Colors.orange, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Get.textTheme.bodyMedium),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: badge,
          ),
        ],
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed:
                  onUpgrade ??
                  () {
                    Get.back();
                    Get.toNamed(Routes.premiumView);
                  },
              child: Text(
                'go_premium'.tr,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onCancel ?? () => Get.back(),
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                'maybe_later'.tr,
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
