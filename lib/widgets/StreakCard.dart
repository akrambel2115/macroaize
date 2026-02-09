import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';
import 'ModernCard.dart';

class StreakCard extends StatelessWidget {
  final int streakCount;
  final VoidCallback? onTap;

  const StreakCard({super.key, required this.streakCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Fire Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColor.primaryOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "$streakCount",
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'streak_title'.tr, // "Day Streak"
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'streak_subtitle'.tr, // "Keep the momentum!"
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColor.neutralGrey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
