import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:macroaize/shared/models/user_usage.dart';
import 'package:macroaize/shared/services/subscription_service.dart';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

/// User combined authentication, subscription, and usage data
class AppUser {
  final User? firebaseUser;
  final Subscription? subscription;
  final UserUsage? usage;

  const AppUser({this.firebaseUser, this.subscription, this.usage});

  bool get isAuthenticated => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified == true;
  bool get isPremium => subscription?.isActive == true;
  bool get isSecurelyAuthenticated => isAuthenticated && isEmailVerified;

  String get displayName {
    if (firebaseUser?.displayName?.isNotEmpty == true) {
      return firebaseUser!.displayName!;
    }
    if (firebaseUser?.email?.isNotEmpty == true) {
      return firebaseUser!.email!;
    }
    return 'User';
  }

  String? get email => firebaseUser?.email;
  String? get uid => firebaseUser?.uid;
  int get remainingScans => isPremium ? -1 : (usage?.remainingScans ?? 2);
  int get remainingChats => isPremium ? -1 : (usage?.remainingChats ?? 5);
  bool get scanLimitReached => !isPremium && (usage?.scanLimitReached == true);
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

class AppUserService {
  static final AppUserService _instance = AppUserService._internal();
  factory AppUserService() => _instance;
  AppUserService._internal();

  SubscriptionService? _subscriptionService;
  UsageService? _usageService;
  Stream<AppUser>? _userStream;

  Stream<AppUser> get userStream =>
      _userStream ?? Stream.value(const AppUser());

  /// Initialize the service; optional mocks for testing
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

    return authStream.switchMap((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(const AppUser());
      }

      // Ensure services are initialized
      final subService = _subscriptionService ?? SubscriptionService();
      final usageService = _usageService ?? UsageService();

      // Combine latest form of 3 streams: Auth (current user), Subscription, Usage
      return Rx.combineLatest3<User, Subscription?, UserUsage?, AppUser>(
        Stream.value(firebaseUser), // Constant stream for current auth user
        subService.subscriptionStream,
        usageService.usageStream,
        (user, sub, usage) {
          return AppUser(firebaseUser: user, subscription: sub, usage: usage);
        },
      );
    });
  }

  Future<AppUser> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return const AppUser();
    if (_subscriptionService == null || _usageService == null)
      return AppUser(firebaseUser: firebaseUser);

    final subscription = await _subscriptionService!.subscriptionStream.first;
    final usage = await _usageService!.usageStream.first;

    return AppUser(
      firebaseUser: firebaseUser,
      subscription: subscription,
      usage: usage,
    );
  }

  Future<bool> isPremiumUser() async {
    final user = await getCurrentUser();
    return user.isPremium;
  }

  Future<bool> isPremiumNow() async {
    try {
      if (_subscriptionService == null) return false;
      final sub = await _subscriptionService!.getSubscriptionOnce();
      return sub?.isActive == true;
    } catch (_) {
      return false;
    }
  }

  bool isAuthenticated() => FirebaseAuth.instance.currentUser != null;
  bool isEmailVerified() =>
      FirebaseAuth.instance.currentUser?.emailVerified == true;
  bool isSecurelyAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.emailVerified;
  }

  bool needsEmailVerification() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.emailVerified;
  }

  /// check email verified and optionally show warnings
  bool checkAccountActivation(String feature, {bool showWarning = true}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (showWarning) NotificationService.showError('auth_required');
      return false;
    }
    if (!user.emailVerified) {
      if (showWarning) {
        String messageKey;
        switch (feature.toLowerCase()) {
          case 'chat':
            messageKey = 'account_activation_required_for_chat';
            break;
          case 'scanner':
            messageKey = 'account_activation_required_for_scanner';
            break;
          case 'premium':
            messageKey = 'account_activation_required_for_premium';
            break;
          default:
            messageKey = 'verify_account_to_continue';
        }
        NotificationService.showError(messageKey);
      }
      return false;
    }
    return true;
  }

  bool isAccountActivated() => checkAccountActivation('', showWarning: false);
}
