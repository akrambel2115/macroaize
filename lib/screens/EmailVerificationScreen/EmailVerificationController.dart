import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/email_verification_guard.dart';
import '../../routes/app_routes.dart';

class EmailVerificationController extends GetxController {
  final AuthRepository authRepo;
  EmailVerificationController(this.authRepo);

  final isLoading = false.obs;
  final isResendLoading = false.obs;
  final resendAttempts = 0.obs;
  final nextResendTime = DateTime(0).obs;
  final userEmail = ''.obs;

  Timer? _verificationTimer;
  Timer? _resendCooldownTimer;

  static const int maxResendAttempts = 5;
  static const int resendCooldownMinutes = 1;
  static const int verificationCheckIntervalSeconds = 3;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
    _startVerificationPolling();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? '';
    }
  }

  void _startVerificationPolling() {
    _verificationTimer = Timer.periodic(
      const Duration(seconds: verificationCheckIntervalSeconds),
      (_) => _checkVerificationStatus(),
    );
  }

  Future<void> _checkVerificationStatus() async {
    try {
      // Reload user to get latest email verification status
      final failure = await authRepo.reloadUser();
      if (failure == null) {
        final isVerified = await authRepo.isEmailVerified();
        if (isVerified) {
          _verificationTimer?.cancel();
          _onVerificationSuccess();
        }
      }
    } catch (e) {
      // Silent fail - don't interrupt user experience
      print('Verification check error: $e');
    }
  }

  void _onVerificationSuccess() {
    NotificationService.showSuccess('email_verification_success');
    // Navigate to home or appropriate screen after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.leadingView);
    });
  }

  Future<void> resendVerificationEmail() async {
    if (_isResendBlocked()) return;

    isResendLoading.value = true;
    try {
      final failure = await authRepo.sendEmailVerification();
      if (failure == null) {
        resendAttempts.value++;
        _startResendCooldown();
        NotificationService.showSuccess('email_verification_resent');
      } else {
        NotificationService.showError(_mapFailureToKey(failure));
      }
    } catch (e) {
      NotificationService.showError('email_verification_resend_error');
    } finally {
      isResendLoading.value = false;
    }
  }

  bool _isResendBlocked() {
    if (resendAttempts.value >= maxResendAttempts) {
      NotificationService.showError('email_verification_max_attempts');
      return true;
    }

    if (nextResendTime.value.isAfter(DateTime.now())) {
      final remaining = nextResendTime.value.difference(DateTime.now());
      NotificationService.showError(
        'email_verification_cooldown'.trParams({
          'seconds': remaining.inSeconds.toString(),
        }),
      );
      return true;
    }

    return false;
  }

  void _startResendCooldown() {
    nextResendTime.value = DateTime.now().add(
      Duration(minutes: resendCooldownMinutes),
    );

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (nextResendTime.value.isBefore(DateTime.now())) {
        _resendCooldownTimer?.cancel();
        update(); // Update UI
      }
    });
  }

  void skipVerification() {
    // Mark that user has explicitly skipped verification for this session
    final guard = EmailVerificationGuard();
    guard.markVerificationSkipped();

    // Navigate directly to home page
    // User keeps unverified state - features will still require verification
    Get.offAllNamed(Routes.leadingView);
  }

  String _mapFailureToKey(failure) {
    // Map auth failures to translation keys
    return 'email_verification_error';
  }

  bool get canResend =>
      resendAttempts.value < maxResendAttempts &&
      nextResendTime.value.isBefore(DateTime.now());

  int get remainingAttempts => maxResendAttempts - resendAttempts.value;

  Duration get cooldownRemaining =>
      nextResendTime.value.isAfter(DateTime.now())
          ? nextResendTime.value.difference(DateTime.now())
          : Duration.zero;

  @override
  void onClose() {
    _verificationTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.onClose();
  }
}
