import 'dart:async';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_usage.dart';

/// Client-side usage helper that integrates with secure backend callables:
/// - getUsage: hydrate server-of-record counts/limits and premium flag
/// - syncUsage: reconcile local counters with server state (monotonic, capped)
///
/// For backwards compatibility, we expose incrementUsage(actionType) which:
/// - Ensures hydration via getUsage once per session
/// - Checks local counters against limits (unless premium)
/// - Increments local counters if allowed
/// - Schedules a background sync periodically
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

  // Local session cache (server-of-record snapshot + local increments)
  bool _hydrated = false;
  bool _isPremium = false;
  int _scanLimit = 2;
  int _chatLimit = 5;
  int _scanCount = 0;
  int _chatCount = 0;

  // Sync throttle
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _syncInterval = const Duration(seconds: 30);
  bool _syncInFlight = false;

  // Public snapshot getters (read-only)
  bool get isPremium => _isPremium;
  int get scanLimit => _scanLimit;
  int get chatLimit => _chatLimit;
  int get scanCount => _scanCount;
  int get chatCount => _chatCount;

  /// Reactive stream of usage snapshots.
  /// Emits a default zero-usage snapshot when unauthenticated.
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
          await getUsage();
        } catch (_) {
          // On failure to hydrate, still emit whatever local state we have
          // and start a retry loop to eventually hydrate from server.
          _startHydrationRetries();
        }
        _emitUsageSnapshot();
      });
      // Emit initial unauthenticated snapshot until auth flows
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

  /// Hydrate from server-of-record
  Future<void> getUsage() async {
    await _ensureAuthenticated();
    try {
      final callable = _functions.httpsCallable('getUsage');
      final res = await callable.call();
      final data = Map<String, dynamic>.from(res.data ?? {});

      _isPremium = data['isPremium'] == true;
      // Support both shapes:
      // A) Top-level: { isPremium, scanCount, chatCount, scanLimit, chatLimit, ... }
      // B) Nested: { isPremium, usage: {scanCount, chatCount}, limits: {scanLimit, chatLimit}, serverTimestampMs }
      if (data.containsKey('scanCount') || data.containsKey('scanLimit')) {
        _scanCount = (data['scanCount'] as num?)?.toInt() ?? 0;
        _chatCount = (data['chatCount'] as num?)?.toInt() ?? 0;
        final sl = data['scanLimit'];
        final cl = data['chatLimit'];
        if (sl != null) _scanLimit = (sl as num).toInt();
        if (cl != null) _chatLimit = (cl as num).toInt();
        // optional timestamp fields (not stored client-side)
      } else {
        final usage = Map<String, dynamic>.from(data['usage'] ?? {});
        final limits = Map<String, dynamic>.from(data['limits'] ?? {});
        _scanCount = (usage['scanCount'] as num?)?.toInt() ?? 0;
        _chatCount = (usage['chatCount'] as num?)?.toInt() ?? 0;
        _scanLimit = (limits['scanLimit'] as num?)?.toInt() ?? _scanLimit;
        _chatLimit = (limits['chatLimit'] as num?)?.toInt() ?? _chatLimit;
        // optional timestamp fields (not stored client-side)
      }

      _hydrated = true;
      _emitUsageSnapshot();
    } on FirebaseFunctionsException catch (_) {
      // If user is signed in, map callable auth/app check errors to a generic error
      final signedIn = FirebaseAuth.instance.currentUser != null;
      if (signedIn) {
        // Keep state unchanged here and let callers decide how to proceed.
        // Throwing allows existing callers to handle the failure, but
        // callers that want a best-effort hydration should call
        // `_startHydrationRetries`.
        throw Exception('usage_call_failed');
      }
      rethrow;
    }
  }

  /// Push local counters to server. Monotonic and capped on server.
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
      // Swallow callable errors into a generic failure when signed-in
      // to avoid leaking auth/app-check specifics to UI logic.
      // Controllers already enforce limits locally.
      final signedIn = FirebaseAuth.instance.currentUser != null;
      if (!signedIn) rethrow;
    } finally {
      _syncInFlight = false;
    }
    _emitUsageSnapshot();
  }

  Future<UsageIncrementResult> incrementUsage(String actionType) async {
    await _ensureAuthenticated();

    // If we haven't hydrated from server this session, prefer the server-side
    // authoritative callable. That lets the backend decide premium status
    // and prevents client-side failures when `getUsage` is missing.
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

        // Update local snapshot conservatively so UI reflects server state
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
        // If callable failed due to auth/app-check, surface error to caller
        final signedIn = FirebaseAuth.instance.currentUser != null;
        if (!signedIn) rethrow;
        // Attempt a best-effort hydration to update local counters
        // from the server before falling back to local enforcement.
        try {
          await getUsage();
        } catch (_) {
          // ignore; we'll fall back to local enforcement below
        }
        // Otherwise fall through to local enforcement as a last resort.
      } catch (_) {
        // Non-callable error: fall back to local enforcement below.
      }
    }

    // If we're hydrated and premium, short-circuit locally to reduce server calls
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

    // Enforce local caps from last hydration (or when server fallback used)
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

    // Schedule/perform background sync
    await _maybeSync();
    _emitUsageSnapshot();

    return UsageIncrementResult(
      success: true,
      isPremium: false,
      message: '',
      currentUsage: _currentUsageData(),
    );
  }

  /// Try to hydrate from server with exponential backoff. Runs in background
  /// until `_hydrated` becomes true, max attempts reached, or user signs out.
  void _startHydrationRetries() {
    if (_hydrationRetryInFlight) return;
    _hydrationRetryInFlight = true;
    _hydrationAttempts = 0;

    Future<void>(() async {
      while (!_hydrated && _hydrationAttempts < _maxHydrationAttempts) {
        // If user signed out while retrying, stop.
        if (FirebaseAuth.instance.currentUser == null) break;

        final delaySeconds = pow(2, _hydrationAttempts).toInt();
        await Future.delayed(Duration(seconds: delaySeconds));
        try {
          await getUsage();
          // success will set _hydrated and emit snapshot
          break;
        } catch (_) {
          _hydrationAttempts += 1;
          // continue loop
        }
      }
      _hydrationRetryInFlight = false;
    });
  }

  Future<void> _maybeSync() async {
    final now = DateTime.now();
    if (now.difference(_lastSync) >= _syncInterval) {
      // Fire and forget; errors bubble up next explicit call
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
    // Map lightweight UsageData into UI's UserUsage model for compatibility
    final snapshot = UserUsage(
      scanCount: _scanCount,
      chatCount: _chatCount,
      lastUsageDate: null,
      scanLimit: _scanLimit,
      chatLimit: _chatLimit,
    );
    if (!_usageController.isClosed) {
      // ignore errors if no listeners
      try {
        _usageController.add(snapshot);
      } catch (_) {}
    }
  }

  /// Cleanup resources when the service is no longer needed.
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
    _scanLimit = 2;
    _chatLimit = 5;
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
      scanLimit: (map['scanLimit'] as num?)?.toInt() ?? 2,
      chatLimit: (map['chatLimit'] as num?)?.toInt() ?? 5,
    );
  }

  int get remainingScans => (scanLimit - scanCount).clamp(0, scanLimit);
  int get remainingChats => (chatLimit - chatCount).clamp(0, chatLimit);
}
