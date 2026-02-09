import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService extends GetxService {
  static const String _logTag = 'NotificationPreferencesService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _keyNotificationsEnabled = 'notif_pref_enabled';
  static const String _keyMealRemindersEnabled = 'notif_pref_meal_enabled';
  static const String _keyStreakRemindersEnabled = 'notif_pref_streak_enabled';
  static const String _keyWeeklyRemindersEnabled = 'notif_pref_weekly_enabled';
  static const String _keyWeightRemindersEnabled = 'notif_pref_weight_enabled';
  static const String _keyGoalRemindersEnabled = 'notif_pref_goal_enabled';

  static const String _keyBreakfastTime = 'notif_pref_breakfast_time';
  static const String _keyLunchTime = 'notif_pref_lunch_time';
  static const String _keyDinnerTime = 'notif_pref_dinner_time';

  final RxBool _isInitialized = false.obs;

  final RxBool notificationsEnabled = true.obs;
  final RxBool mealRemindersEnabled = true.obs;
  final RxBool streakRemindersEnabled = true.obs;
  final RxBool weeklyRemindersEnabled = true.obs;
  final RxBool weightRemindersEnabled = true.obs;
  final RxBool goalRemindersEnabled = true.obs;

  final RxString breakfastTime = '08:00'.obs;
  final RxString lunchTime = '12:00'.obs;
  final RxString dinnerTime = '19:00'.obs;

  bool get isInitialized => _isInitialized.value;

  Future<NotificationPreferencesService> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      notificationsEnabled.value =
          prefs.getBool(_keyNotificationsEnabled) ?? true;
      mealRemindersEnabled.value =
          prefs.getBool(_keyMealRemindersEnabled) ?? true;
      streakRemindersEnabled.value =
          prefs.getBool(_keyStreakRemindersEnabled) ?? true;
      weeklyRemindersEnabled.value =
          prefs.getBool(_keyWeeklyRemindersEnabled) ?? true;
      weightRemindersEnabled.value =
          prefs.getBool(_keyWeightRemindersEnabled) ?? true;
      goalRemindersEnabled.value =
          prefs.getBool(_keyGoalRemindersEnabled) ?? true;

      breakfastTime.value = prefs.getString(_keyBreakfastTime) ?? '08:00';
      lunchTime.value = prefs.getString(_keyLunchTime) ?? '12:00';
      dinnerTime.value = prefs.getString(_keyDinnerTime) ?? '19:00';

      _isInitialized.value = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error loading preferences: $e');
      }
      _isInitialized.value = true;
    }

    return this;
  }

  // local storage logic

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setMealRemindersEnabled(bool value) async {
    mealRemindersEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMealRemindersEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setStreakRemindersEnabled(bool value) async {
    streakRemindersEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakRemindersEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setWeeklyRemindersEnabled(bool value) async {
    weeklyRemindersEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyRemindersEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setWeightRemindersEnabled(bool value) async {
    weightRemindersEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightRemindersEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setGoalRemindersEnabled(bool value) async {
    goalRemindersEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGoalRemindersEnabled, value);
    await _syncToFirestore();
  }

  Future<void> setBreakfastTime(String time) async {
    breakfastTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBreakfastTime, time);
    await _syncToFirestore();
  }

  Future<void> setLunchTime(String time) async {
    lunchTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLunchTime, time);
    await _syncToFirestore();
  }

  Future<void> setDinnerTime(String time) async {
    dinnerTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDinnerTime, time);
    await _syncToFirestore();
  }

  // cloud sync logic

  Future<void> _syncToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[$_logTag] No user logged in, skipping Firestore sync');
        }
        return;
      }

      final breakfast = parseTime(breakfastTime.value);
      final lunch = parseTime(lunchTime.value);
      final dinner = parseTime(dinnerTime.value);

      final prefsData = {
        'enabled': notificationsEnabled.value,
        'mealReminders': mealRemindersEnabled.value,
        'streakReminders': streakRemindersEnabled.value,
        'weeklyReminders': weeklyRemindersEnabled.value,
        'weightReminders': weightRemindersEnabled.value,
        'goalReminders': goalRemindersEnabled.value,
        'breakfastHour': breakfast.hour,
        'lunchHour': lunch.hour,
        'dinnerHour': dinner.hour,
        'timezone': _getIanaTimezone(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set({
        'notificationPrefs': prefsData,
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('[$_logTag] Synced preferences to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error syncing to Firestore: $e');
      }
    }
  }

  String _getIanaTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;

      // common offset mapping
      if (hours == 1) return 'Africa/Algiers';
      if (hours == 0) return 'UTC';
      if (hours == -5) return 'America/New_York';
      if (hours == -8) return 'America/Los_Angeles';
      if (hours == 2) return 'Europe/Paris';
      if (hours == 3) return 'Europe/Moscow';
      if (hours == 5 || hours == 6) return 'Asia/Kolkata';
      if (hours == 8) return 'Asia/Shanghai';
      if (hours == 9) return 'Asia/Tokyo';

      return 'Africa/Algiers';
    } catch (e) {
      return 'Africa/Algiers';
    }
  }

  Future<void> syncOnLogin() async {
    await _syncToFirestore();
  }

  ({int hour, int minute}) parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return (
      hour: int.tryParse(parts[0]) ?? 12,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
