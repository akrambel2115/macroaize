import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import '../../routes/app_routes.dart';

/// Global email verification guard service
/// Enforces email verification across the application
/// SECURITY: Removed persistent skip verification flag to prevent tampering
class EmailVerificationGuard {
  static final EmailVerificationGuard _instance =
      EmailVerificationGuard._internal();
  factory EmailVerificationGuard() => _instance;
  EmailVerificationGuard._internal();

  /// Check if current user needs email verification
  /// SECURITY: Now only checks server-trusted Firebase Auth state
  Future<bool> needsVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return !user.emailVerified;
  }

  /// Synchronous version for cases where async is not possible
  /// SECURITY: Now only checks server-trusted Firebase Auth state
  bool needsVerificationSync() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return !user.emailVerified;
  }

  /// SECURITY: Skip verification functionality removed for security
  /// Users must verify their email to access protected features
  @Deprecated('Skip verification removed for security - users must verify email')
  Future<void> markVerificationSkipped() async {
    // This method no longer stores persistent skip state
    // Users must complete email verification to access protected features
    print('WARNING: Skip verification attempt - redirecting to verification');
    _redirectToVerification();
  }

  /// SECURITY: Reset functionality removed as skip flags no longer exist
  @Deprecated('Reset skip flag removed - no persistent state to reset')
  Future<void> resetSkipFlag([String? userId]) async {
    // No persistent skip state to reset anymore
    // This is a no-op for backward compatibility
  }

  /// Check if current user is securely authenticated
  bool isSecurelyAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.emailVerified;
  }

  /// Enforce email verification for sensitive operations
  /// Returns true if user can proceed, false if blocked
  bool checkVerificationOrBlock({
    String? errorMessage,
    bool showError = true,
    bool redirectToVerification = true,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    // Not authenticated at all
    if (user == null) {
      if (showError) {
        NotificationService.showError('auth_required');
      }
      return false;
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

    // Authenticated and verified - allow access
    return true;
  }

  /// Guard for premium features - requires both email verification AND premium status
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
    // This method should be called before existing premium checks
    return true;
  }

  /// Guard for usage tracking (scans, chats) - requires email verification
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

  /// Check and potentially redirect unverified users on app navigation
  /// Returns true if user should proceed to intended route, false if blocked
  bool checkRouteAccess(String routeName) {
    // Allow access to verification-related routes
    if (_isVerificationRoute(routeName)) {
      return true;
    }

    // Allow access to basic authentication routes
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

  /// Private method to redirect to verification screen
  void _redirectToVerification() {
    // Only redirect if not already on verification screen
    if (Get.currentRoute != Routes.emailVerificationView) {
      // Use post-frame callback to avoid navigation during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed(Routes.emailVerificationView);
      });
    }
  }

  /// Check if route is verification-related (always allow)
  bool _isVerificationRoute(String routeName) {
    return [
      Routes.emailVerificationView,
      Routes.splashView,
      Routes.welcomeView,
      Routes.transitionView,
    ].contains(routeName);
  }

  /// Check if route is basic authentication (allow for unverified users)
  bool _isBasicAuthRoute(String routeName) {
    return [
      Routes.signUpView,
      Routes.onBoardingView,
      Routes.planIntroView,
      Routes.languageView,
    ].contains(routeName);
  }

  /// Check if route requires email verification
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

  /// Reload user token to get latest verification status
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

  /// Get user verification status for UI display
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
