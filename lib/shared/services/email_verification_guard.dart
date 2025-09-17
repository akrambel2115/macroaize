import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import '../../routes/app_routes.dart';

/// Email verification guard service
class EmailVerificationGuard {
  static final EmailVerificationGuard _instance =
      EmailVerificationGuard._internal();
  factory EmailVerificationGuard() => _instance;
  EmailVerificationGuard._internal();

  DateTime? _skipUntil;
  bool _skipActive = false;
  bool get _isSkipActive => _skipActive || (_skipUntil != null && DateTime.now().isBefore(_skipUntil!));

  Future<bool> needsVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (_isSkipActive) return false;
    return !user.emailVerified;
  }

  bool needsVerificationSync() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (_isSkipActive) return false;
    return !user.emailVerified;
  }

  Future<void> markVerificationSkipped() async {
    _skipActive = true; // Session-scoped skip
  }

  Future<void> markVerificationSkippedFor(Duration duration) async {
    _skipUntil = DateTime.now().add(duration);
  }

  Future<void> resetSkipFlag([String? userId]) async {
    _skipActive = false;
    _skipUntil = null;
  }

  bool isSecurelyAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.emailVerified;
  }

  bool checkVerificationOrBlock({
    String? errorMessage,
    bool showError = true,
    bool redirectToVerification = true,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    // Not authenticated
    if (user == null) {
      if (showError) {
        NotificationService.showError('auth_required');
      }
      return false;
    }

    if (_isSkipActive) {
      return true;
    }

    // Authenticated but not verified
    if (!user.emailVerified) {
      if (showError) {
        final message =
            errorMessage ?? 'email_verification_required_for_feature';
        NotificationService.showError(message);
      }

      if (redirectToVerification) {
        _redirectToVerification();
      }

      return false;
    }

    // Authenticated and verified
    return true;
  }

  Future<bool> checkPremiumAccessOrBlock({
    String? errorMessage,
    bool showError = true,
  }) async {
  // First check email verification
    if (!checkVerificationOrBlock(
      errorMessage: 'email_verification_required_for_premium',
      showError: showError,
      redirectToVerification: true,
    )) {
      return false;
    }

    // Then check premium status (existing logic can be kept)
    return true;
  }

  bool checkUsageAccessOrBlock({String? feature}) {
    return checkVerificationOrBlock(
      errorMessage:
          feature != null
              ? 'email_verification_required_for_$feature'
              : 'email_verification_required_for_feature',
      showError: true,
      redirectToVerification: true,
    );
  }

  bool checkRouteAccess(String routeName) {
    // Allow verification-related routes
    if (_isVerificationRoute(routeName)) {
      return true;
    }

    // Allow basic authentication routes
    if (_isBasicAuthRoute(routeName)) {
      return true;
    }

    // For protected routes, check verification
    if (_isProtectedRoute(routeName)) {
      return checkVerificationOrBlock(
        errorMessage: 'email_verification_required_for_app_access',
        showError: false, // Don't show error on route changes
        redirectToVerification: true,
      );
    }

    return true;
  }

  /// Redirect to verification screen
  void _redirectToVerification() {
    // Only redirect if not already on verification screen
    if (Get.currentRoute != Routes.emailVerificationView) {
      // Use post-frame callback to avoid navigation during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.emailVerificationView);
      });
    }
  }

  bool _isVerificationRoute(String routeName) {
    return [
      Routes.emailVerificationView,
      Routes.splashView,
      Routes.welcomeView,
      Routes.transitionView,
    ].contains(routeName);
  }

  bool _isBasicAuthRoute(String routeName) {
    return [
      Routes.signUpView,
      Routes.onBoardingView,
      Routes.planIntroView,
      Routes.languageView,
    ].contains(routeName);
  }

  bool _isProtectedRoute(String routeName) {
    return [
      Routes.leadingView, // Main app tabs
      Routes.homeView,
      Routes.scanFoodView,
      Routes.scanCalorieView,
      Routes.chatView,
      Routes.premiumView,
      Routes.settingView,
      Routes.analyticsView,
      Routes.historyView,
      Routes.recipesView,
      Routes.localFoodView,
      Routes.personalDetailsView,
      Routes.adjustGoalsView,
      Routes.accountDetailsView,
    ].contains(routeName);
  }

  Future<void> reloadUserVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (e) {
        print('Error reloading user verification status: $e');
      }
    }
  }

  Map<String, dynamic> getVerificationStatus() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {
        'isAuthenticated': false,
        'isVerified': false,
        'needsVerification': false,
        'email': null,
      };
    }

    return {
      'isAuthenticated': true,
      'isVerified': user.emailVerified,
      'needsVerification': !user.emailVerified,
      'email': user.email,
    };
  }
}
