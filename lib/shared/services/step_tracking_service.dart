import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackingService extends GetxService with WidgetsBindingObserver {
  final RxInt dailySteps = 0.obs;
  final RxInt stepCaloriesBurned = 0.obs;
  final RxBool isTrackingAvailable = false.obs;

  StreamSubscription<StepCount>? _stepSub;

  DateTime _activeDate = _dateOnly(DateTime.now());
  int _baselineRawSteps = 0;
  int _latestRawSteps = 0;
  int _resetOffsetSteps = 0;

  bool _started = false;

  static const double _caloriesPerKgPerKm = 0.9;

  Future<StepTrackingService> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _loadPersistedStateForDate(_activeDate);
    await _ensureTracking();
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSub?.cancel();
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

    final granted =
        permission.isGranted || permission.isLimited || permission.isRestricted;
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

    if (_baselineRawSteps == 0) {
      _baselineRawSteps = adjustedRaw;
    }

    final computedSteps = math.max(0, adjustedRaw - _baselineRawSteps);
    final computedCalories = _estimateStepCalories(computedSteps);

    if (computedSteps != dailySteps.value ||
        computedCalories != stepCaloriesBurned.value) {
      dailySteps.value = computedSteps;
      stepCaloriesBurned.value = computedCalories;
      await _persistActiveDateState();
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
    _latestRawSteps = 0;
    _resetOffsetSteps = 0;
    dailySteps.value = 0;
    stepCaloriesBurned.value = 0;

    await _loadPersistedStateForDate(_activeDate);
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

  Future<int> getDailyStepsForDate(DateTime date) async {
    if (_isSameDate(date, _activeDate)) {
      return dailySteps.value;
    }
    return await SharedPref.readInt(_stepsKey(date)) ?? 0;
  }

  Future<int> getStepCaloriesForDate(DateTime date) async {
    if (_isSameDate(date, _activeDate)) {
      return stepCaloriesBurned.value;
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
