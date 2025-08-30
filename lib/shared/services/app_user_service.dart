import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:foodcalorietracker/shared/models/user_usage.dart';
import 'package:foodcalorietracker/shared/services/subscription_service.dart';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'dart:async';

/// Unified model combining user authentication, subscription, and usage data
class AppUser {
  final User? firebaseUser;
  final Subscription? subscription;
  final UserUsage? usage;

  const AppUser({this.firebaseUser, this.subscription, this.usage});

  /// Check if user is authenticated
  bool get isAuthenticated => firebaseUser != null;

  /// Check if user has an active premium subscription
  bool get isPremium => subscription?.isActive == true;

  /// User's display name or email
  String get displayName {
    if (firebaseUser?.displayName?.isNotEmpty == true) {
      return firebaseUser!.displayName!;
    }
    if (firebaseUser?.email?.isNotEmpty == true) {
      return firebaseUser!.email!;
    }
    return 'User';
  }

  /// User's email
  String? get email => firebaseUser?.email;

  /// User ID
  String? get uid => firebaseUser?.uid;

  /// Remaining scans for free users
  int get remainingScans => isPremium ? -1 : (usage?.remainingScans ?? 2);

  /// Remaining chats for free users
  int get remainingChats => isPremium ? -1 : (usage?.remainingChats ?? 5);

  /// Check if scan limit is reached
  bool get scanLimitReached => !isPremium && (usage?.scanLimitReached == true);

  /// Check if chat limit is reached
  bool get chatLimitReached => !isPremium && (usage?.chatLimitReached == true);

  AppUser copyWith({
    User? firebaseUser,
    Subscription? subscription,
    UserUsage? usage,
  }) {
    return AppUser(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
    );
  }
}

/// Unified service for managing user authentication, subscription, and usage state
class AppUserService {
  static final AppUserService _instance = AppUserService._internal();
  factory AppUserService() => _instance;
  AppUserService._internal();

  // Delay creating Firebase-backed services until initialize() is called.
  SubscriptionService? _subscriptionService;
  UsageService? _usageService;

  Stream<AppUser>? _userStream;

  // Safe getter: returns a simple empty AppUser stream if the service hasn't been
  // initialized yet. This prevents runtime failures in tests or views that call
  // Get.find<AppUserService>() before Firebase is available.
  Stream<AppUser> get userStream =>
      _userStream ?? Stream.value(const AppUser());

  /// Initialize the service (call this in main or app startup). You can provide
  /// optional mock services for testing.
  void initialize({
    SubscriptionService? subscriptionService,
    UsageService? usageService,
    Stream? authStateStream,
  }) {
    _subscriptionService = subscriptionService ?? SubscriptionService();
    _usageService = usageService ?? UsageService();
    _userStream = _createUserStream(authStateStream: authStateStream);
  }

  Stream<AppUser> _createUserStream({Stream? authStateStream}) {
    final authStream =
        authStateStream ?? FirebaseAuth.instance.authStateChanges();

    return authStream.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return const AppUser();
      }

      // If services are not initialized, return a partial AppUser to avoid
      // crashing the app. initialize() should be called on app startup to
      // enable full behavior.
      if (_subscriptionService == null || _usageService == null) {
        return AppUser(firebaseUser: firebaseUser);
      }

      // Wait for subscription and usage data to be available
      final subscription = await _subscriptionService!.subscriptionStream.first;
      final usage = await _usageService!.usageStream.first;

      return AppUser(
        firebaseUser: firebaseUser,
        subscription: subscription,
        usage: usage,
      );
    });
  }

  /// Get current user snapshot (for non-reactive usage)
  Future<AppUser> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const AppUser();
    }

    // If services aren't initialized, return partial user data instead of
    // trying to access Firebase-backed streams.
    if (_subscriptionService == null || _usageService == null) {
      return AppUser(firebaseUser: firebaseUser);
    }

    final subscription = await _subscriptionService!.subscriptionStream.first;
    final usage = await _usageService!.usageStream.first;

    return AppUser(
      firebaseUser: firebaseUser,
      subscription: subscription,
      usage: usage,
    );
  }

  /// Convenience method to check if user is premium
  Future<bool> isPremiumUser() async {
    final user = await getCurrentUser();
    return user.isPremium;
  }

  /// Non-reactive server-checked premium flag. Useful for gating where
  /// streams may not have emitted yet. Returns `false` on errors (fail closed).
  Future<bool> isPremiumNow() async {
    try {
      if (_subscriptionService == null) return false;
      final sub = await _subscriptionService!.getSubscriptionOnce();
      return sub?.isActive == true;
    } catch (_) {
      // Fail closed to avoid granting access on errors.
      return false;
    }
  }

  /// Convenience method to check if user is authenticated
  bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
