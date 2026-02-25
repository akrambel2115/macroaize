import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constant/app_color.dart';
import 'daily_streak_controller.dart';

class DailyStreakView extends GetView<DailyStreakController> {
  const DailyStreakView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.neutralGrey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Streak & Discipline",
              style: context.theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(context),
                    const SizedBox(height: 24),
                    Text(
                      "Activity History",
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHeatmap(context),
                    const SizedBox(height: 8),
                    _buildLegend(context),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    bool hasStreak = controller.currentStreak.value > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    hasStreak
                        ? Image.asset(
                          'assets/icons/fire.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        )
                        : Image.asset(
                          'assets/icons/fire.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          color: AppColor.neutralGrey400,
                        ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasStreak
                              ? "${controller.currentStreak.value}"
                              : "Start",
                          style: context.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                hasStreak
                                    ? AppColor.primaryOrange
                                    : AppColor.neutralGrey400,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          hasStreak ? "Day Streak" : "Your Streak",
                          style: context.textTheme.labelMedium?.copyWith(
                            color: AppColor.neutralGrey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final now = DateTime.now();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            List.generate(12, (index) {
              DateTime monthDate = DateTime(now.year, now.month - index, 1);
              int daysInMonth =
                  DateTime(monthDate.year, monthDate.month + 1, 0).day;

              return Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(monthDate),
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.neutralGrey600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: 7 * 22.0,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // calendar grid padding
                          ...List.generate(
                            (monthDate.weekday == 7 ? 0 : monthDate.weekday),
                            (_) => const SizedBox(width: 16, height: 16),
                          ),

                          ...List.generate(daysInMonth, (dayIndex) {
                            DateTime dayDate = DateTime(
                              monthDate.year,
                              monthDate.month,
                              dayIndex + 1,
                            );
                            String dateStr = DateFormat(
                              'yyyy-MM-dd',
                            ).format(dayDate);
                            bool isActive = controller.historyDates.contains(
                              dateStr,
                            );
                            bool isFuture = dayDate.isAfter(now);

                            if (isFuture) {
                              return Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color:
                                      context.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : AppColor.neutralGrey100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            }

                            return Tooltip(
                              message: "$dateStr${isActive ? ': Active' : ''}",
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient:
                                      isActive
                                          ? const LinearGradient(
                                            colors: [
                                              AppColor.primaryOrange,
                                              Colors.deepOrange,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                          : null,
                                  color:
                                      isActive
                                          ? null
                                          : (context.isDarkMode
                                              ? AppColor.darkBorder
                                              : AppColor.neutralGrey200),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).reversed.toList(),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Less", style: context.textTheme.bodySmall),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? AppColor.darkBorder
                    : AppColor.neutralGrey200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColor.primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text("More", style: context.textTheme.bodySmall),
      ],
    );
  }
}
