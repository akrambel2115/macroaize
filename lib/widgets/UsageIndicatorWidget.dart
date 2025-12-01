import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/shared/models/user_usage.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'package:foodcalorietracker/shared/services/subscription_service.dart';

class UsageIndicatorWidget extends StatelessWidget {
  final bool showOnlyWhenLimited;

  const UsageIndicatorWidget({super.key, this.showOnlyWhenLimited = false});

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService();
    final usageService = UsageService();

    return StreamBuilder<Subscription?>(
      stream: subscriptionService.subscriptionStream,
      builder: (context, subscriptionSnapshot) {
        final subscription = subscriptionSnapshot.data;

        if (subscription?.isActive == true && showOnlyWhenLimited) {
          return const SizedBox.shrink();
        }
        if (subscription?.isActive == true) {
          return _buildPremiumBadge(context);
        }
        return StreamBuilder<UserUsage?>(
          stream: usageService.usageStream,
          builder: (context, usageSnapshot) {
            final usage =
                usageSnapshot.data ??
                const UserUsage(scanCount: 0, chatCount: 0);
            return _buildUsageDisplay(context, usage);
          },
        );
      },
    );
  }

  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColor.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            'Premium',
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageDisplay(BuildContext context, UserUsage usage) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColor.neutralGrey200.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColor.primaryOrange, size: 16),
              const SizedBox(width: 8),
              Text(
                'Daily Usage',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap:
                    () => Get.toNamed('/premiumView'), // Adjust route as needed
                child: Text(
                  'Go Premium',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColor.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUsageItem(
                  context,
                  icon: Icons.photo_camera_outlined,
                  label: 'Scans',
                  current: usage.scanCount,
                  total: usage.scanLimit,
                  color: AppColor.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUsageItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  current: usage.chatCount,
                  total: usage.chatLimit,
                  color: AppColor.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int total,
    required Color color,
  }) {
    final remaining = (total - current).clamp(0, total);
    final isLimitReached = current >= total;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isLimitReached ? Colors.grey : color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: isLimitReached ? Colors.grey : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey.withOpacity(0.2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress =
                  total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * progress,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isLimitReached ? Colors.red : color,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$remaining left',
          style: context.textTheme.labelSmall?.copyWith(
            color:
                isLimitReached
                    ? Colors.red
                    : remaining <= 1
                    ? Colors.orange
                    : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
