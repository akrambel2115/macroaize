import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class RemoteConfigService extends GetxService {
  static const String _logTag = 'RemoteConfigService';

  late final FirebaseRemoteConfig _remoteConfig;
  final RxBool _isInitialized = false.obs;

  bool get isInitialized => _isInitialized.value;

  static const Map<String, dynamic> _defaults = {
    'notifications_enabled': true,

    'notification_breakfast_time': '08:00',
    'notification_lunch_time': '12:00',
    'notification_dinner_time': '19:00',
    'notification_water_interval_hours': 2,
    'notification_daily_reset_time': '00:05',
    'notification_weekly_summary_day': 0,
    'notification_weekly_summary_time': '20:00',
    'notification_weight_reminder_day': 0,
    'notification_weight_reminder_time': '09:00',

    'notification_breakfast_msg':
        '🌅 Good morning! Start your day right by logging your breakfast.',
    'notification_lunch_msg': '🍽️ Lunchtime! Don\'t forget to log your meal.',
    'notification_dinner_msg':
        '🌙 Evening reminder: Log your dinner before the day ends.',
    'notification_water_msg':
        '💧 Stay hydrated! Have you had your water today?',
    'notification_streak_msg':
        '🔥 Your {streak} day streak is at risk! Log a meal now.',
    'notification_goal_50pct_msg':
        '🎯 Halfway there! You\'ve logged {percent}% of your daily goal.',
    'notification_goal_100pct_msg':
        ' Amazing! You\'ve reached your daily calorie goal!',
    'notification_daily_reset_msg':
        '🌅 A new day begins! Your daily counters have been reset.',
    'notification_end_of_day_msg':
        '📊 Day complete! Check your summary before midnight.',
    'notification_weekly_summary_msg':
        '📈 Weekly summary ready! See your progress this week.',
    'notification_weight_reminder_msg':
        '⚖️ Weekly reminder: Update your weight to track progress!',
  };

  Future<RemoteConfigService> init() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode
                  ? const Duration(minutes: 5)
                  : const Duration(hours: 12),
        ),
      );

      await _remoteConfig.setDefaults(
        _defaults.map((key, value) => MapEntry(key, value.toString())),
      );

      await _fetchAndActivate();

      _isInitialized.value = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error initializing Remote Config: $e');
        debugPrint('[$_logTag] Using default values');
      }
      // fallback to defaults
      _isInitialized.value = true;
    }

    return this;
  }

  Future<bool> _fetchAndActivate() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        debugPrint('[$_logTag] Config fetched and activated: $activated');
      }
      return activated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error fetching config: $e');
      }
      return false;
    }
  }

  Future<void> refresh() async {
    await _fetchAndActivate();
  }

  bool get notificationsEnabled =>
      _remoteConfig.getBool('notifications_enabled');

  String get breakfastTime =>
      _remoteConfig.getString('notification_breakfast_time');
  String get lunchTime => _remoteConfig.getString('notification_lunch_time');
  String get dinnerTime => _remoteConfig.getString('notification_dinner_time');
  int get waterIntervalHours =>
      _remoteConfig.getInt('notification_water_interval_hours');
  String get dailyResetTime =>
      _remoteConfig.getString('notification_daily_reset_time');
  int get weeklySummaryDay =>
      _remoteConfig.getInt('notification_weekly_summary_day');
  String get weeklySummaryTime =>
      _remoteConfig.getString('notification_weekly_summary_time');
  int get weightReminderDay =>
      _remoteConfig.getInt('notification_weight_reminder_day');
  String get weightReminderTime =>
      _remoteConfig.getString('notification_weight_reminder_time');

  String get breakfastMsg =>
      _remoteConfig.getString('notification_breakfast_msg');
  String get lunchMsg => _remoteConfig.getString('notification_lunch_msg');
  String get dinnerMsg => _remoteConfig.getString('notification_dinner_msg');
  String get waterMsg => _remoteConfig.getString('notification_water_msg');
  String get streakMsg => _remoteConfig.getString('notification_streak_msg');
  String get goal50pctMsg =>
      _remoteConfig.getString('notification_goal_50pct_msg');
  String get goal100pctMsg =>
      _remoteConfig.getString('notification_goal_100pct_msg');
  String get dailyResetMsg =>
      _remoteConfig.getString('notification_daily_reset_msg');
  String get endOfDayMsg =>
      _remoteConfig.getString('notification_end_of_day_msg');
  String get weeklySummaryMsg =>
      _remoteConfig.getString('notification_weekly_summary_msg');
  String get weightReminderMsg =>
      _remoteConfig.getString('notification_weight_reminder_msg');

  ({int hour, int minute}) parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return (
      hour: int.tryParse(parts[0]) ?? 12,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String formatMessage(String message, Map<String, String> params) {
    var result = message;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
