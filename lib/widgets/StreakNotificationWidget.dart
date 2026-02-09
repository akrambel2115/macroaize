import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';
import '../constant/AppAssets.dart';

class StreakNotificationWidget extends StatelessWidget {
  final int streakCount;
  final List<Map<String, dynamic>> history;

  const StreakNotificationWidget({
    super.key,
    required this.streakCount,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Row(
                  children: [
                    Text(
                      "$streakCount",
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryOrange,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'streak_title'.tr,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primaryOrange,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Days Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      history.map((dayData) {
                        final String label = dayData['day'];
                        final bool isActive = dayData['isActive'];

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColor.darkTextSecondary
                                        : AppColor.neutralGrey800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isActive
                                        ? AppColor.primaryOrange
                                        : (isDark
                                            ? AppColor.darkBorder
                                            : AppColor.neutralGrey300),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Icon (Fire)
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [Image.asset(AppAssets.fireIcon, fit: BoxFit.contain)],
            ),
          ),
        ],
      ),
    );
  }
}
