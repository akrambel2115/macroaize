import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../constant/app_color.dart';
import '../routes/app_routes.dart';

/// Small rounded badge for email verification with warning icon
class VerifyEmailButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;

  const VerifyEmailButton({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Not authenticated or already verified - don't show badge
        if (user == null || user.emailVerified) {
          return const SizedBox.shrink();
        }

        // Show verify email badge
        return Container(
          padding: padding,
          child: GestureDetector(
            onTap: () => Get.toNamed(Routes.emailVerificationView),
            child: _buildBadge(),
          ),
        );
      },
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.warning,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.warning.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'verify'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
