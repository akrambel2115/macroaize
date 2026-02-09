import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'remote_config_service.dart';
import 'notification_preferences_service.dart';

// local alerts only
class LocalNotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final RxBool _isInitialized = false.obs;
  static const int _idGoalProgress = 6001;

  bool get isInitialized => _isInitialized.value;

  Future<LocalNotificationService> init() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
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
      Get.toNamed('/home');
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

    if (prefsService != null && !prefsService.goalRemindersEnabled.value)
      return;

    final configService =
        Get.isRegistered<RemoteConfigService>()
            ? Get.find<RemoteConfigService>()
            : null;

    String title;
    String body;

    if (percent >= 100) {
      title = 'Goal Achieved! 🎉';
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
}
