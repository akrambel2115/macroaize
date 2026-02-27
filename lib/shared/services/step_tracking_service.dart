import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/shared/services/wellness_sync_service.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackingService extends GetxService with WidgetsBindingObserver {
  final RxInt dailySteps = 0.obs;
  final RxInt stepCaloriesBurned = 0.obs;
  final RxBool isTrackingAvailable = false.obs;

  StreamSubscription<StepCount>? _stepSub;

  DateTime _activeDate = _dateOnly(DateTime.now());
  int _baselineRawSteps = 0;
  bool _baselineInitialized = false;
  int _latestRawSteps = 0;
  int _resetOffsetSteps = 0;

  bool _started = false;
  DateTime? _lastWellnessReconcileAt;

  /// Debounce timer so we don't write to SharedPreferences on every single
  /// step event (can be hundreds per minute while actively walking).
  Timer? _persistDebounce;
  static const Duration _persistDelay = Duration(seconds: 3);

  static const Duration _wellnessReconcileInterval = Duration(minutes: 2);

  /// ~0.7 kcal/kg/km is the accepted average for walking.
  /// Running is ~1.0; 0.7 avoids over-estimating for typical step tracking.
  static const double _caloriesPerKgPerKm = 0.7;

  Future<StepTrackingService> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _loadPersistedStateForDate(_activeDate);
    await _ensureTracking();
    await _reconcileFromWellness(force: true);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSub?.cancel();
    _persistDebounce?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumeSync();
    }
  }

  Future<void> _onResumeSync() async {
    await _rolloverIfNeeded();
    await _ensureTracking();
    await _reconcileFromWellness(force: true);
  }

  Future<void> _ensureTracking() async {
    if (kIsWeb) {
      isTrackingAvailable.value = false;
      return;
    }

    var permission = await Permission.activityRecognition.status;
    if (!permission.isGranted &&
        !permission.isLimited &&
        !permission.isRestricted) {
      permission = await Permission.activityRecognition.request();
    }

    // isRestricted on iOS means parental controls block the permission;
    // the user cannot grant it, so it must NOT be treated as "granted".
    final granted = permission.isGranted || permission.isLimited;
    isTrackingAvailable.value = granted;

    if (!granted) {
      await _stepSub?.cancel();
      _stepSub = null;
      _started = false;
      return;
    }

    if (_started) {
      return;
    }

    _started = true;
    _stepSub = Pedometer.stepCountStream.listen(
      _onStepEvent,
      onError: (_) {
        isTrackingAvailable.value = false;
        _started = false;
      },
      cancelOnError: false,
    );
  }

  Future<void> _onStepEvent(StepCount event) async {
    await _rolloverIfNeeded();

    final rawSteps = event.steps;

    if (_latestRawSteps > 0 && rawSteps < _latestRawSteps) {
      _resetOffsetSteps += (_latestRawSteps - rawSteps);
    }

    _latestRawSteps = rawSteps;
    final adjustedRaw = rawSteps + _resetOffsetSteps;

    if (!_baselineInitialized) {
      _baselineRawSteps = adjustedRaw;
      _baselineInitialized = true;
    }

    final computedSteps = math.max(0, adjustedRaw - _baselineRawSteps);
    final computedCalories = _estimateStepCalories(computedSteps);

    if (computedSteps != dailySteps.value ||
        computedCalories != stepCaloriesBurned.value) {
      dailySteps.value = computedSteps;
      stepCaloriesBurned.value = computedCalories;
      _schedulePersist();

      unawaited(_reconcileFromWellness());
    }
  }

  Future<void> _rolloverIfNeeded() async {
    final nowDate = _dateOnly(DateTime.now());
    if (_isSameDate(nowDate, _activeDate)) {
      return;
    }

    await _persistActiveDateState();

    _activeDate = nowDate;
    _baselineRawSteps = 0;
    _baselineInitialized = false;
    _latestRawSteps = 0;
    _resetOffsetSteps = 0;
    dailySteps.value = 0;
    stepCaloriesBurned.value = 0;

    await _loadPersistedStateForDate(_activeDate);
    await _reconcileFromWellness(force: true);
  }

  Future<void> _loadPersistedStateForDate(DateTime date) async {
    final storedSteps = await SharedPref.readInt(_stepsKey(date)) ?? 0;
    final storedStepCalories = await SharedPref.readInt(_stepCaloriesKey(date));
    final storedBaseline = await SharedPref.readInt(_baselineKey(date)) ?? 0;
    final storedLatest = await SharedPref.readInt(_latestRawKey(date)) ?? 0;
    final storedOffset = await SharedPref.readInt(_offsetKey(date)) ?? 0;

    dailySteps.value = storedSteps;
    stepCaloriesBurned.value =
        storedStepCalories ?? _estimateStepCalories(storedSteps);

    _baselineRawSteps = storedBaseline;
    _baselineInitialized = storedBaseline != 0 || storedSteps > 0;
    _latestRawSteps = storedLatest;
    _resetOffsetSteps = storedOffset;
  }

  Future<void> _persistActiveDateState() async {
    await SharedPref.saveInt(_stepsKey(_activeDate), dailySteps.value);
    await SharedPref.saveInt(
      _stepCaloriesKey(_activeDate),
      stepCaloriesBurned.value,
    );
    await SharedPref.saveInt(_baselineKey(_activeDate), _baselineRawSteps);
    await SharedPref.saveInt(_latestRawKey(_activeDate), _latestRawSteps);
    await SharedPref.saveInt(_offsetKey(_activeDate), _resetOffsetSteps);
  }

  Future<void> _persistDateTotals(
    DateTime date, {
    required int steps,
    required int calories,
  }) async {
    await SharedPref.saveInt(_stepsKey(date), steps);
    await SharedPref.saveInt(_stepCaloriesKey(date), calories);
  }

  Future<void> _reconcileFromWellness({bool force = false}) async {
    if (!Get.isRegistered<WellnessSyncService>()) return;

    final now = DateTime.now();
    if (!force && _lastWellnessReconcileAt != null) {
      final elapsed = now.difference(_lastWellnessReconcileAt!);
      if (elapsed < _wellnessReconcileInterval) {
        return;
      }
    }

    final wellness = Get.find<WellnessSyncService>();
    if (!wellness.isConnected.value) return;

    final syncedSteps = await wellness.getTotalStepsForDate(_activeDate);
    _lastWellnessReconcileAt = DateTime.now();
    if (syncedSteps == null || syncedSteps < 0) return;

    // Never let wellness decrease the visible step count — wellness data
    // can lag behind the real-time pedometer.
    final bestSteps = math.max(dailySteps.value, syncedSteps);
    final bestCalories = _estimateStepCalories(bestSteps);
    final changed =
        bestSteps != dailySteps.value ||
        bestCalories != stepCaloriesBurned.value;

    if (!changed && !force) return;

    dailySteps.value = bestSteps;
    stepCaloriesBurned.value = bestCalories;

    if (_latestRawSteps > 0 && _isSameDate(_activeDate, DateTime.now())) {
      final adjustedRaw = _latestRawSteps + _resetOffsetSteps;
      final newBaseline = math.max(0, adjustedRaw - bestSteps);
      _baselineRawSteps = newBaseline;
      _baselineInitialized = true;
    }

    await _persistActiveDateState();
  }

  Future<int> getDailyStepsForDate(DateTime date) async {
    if (_isSameDate(date, _activeDate)) {
      return dailySteps.value;
    }

    if (Get.isRegistered<WellnessSyncService>()) {
      final wellness = Get.find<WellnessSyncService>();
      if (wellness.isConnected.value) {
        final syncedSteps = await wellness.getTotalStepsForDate(date);
        if (syncedSteps != null && syncedSteps >= 0) {
          final calories = _estimateStepCalories(syncedSteps);
          await _persistDateTotals(
            date,
            steps: syncedSteps,
            calories: calories,
          );
          return syncedSteps;
        }
      }
    }

    return await SharedPref.readInt(_stepsKey(date)) ?? 0;
  }

  Future<int> getStepCaloriesForDate(DateTime date) async {
    if (_isSameDate(date, _activeDate)) {
      return stepCaloriesBurned.value;
    }

    if (Get.isRegistered<WellnessSyncService>()) {
      final wellness = Get.find<WellnessSyncService>();
      if (wellness.isConnected.value) {
        final syncedSteps = await wellness.getTotalStepsForDate(date);
        if (syncedSteps != null && syncedSteps >= 0) {
          final calories = _estimateStepCalories(syncedSteps);
          await _persistDateTotals(
            date,
            steps: syncedSteps,
            calories: calories,
          );
          return calories;
        }
      }
    }

    final storedCalories = await SharedPref.readInt(_stepCaloriesKey(date));
    if (storedCalories != null) {
      return storedCalories;
    }

    final steps = await SharedPref.readInt(_stepsKey(date)) ?? 0;
    return _estimateStepCalories(steps);
  }

  int _estimateStepCalories(int steps) {
    if (steps <= 0) return 0;

    final weightKg =
        ConstantUserMaster.weight > 0 ? ConstantUserMaster.weight : 70;
    final heightCm =
        ConstantUserMaster.height > 0 ? ConstantUserMaster.height : 170;
    final strideMeters = math.max(0.45, (heightCm / 100.0) * 0.415);
    final distanceKm = (steps * strideMeters) / 1000.0;
    final calories = distanceKm * weightKg * _caloriesPerKgPerKm;
    return calories.round();
  }

  /// Schedules a debounced write so rapid step events don't thrash storage.
  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(_persistDelay, () {
      _persistActiveDateState();
    });
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String _stepsKey(DateTime date) => 'steps_daily_${_dateKey(date)}';
  static String _stepCaloriesKey(DateTime date) =>
      'steps_calories_daily_${_dateKey(date)}';
  static String _baselineKey(DateTime date) =>
      'steps_baseline_raw_${_dateKey(date)}';
  static String _latestRawKey(DateTime date) =>
      'steps_latest_raw_${_dateKey(date)}';
  static String _offsetKey(DateTime date) =>
      'steps_reset_offset_${_dateKey(date)}';
}
