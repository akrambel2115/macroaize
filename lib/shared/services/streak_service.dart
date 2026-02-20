import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../SharePrefHelper/share_pref.dart';
import '../../SharePrefHelper/share_pref_key.dart';
import '../../widgets/streak_notification_widget.dart';
import 'streak_widget_service.dart';

class StreakService {
  // singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();


  Future<int> getCurrentStreak() async {
    final int storedCount =
        await SharedPref.readInt(SharePrefKey.streakCount) ?? 0;
    final String lastDateStr = await SharedPref.readString(
      SharePrefKey.lastActiveDate,
    );

    if (storedCount == 0 || lastDateStr.isEmpty) {
      return 0;
    }

    final DateTime lastDate = DateTime.parse(lastDateStr);
    final DateTime today = DateTime.now();

    final DateTime lastDateMidnight = DateTime(
      lastDate.year,
      lastDate.month,
      lastDate.day,
    );
    final DateTime todayMidnight = DateTime(today.year, today.month, today.day);

    final int diff = todayMidnight.difference(lastDateMidnight).inDays;

    if (diff > 1) {
      // reset broken streak
      await SharedPref.saveInt(SharePrefKey.streakCount, 0);
      return 0;
    }

    return storedCount;
  }

  Future<int> recordActivity() async {
    final int currentStoredStreak =
        await SharedPref.readInt(SharePrefKey.streakCount) ?? 0;
    final String lastDateStr = await SharedPref.readString(
      SharePrefKey.lastActiveDate,
    );

    final DateTime now = DateTime.now();
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    int newStreak = 1;

    if (lastDateStr.isNotEmpty) {
      final DateTime lastDate = DateTime.parse(lastDateStr);
      final DateTime lastDateMidnight = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );

      final int diff = todayMidnight.difference(lastDateMidnight).inDays;

      if (diff == 0) {
        newStreak = currentStoredStreak;
      } else if (diff == 1) {
        newStreak = currentStoredStreak + 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await SharedPref.saveInt(SharePrefKey.streakCount, newStreak);
    await SharedPref.saveString(
      SharePrefKey.lastActiveDate,
      now.toIso8601String(),
    );

    List<String> history = await SharedPref.readList(
      SharePrefKey.streakHistory,
    );
    final String todayStr = DateFormat('yyyy-MM-dd').format(now);
    if (!history.contains(todayStr)) {
      history.add(todayStr);
      await SharedPref.saveList(SharePrefKey.streakHistory, history);
    }

    await _updateHomeWidget();

    return newStreak;
  }

  Future<List<Map<String, dynamic>>> getLast7DaysHistory() async {
    List<String> history = await SharedPref.readList(
      SharePrefKey.streakHistory,
    );

    if (history.isEmpty) {
      int currentStreak = await getCurrentStreak();
      if (currentStreak > 0) {}
    }

    List<Map<String, dynamic>> result = [];
    DateTime today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime day = today.subtract(Duration(days: i));
      String dayStr = DateFormat('yyyy-MM-dd').format(day);
      String dayLabel = DateFormat('E').format(day)[0];
      bool isActive = history.contains(dayStr);
      result.add({'day': dayLabel, 'isActive': isActive, 'date': day});
    }
    return result;
  }

  Future<void> checkAndShowNotification() async {
    final String lastShown = await SharedPref.readString(
      SharePrefKey.lastStreakShownDate,
    );
    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastShown != todayStr) {
      final int streak = await getCurrentStreak();
      final history = await getLast7DaysHistory();

      Get.showSnackbar(
        GetSnackBar(
          backgroundColor: Colors.transparent,
          messageText: StreakNotificationWidget(
            streakCount: streak,
            history: history,
          ),
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          animationDuration: const Duration(milliseconds: 500),
          overlayBlur: 0.0,
          margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
          borderRadius: 20,
          padding: EdgeInsets.zero,
          isDismissible: true,
        ),
      );

      await SharedPref.saveString(SharePrefKey.lastStreakShownDate, todayStr);
    }
  }

  Future<int> getMaxStreak() async {
    List<String> history = await SharedPref.readList(
      SharePrefKey.streakHistory,
    );
    if (history.isEmpty) return 0;

    List<DateTime> dates =
        history.map((e) => DateTime.parse(e)).toList()
          ..sort((a, b) => a.compareTo(b));

    int maxStreak = 0;
    int currentRun = 0;

    for (int i = 0; i < dates.length; i++) {
      if (i == 0) {
        currentRun = 1;
      } else {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          if (currentRun > maxStreak) maxStreak = currentRun;
          currentRun = 1;
        }
      }
    }
    if (currentRun > maxStreak) maxStreak = currentRun;

    return maxStreak;
  }

  Future<int> getTotalActiveDays() async {
    List<String> history = await SharedPref.readList(
      SharePrefKey.streakHistory,
    );
    return history.toSet().length;
  }

  Future<void> _updateHomeWidget() async {
    try {
      final int streak = await getCurrentStreak();
      List<String> history = await SharedPref.readList(
        SharePrefKey.streakHistory,
      );
      DateTime now = DateTime.now();
      DateTime earliest =
          history.isNotEmpty
              ? history
                  .map((e) => DateTime.parse(e))
                  .reduce((a, b) => a.isBefore(b) ? a : b)
              : now;

      int totalDays = now.difference(earliest).inDays + 1;
      if (totalDays < 1) totalDays = 1;
      int activeDays = history.toSet().length;
      double score = (activeDays / totalDays) * 100;
      if (score > 100) score = 100;

      final String todayStr = DateFormat('yyyy-MM-dd').format(now);
      bool isActive = history.contains(todayStr);

      await StreakWidgetService.updateWidget(
        streakCount: streak,
        disciplineScore: score,
        isActiveToday: isActive,
      );
    } catch (e) {
      debugPrint("StreakService: Error updating widget: $e");
    }
  }

  Future<void> syncWidget() async {
    await _updateHomeWidget();
  }
}
