import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:health/health.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';

class WellnessSyncService extends GetxService {
  final Health _health = Health();

  final RxBool isConnected = false.obs;
  final RxBool isAvailable = true.obs;
  final RxBool isBusy = false.obs;
  final RxString statusMessage = 'Not connected'.obs;

  static const _types = [HealthDataType.STEPS, HealthDataType.WORKOUT];
  static const _permissions = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];

  /// SharedPreferences key used to persist the connection flag on iOS,
  /// because HealthKit's hasPermissions always returns null.
  static const String _iosConnectedKey = 'wellness_connected_ios';

  String get providerDisplayName {
    if (kIsWeb) return 'Wellness';
    if (Platform.isIOS) return 'Apple Health';
    return 'Health Connect';
  }

  Future<WellnessSyncService> init() async {
    await _health.configure();
    await refreshStatus();
    return this;
  }

  Future<void> refreshStatus() async {
    try {
      if (kIsWeb) {
        isAvailable.value = false;
        isConnected.value = false;
        statusMessage.value = 'Not supported on web';
        return;
      }

      if (Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();
        isAvailable.value = available;
        if (!available) {
          isConnected.value = false;
          statusMessage.value = 'Health Connect not installed';
          return;
        }
        // Android: hasPermissions works reliably
        final granted = await _health.hasPermissions(
          _types,
          permissions: _permissions,
        );
        isConnected.value = granted ?? false;
      } else {
        // iOS: hasPermissions always returns null due to HealthKit privacy.
        // Trust the persisted flag immediately so the UI shows "Connected"
        // right away, then verify HealthKit access in the background.
        isAvailable.value = true;
        final savedFlag = await SharedPref.readBool(_iosConnectedKey) ?? false;
        if (savedFlag) {
          isConnected.value = true;
          statusMessage.value = 'Connected';
          // Verify asynchronously — if the user revoked permission in iOS
          // Settings, this will clear the flag after a short grace period.
          _verifyIosPermissionInBackground();
          return; // skip the statusMessage assignment below
        } else {
          isConnected.value = false;
        }
      }

      statusMessage.value = isConnected.value ? 'Connected' : 'Not connected';
    } catch (_) {
      isConnected.value = false;
      statusMessage.value = 'Permission unavailable';
    }
  }

  /// Verify HealthKit access in the background with retries.
  ///
  /// On cold start HealthKit may not be fully ready immediately after
  /// [Health.configure], so we give it a few seconds before attempting a
  /// lightweight step read.  Only if *all* attempts fail do we clear the
  /// persisted flag (the user likely revoked permission in iOS Settings).
  Future<void> _verifyIosPermissionInBackground() async {
    const retries = 3;
    const delays = [Duration(seconds: 2), Duration(seconds: 3), Duration(seconds: 5)];
    for (var i = 0; i < retries; i++) {
      await Future.delayed(delays[i]);
      if (await _verifyIosPermission()) return; // still valid
    }
    // All retries exhausted — permission was likely revoked.
    isConnected.value = false;
    statusMessage.value = 'Not connected';
    await SharedPref.saveBool(_iosConnectedKey, false);
  }

  /// Attempt a lightweight HealthKit read to verify permission is still granted.
  Future<bool> _verifyIosPermission() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      // getTotalStepsInInterval returns null when no data, but does NOT throw
      // when permission is granted. It throws or returns null when revoked.
      await _health.getTotalStepsInInterval(start, now);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect() async {
    if (isBusy.value) return false;
    isBusy.value = true;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          await _health.installHealthConnect();
          isAvailable.value = false;
          statusMessage.value = 'Install Health Connect then try again';
          return false;
        }
      }

      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      isConnected.value = granted;
      statusMessage.value = granted ? 'Connected' : 'Permission denied';

      if (granted) {
        // Persist the flag on iOS so we remember across app restarts.
        if (!kIsWeb && Platform.isIOS) {
          await SharedPref.saveBool(_iosConnectedKey, true);
        }
        if (!kIsWeb && Platform.isAndroid) {
          await _requestOptionalAndroidHistoryAccess();
        }
      }

      return granted;
    } catch (_) {
      statusMessage.value = 'Connection failed';
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> disconnect() async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      await _health.revokePermissions();
      isConnected.value = false;
      statusMessage.value = 'Disconnected';
      // Clear the persisted iOS flag.
      if (!kIsWeb && Platform.isIOS) {
        await SharedPref.saveBool(_iosConnectedKey, false);
      }
    } catch (_) {
      statusMessage.value = 'Failed to disconnect';
    } finally {
      isBusy.value = false;
    }
  }

  Future<int?> getTodayStepsTotal() async {
    return getTotalStepsForDate(DateTime.now());
  }

  Future<int?> getTotalStepsForDate(DateTime date) async {
    if (!isConnected.value || kIsWeb) return null;
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end =
          _isSameDate(date, DateTime.now())
              ? DateTime.now()
              : start.add(const Duration(days: 1));
      final steps = await _health.getTotalStepsInInterval(start, end);
      if (steps == null || steps < 0) return null;
      return steps;
    } catch (_) {
      return null;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _requestOptionalAndroidHistoryAccess() async {
    try {
      final hasHistory = await _health.isHealthDataHistoryAuthorized();
      if (!hasHistory) {
        await _health.requestHealthDataHistoryAuthorization();
      }
    } catch (_) {}

    try {
      final bgAvailable = await _health.isHealthDataInBackgroundAvailable();
      if (!bgAvailable) return;
      final hasBg = await _health.isHealthDataInBackgroundAuthorized();
      if (!hasBg) {
        await _health.requestHealthDataInBackgroundAuthorization();
      }
    } catch (_) {}
  }

  Future<void> syncWorkout({
    required int workoutId,
    required DateTime date,
    required int durationMinutes,
    required int caloriesBurned,
    required String workoutType,
  }) async {
    if (!isConnected.value || durationMinutes <= 0) return;
    final dedupeKey = 'wellness_workout_synced_$workoutId';
    final alreadySynced = await SharedPref.readBool(dedupeKey) ?? false;
    if (alreadySynced) return;

    try {
      final start = date;
      final end = start.add(Duration(minutes: durationMinutes));
      final success = await _health.writeWorkoutData(
        activityType: _mapWorkoutType(workoutType),
        start: start,
        end: end,
        totalEnergyBurned: caloriesBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        title: workoutType,
        recordingMethod: RecordingMethod.automatic,
      );

      if (success) {
        await SharedPref.saveBool(dedupeKey, true);
      }
    } catch (_) {
      // Silent by design (workout save must never fail because sync failed)
    }
  }

  HealthWorkoutActivityType _mapWorkoutType(String type) {
    final t = type.toLowerCase();
    if (t.contains('run')) return HealthWorkoutActivityType.RUNNING;
    if (t.contains('walk')) return HealthWorkoutActivityType.WALKING;
    if (t.contains('cycle') || t.contains('bike')) {
      return HealthWorkoutActivityType.BIKING;
    }
    if (t.contains('swim')) return HealthWorkoutActivityType.SWIMMING;
    if (t.contains('yoga')) return HealthWorkoutActivityType.YOGA;
    if (t.contains('hiit')) {
      return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
    }
    if (t.contains('strength') || t.contains('weight')) {
      return HealthWorkoutActivityType.STRENGTH_TRAINING;
    }
    return HealthWorkoutActivityType.OTHER;
  }
}
