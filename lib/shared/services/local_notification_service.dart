import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'remote_config_service.dart';
import 'notification_preferences_service.dart';

// local alerts only
class LocalNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final RxBool _isInitialized = false.obs;
  static const int _idGoalProgress = 6001;

  /// Water reminder IDs: 7001–7008 (one per time‑slot).
  static const int _idWaterBase = 7001;
  static const int _waterSlotCount = 8; // 8am,10am,12pm,2pm,4pm,6pm,8pm,10pm

  bool get isInitialized => _isInitialized.value;

  Future<LocalNotificationService> init() async {
    try {
      // Initialize timezone data for scheduled notifications
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: !Platform.isIOS,
        requestBadgePermission: !Platform.isIOS,
        requestSoundPermission: !Platform.isIOS,
      );
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      if (Platform.isAndroid) {
        final androidPlugin =
            _notifications
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        // request notification permission
        await androidPlugin?.requestNotificationsPermission();
      }

      _isInitialized.value = true;
    } catch (e) {
      if (kDebugMode) debugPrint('LocalNotificationService init error: $e');
    }
    return this;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      if (Get.currentRoute != Routes.leadingView) {
        Get.offAllNamed(Routes.leadingView);
      }
    }
  }

  NotificationDetails _getNotificationDetails({
    String channelId = 'calai_notifications',
    String channelName = 'macroAize Notifications',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showGoalProgress(int percent) async {
    if (!_isInitialized.value) return;

    final prefsService =
        Get.isRegistered<NotificationPreferencesService>()
            ? Get.find<NotificationPreferencesService>()
            : null;

    if (prefsService != null && !prefsService.goalRemindersEnabled.value) {
      return;
    }

    final configService =
        Get.isRegistered<RemoteConfigService>()
            ? Get.find<RemoteConfigService>()
            : null;

    String title;
    String body;

    if (percent >= 100) {
      title = 'Goal Achieved! ';
      body =
          configService?.goal100pctMsg ??
          'Amazing! You\'ve reached your daily calorie goal!';
    } else if (percent >= 50) {
      title = 'Halfway There! 🎯';
      body =
          configService?.formatMessage(configService.goal50pctMsg, {
            'percent': percent.toString(),
          }) ??
          'You\'ve logged $percent% of your daily goal. Keep going!';
    } else {
      return;
    }

    await _notifications.show(
      id: _idGoalProgress,
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails(
        channelId: 'calai_goals',
        channelName: 'Goal Progress',
      ),
      payload: 'goal_progress',
    );
  }

  // ─── Water drink reminders ───────────────────────────────────────────

  /// Schedules daily water reminders every [intervalHours] hours
  /// from 8 AM to 10 PM (local time).
  /// Previously scheduled water notifications are cancelled first.
  Future<void> scheduleWaterReminders() async {
    if (!_isInitialized.value) return;

    final prefsService =
        Get.isRegistered<NotificationPreferencesService>()
            ? Get.find<NotificationPreferencesService>()
            : null;

    if (prefsService != null && !prefsService.waterRemindersEnabled.value) {
      await cancelWaterReminders();
      return;
    }

    final configService =
        Get.isRegistered<RemoteConfigService>()
            ? Get.find<RemoteConfigService>()
            : null;

    final int intervalHours = configService?.waterIntervalHours ?? 2;
    final String message =
        configService?.waterMsg ?? '💧 Stay hydrated! Drink a glass of water.';

    // Cancel any existing water reminders before rescheduling
    await cancelWaterReminders();

    final now = tz.TZDateTime.now(tz.local);
    const int startHour = 8;
    const int endHour = 22; // 10 PM

    int slot = 0;
    for (int hour = startHour;
        hour <= endHour && slot < _waterSlotCount;
        hour += intervalHours) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
      );

      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notifications.zonedSchedule(
          id: _idWaterBase + slot,
          title: 'Water Reminder 💧',
          body: message,
          scheduledDate: scheduledDate,
          notificationDetails: _getNotificationDetails(
            channelId: 'calai_water',
            channelName: 'Water Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'water_reminder',
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to schedule water reminder slot $slot: $e');
        }
      }
      slot++;
    }

    if (kDebugMode) {
      debugPrint('Scheduled $slot water reminders every ${intervalHours}h');
    }
  }

  /// Cancels all scheduled water reminder notifications.
  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < _waterSlotCount; i++) {
      await _notifications.cancel(id: _idWaterBase + i);
    }
  }
}
