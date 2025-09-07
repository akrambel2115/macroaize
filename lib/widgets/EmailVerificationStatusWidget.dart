import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constant/AppColor.dart';
import '../routes/app_routes.dart';

/// Reusable widget to show email verification status throughout the app
class EmailVerificationStatusWidget extends StatelessWidget {
  final bool showInlineActions;
  final bool compactMode;
  final EdgeInsetsGeometry? padding;

  const EmailVerificationStatusWidget({
    super.key,
    this.showInlineActions = true,
    this.compactMode = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        // Not authenticated - don't show anything
        if (user == null) {
          return const SizedBox.shrink();
        }

        // Email already verified - show success state
        if (user.emailVerified) {
          return _buildVerifiedStatus(context);
        }

        // Email not verified - show warning/action state
        return _buildUnverifiedStatus(context, user);
      },
    );
  }

  Widget _buildVerifiedStatus(BuildContext context) {
    if (compactMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColor.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.success.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 16, color: AppColor.success),
            const SizedBox(width: 6),
            Text(
              'email_verified_status'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColor.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'email_verified'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutralGrey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'email_verification_complete_subtitle'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColor.neutralGrey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedStatus(BuildContext context, User user) {
    if (compactMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColor.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.warning.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 16, color: AppColor.warning),
            const SizedBox(width: 6),
            Text(
              'email_unverified_status'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.warning,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'email_verification_required'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.neutralGrey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'email_verification_required_subtitle'.trParams({
                        'email': user.email ?? '',
                      }),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColor.neutralGrey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showInlineActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _refreshStatus(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColor.neutralGrey300),
                      foregroundColor: AppColor.neutralGrey700,
                    ),
                    child: Text('refresh'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _goToVerification(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('verify_now'.tr),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _refreshStatus(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
        // Trigger rebuild by calling setState equivalent
        // The StreamBuilder will automatically rebuild when auth state changes
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('refresh_failed'.tr),
            backgroundColor: AppColor.error,
          ),
        );
      }
    }
  }

  void _goToVerification() {
    Get.toNamed(Routes.emailVerificationView);
  }
}

/// Compact verification badge for AppBars or small spaces
class EmailVerificationBadge extends StatelessWidget {
  const EmailVerificationBadge({super.key});

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

        // Show unverified badge
        return GestureDetector(
          onTap: () => Get.toNamed(Routes.emailVerificationView),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColor.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'verify_email'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
