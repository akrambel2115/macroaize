import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/widgets/modern_card.dart';
import 'package:macroaize/shared/services/notification_preferences_service.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  late final NotificationPreferencesService _prefsService;

  @override
  void initState() {
    super.initState();
    _prefsService = Get.find<NotificationPreferencesService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('notification_settings'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealRemindersSection(context),
            _buildOtherNotificationsSection(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRemindersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'meal_reminders'.tr,
          Icons.restaurant_outlined,
        ),
        const SizedBox(height: 12),
        ModernCard(
          child: Column(
            children: [
              Obx(
                () => _buildSwitchTile(
                  context,
                  title: 'meal_reminders'.tr,
                  subtitle: 'meal_reminders_desc'.tr,
                  icon: Icons.restaurant_menu,
                  iconColor: AppColor.primaryGreen,
                  value: _prefsService.mealRemindersEnabled.value,
                  onChanged:
                      (value) => _prefsService.setMealRemindersEnabled(value),
                ),
              ),

              Obx(
                () =>
                    _prefsService.mealRemindersEnabled.value
                        ? Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildTimePicker(
                              context,
                              title: 'breakfast_time'.tr,
                              icon: Icons.wb_sunny_outlined,
                              iconColor: Colors.orange,
                              currentTime: _prefsService.breakfastTime.value,
                              onTimeChanged:
                                  (time) =>
                                      _prefsService.setBreakfastTime(time),
                            ),
                            const SizedBox(height: 16),
                            _buildTimePicker(
                              context,
                              title: 'lunch_time'.tr,
                              icon: Icons.wb_twilight_outlined,
                              iconColor: Colors.amber,
                              currentTime: _prefsService.lunchTime.value,
                              onTimeChanged:
                                  (time) => _prefsService.setLunchTime(time),
                            ),
                            const SizedBox(height: 16),
                            _buildTimePicker(
                              context,
                              title: 'dinner_time'.tr,
                              icon: Icons.nightlight_outlined,
                              iconColor: Colors.indigo,
                              currentTime: _prefsService.dinnerTime.value,
                              onTimeChanged:
                                  (time) => _prefsService.setDinnerTime(time),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtherNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'other_notifications'.tr,
          Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 12),
        ModernCard(
          child: Column(
            children: [
              Obx(
                () => _buildSwitchTile(
                  context,
                  title: 'streak_reminders'.tr,
                  subtitle: 'streak_reminders_desc'.tr,
                  icon: Icons.local_fire_department,
                  iconColor: Colors.deepOrange,
                  value: _prefsService.streakRemindersEnabled.value,
                  onChanged:
                      (value) => _prefsService.setStreakRemindersEnabled(value),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _buildSwitchTile(
                  context,
                  title: 'goal_notifications'.tr,
                  subtitle: 'goal_notifications_desc'.tr,
                  icon: Icons.flag,
                  iconColor: AppColor.accent,
                  value: _prefsService.goalRemindersEnabled.value,
                  onChanged:
                      (value) => _prefsService.setGoalRemindersEnabled(value),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _buildSwitchTile(
                  context,
                  title: 'weekly_summary'.tr,
                  subtitle: 'weekly_summary_desc'.tr,
                  icon: Icons.bar_chart,
                  iconColor: Colors.purple,
                  value: _prefsService.weeklyRemindersEnabled.value,
                  onChanged:
                      (value) => _prefsService.setWeeklyRemindersEnabled(value),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => _buildSwitchTile(
                  context,
                  title: 'weight_reminders'.tr,
                  subtitle: 'weight_reminders_desc'.tr,
                  icon: Icons.monitor_weight_outlined,
                  iconColor: Colors.teal,
                  value: _prefsService.weightRemindersEnabled.value,
                  onChanged:
                      (value) => _prefsService.setWeightRemindersEnabled(value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.theme.hintColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColor.primaryOrange,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String currentTime,
    required ValueChanged<String> onTimeChanged,
  }) {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 12;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) {
            return Theme(
              data: context.theme.copyWith(
                colorScheme: context.theme.colorScheme.copyWith(
                  primary: AppColor.primaryOrange,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final timeStr =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(timeStr);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.theme.hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTimeDisplay(hour, minute),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColor.primaryOrange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTimeDisplay(int hour, int minute) {
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
