import 'dart:async';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_usage.dart';
import '../../SharePrefHelper/share_pref.dart';
import '../../SharePrefHelper/share_pref_key.dart';

class UsageService {
  UsageService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;
  final StreamController<UserUsage> _usageController =
      StreamController<UserUsage>.broadcast();
  StreamSubscription<User?>? _authSub;
  bool _streamInitialized = false;
  bool _hydrationRetryInFlight = false;
  int _hydrationAttempts = 0;
  final int _maxHydrationAttempts = 5;

  bool _hydrated = false;
  bool _isPremium = false;
  int _scanLimit = 1;
  int _chatLimit = 2;
  int _scanCount = 0;
  int _chatCount = 0;

  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _syncInterval = const Duration(seconds: 30);
  bool _syncInFlight = false;

  bool get isPremium => _isPremium;
  int get scanLimit => _scanLimit;
  int get chatLimit => _chatLimit;
  int get scanCount => _scanCount;
  int get chatCount => _chatCount;

  void setPremium(bool value) {
    if (_isPremium != value) {
      _isPremium = value;
      _emitUsageSnapshot();
    }
  }

  // reactive usage stream
  Stream<UserUsage> get usageStream {
    if (!_streamInitialized) {
      _streamInitialized = true;
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user == null) {
          _resetLocal();
          _emitUsageSnapshot();
          return;
        }
        try {
          final cachedLimit = await SharedPref.readInt(SharePrefKey.scanLimit);
          if (cachedLimit != null) {
            _scanLimit = cachedLimit;
            _emitUsageSnapshot();
          }
          await getUsage();
        } catch (_) {
          _startHydrationRetries();
        }
        _emitUsageSnapshot();
      });
      _emitUsageSnapshot();
    }
    return _usageController.stream;
  }

  Future<void> _ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
  }

  // hydrate from backend
  Future<void> getUsage() async {
    await _ensureAuthenticated();
    try {
      final callable = _functions.httpsCallable('getUsage');
      final res = await callable.call();
      final data = Map<String, dynamic>.from(res.data ?? {});

      _isPremium = data['isPremium'] == true;
      // flat or nested response
      if (data.containsKey('scanCount') || data.containsKey('scanLimit')) {
        _scanCount = (data['scanCount'] as num?)?.toInt() ?? 0;
        _chatCount = (data['chatCount'] as num?)?.toInt() ?? 0;
        final sl = data['scanLimit'];
        final cl = data['chatLimit'];
        if (sl != null) {
          _scanLimit = (sl as num).toInt();
          SharedPref.saveInt(SharePrefKey.scanLimit, _scanLimit);
        }
        if (cl != null) _chatLimit = (cl as num).toInt();
      } else {
        final usage = Map<String, dynamic>.from(data['usage'] ?? {});
        final limits = Map<String, dynamic>.from(data['limits'] ?? {});
        _scanCount = (usage['scanCount'] as num?)?.toInt() ?? 0;
        _chatCount = (usage['chatCount'] as num?)?.toInt() ?? 0;
        if (limits['scanLimit'] != null) {
          _scanLimit = (limits['scanLimit'] as num).toInt();
          SharedPref.saveInt(SharePrefKey.scanLimit, _scanLimit);
        }
        _chatLimit = (limits['chatLimit'] as num?)?.toInt() ?? _chatLimit;
      }

      _hydrated = true;
      _emitUsageSnapshot();
    } on FirebaseFunctionsException catch (_) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      if (signedIn) {
        throw Exception('usage_call_failed');
      }
      rethrow;
    }
  }

  // push counters to server
  Future<void> syncUsage() async {
    await _ensureAuthenticated();
    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      final callable = _functions.httpsCallable('syncUsage');
      await callable.call({
        'scanCount': _scanCount,
        'chatCount': _chatCount,
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
      });
      _lastSync = DateTime.now();
    } on FirebaseFunctionsException catch (_) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      if (!signedIn) rethrow;
    } finally {
      _syncInFlight = false;
    }
    _emitUsageSnapshot();
  }

  // increment action usage
  Future<UsageIncrementResult> incrementUsage(String actionType) async {
    await _ensureAuthenticated();
    if (!_hydrated) {
      try {
        final callable = _functions.httpsCallable('incrementUsage');
        final res = await callable.call({'actionType': actionType});
        final data = Map<String, dynamic>.from(res.data ?? {});

        final isPremiumResp = data['isPremium'] == true;
        final success = data['success'] == true;
        final message = (data['message'] as String?) ?? '';

        UsageData? current;
        if (data['currentUsage'] != null) {
          try {
            current = UsageData.fromMap(
              Map<String, dynamic>.from(data['currentUsage']),
            );
          } catch (_) {}
        }

        _isPremium = isPremiumResp;
        if (current != null) {
          _scanCount = current.scanCount;
          _chatCount = current.chatCount;
          _scanLimit = current.scanLimit;
          _chatLimit = current.chatLimit;
        }
        _hydrated = true;
        _emitUsageSnapshot();

        return UsageIncrementResult(
          success: success,
          isPremium: isPremiumResp,
          message: message,
          currentUsage: current,
          limitReached: !success,
        );
      } on FirebaseFunctionsException catch (_) {
        final signedIn = FirebaseAuth.instance.currentUser != null;
        if (!signedIn) rethrow;
        try {
          await getUsage();
        } catch (_) {}
      } catch (_) {}
    }
    if (_hydrated && _isPremium) {
      await _maybeSync();
      final result = UsageIncrementResult(
        success: true,
        isPremium: true,
        message: '',
        currentUsage: _currentUsageData(),
      );
      _emitUsageSnapshot();
      return result;
    }
    if (actionType == 'scan') {
      if (_scanCount >= _scanLimit) {
        return UsageIncrementResult(
          success: false,
          isPremium: false,
          message: 'daily_scan_limit_reached',
          limitReached: true,
          currentUsage: _currentUsageData(),
        );
      }
      _scanCount += 1;
    } else if (actionType == 'chat') {
      if (_chatCount >= _chatLimit) {
        return UsageIncrementResult(
          success: false,
          isPremium: false,
          message: 'daily_chat_limit_reached',
          limitReached: true,
          currentUsage: _currentUsageData(),
        );
      }
      _chatCount += 1;
    } else {
      return UsageIncrementResult(
        success: false,
        isPremium: false,
        message: 'invalid_action',
      );
    }
    await _maybeSync();
    _emitUsageSnapshot();

    return UsageIncrementResult(
      success: true,
      isPremium: false,
      message: '',
      currentUsage: _currentUsageData(),
    );
  }

  // retry with backoff
  void _startHydrationRetries() {
    if (_hydrationRetryInFlight) return;
    _hydrationRetryInFlight = true;
    _hydrationAttempts = 0;

    Future<void>(() async {
      while (!_hydrated && _hydrationAttempts < _maxHydrationAttempts) {
        if (FirebaseAuth.instance.currentUser == null) break;

        final delaySeconds = pow(2, _hydrationAttempts).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
        try {
          await getUsage();
          break;
        } catch (_) {
          _hydrationAttempts += 1;
        }
      }
      _hydrationRetryInFlight = false;
    });
  }

  Future<void> _maybeSync() async {
    final now = DateTime.now();
    if (now.difference(_lastSync) >= _syncInterval) {
      Future.microtask(() => syncUsage());
    }
  }

  UsageData _currentUsageData() => UsageData(
    scanCount: _scanCount,
    chatCount: _chatCount,
    scanLimit: _scanLimit,
    chatLimit: _chatLimit,
  );

  void _emitUsageSnapshot() {
    final snapshot = UserUsage(
      scanCount: _scanCount,
      chatCount: _chatCount,
      lastUsageDate: null,
      scanLimit: _scanLimit,
      chatLimit: _chatLimit,
    );
    if (!_usageController.isClosed) {
      try {
        _usageController.add(snapshot);
      } catch (_) {}
    }
  }

  // cleanup resources
  void dispose() {
    try {
      _authSub?.cancel();
    } catch (_) {}
    try {
      _usageController.close();
    } catch (_) {}
  }

  void _resetLocal() {
    _hydrated = false;
    _isPremium = false;
    _scanLimit = 1;
    _chatLimit = 2;
    _scanCount = 0;
    _chatCount = 0;
  }
}

class UsageIncrementResult {
  final bool success;
  final bool isPremium;
  final String message;
  final bool limitReached;
  final UsageData? currentUsage;

  UsageIncrementResult({
    required this.success,
    required this.isPremium,
    required this.message,
    this.limitReached = false,
    this.currentUsage,
  });
}

class UsageData {
  final int scanCount;
  final int chatCount;
  final int scanLimit;
  final int chatLimit;

  UsageData({
    required this.scanCount,
    required this.chatCount,
    required this.scanLimit,
    required this.chatLimit,
  });

  factory UsageData.fromMap(Map<String, dynamic> map) {
    return UsageData(
      scanCount: (map['scanCount'] as num?)?.toInt() ?? 0,
      chatCount: (map['chatCount'] as num?)?.toInt() ?? 0,
      scanLimit: (map['scanLimit'] as num?)?.toInt() ?? 1,
      chatLimit: (map['chatLimit'] as num?)?.toInt() ?? 2,
    );
  }

  int get remainingScans => (scanLimit - scanCount).clamp(0, scanLimit);
  int get remainingChats => (chatLimit - chatCount).clamp(0, chatLimit);
}
