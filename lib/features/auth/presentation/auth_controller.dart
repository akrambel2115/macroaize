import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/notification_service.dart';

import '../../auth/domain/auth_failure.dart';
import '../../auth/domain/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository repo;
  AuthController(this.repo);

  // Form keys
  final loginKey = GlobalKey<FormState>();
  final registerKey = GlobalKey<FormState>();

  // Text controllers
  final email = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final confirmPassword = TextEditingController();

  final isLoading = false.obs;
  final tosAccepted = false.obs;
  final errorText = ''.obs;
  // Holds the last success translation key so callers (e.g. modal) can show it after UI changes
  final lastSuccessKey = ''.obs;

  // Eye / obscure state for password fields
  final loginObscure = true.obs;
  final registerPasswordObscure = true.obs;
  final registerConfirmObscure = true.obs;

  // Whether to show the eye icon (becomes true when user starts typing)
  final showPasswordEye = false.obs; // for both login & register password field
  final showConfirmEye = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Update eye visibility when the user types
    password.addListener(() {
      showPasswordEye.value = password.text.isNotEmpty;
    });
    confirmPassword.addListener(() {
      showConfirmEye.value = confirmPassword.text.isNotEmpty;
    });
  }

  void toggleLoginObscure() => loginObscure.value = !loginObscure.value;
  void toggleRegisterPasswordObscure() =>
      registerPasswordObscure.value = !registerPasswordObscure.value;
  void toggleRegisterConfirmObscure() =>
      registerConfirmObscure.value = !registerConfirmObscure.value;

  // Validation
  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'email_required'.tr;
    final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
    if (!ok) return 'invalid_email_format'.tr;
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'password_required'.tr;
    if (v.length < 8) return 'password_min_length'.tr;
    final upper = RegExp(r'[A-Z]').hasMatch(v);
    final lower = RegExp(r'[a-z]').hasMatch(v);
    final digit = RegExp(r'\d').hasMatch(v);
    final symbol = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/]').hasMatch(v);
    if (!(upper && lower && digit && symbol)) return 'password_complexity'.tr;
    return null;
  }

  String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'name_required'.tr;
    if (v.trim().length < 2) return 'name_too_short'.tr;
    return null;
  }

  String? validateConfirm(String? v) {
    if (v != password.text) return 'passwords_do_not_match'.tr;
    return null;
  }

  Future<User?> loginEmail() async {
    if (!(loginKey.currentState?.validate() ?? false)) return null;
    return _guard(() async {
      final (user, failure) = await repo.signInWithEmail(
        email: email.text.trim(),
        password: password.text,
      );
      final res = _handle(user, failure);
      if (res != null) lastSuccessKey.value = 'auth_login_success';
      return res;
    });
  }

  Future<User?> registerEmail() async {
    if (!(registerKey.currentState?.validate() ?? false) || !tosAccepted.value) {
      return null;
    }
    return _guard(() async {
      final (user, failure) = await repo.registerWithEmail(
        email: email.text.trim(),
        password: password.text,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
      );
      final res = _handle(user, failure);
      if (res != null) {
        // CRITICAL: After successful registration, redirect to email verification
        // Don't set success message as we're redirecting to verification screen
        lastSuccessKey.value = 'auth_register_verification_required';
      }
      return res;
    });
  }

  Future<User?> google() async => _guard(() async {
    final (user, failure) = await repo.signInWithGoogle();
    final res = _handle(user, failure);
    if (res != null) lastSuccessKey.value = 'auth_login_success';
    return res;
  });

  Future<User?> apple() async => _guard(() async {
    final (user, failure) = await repo.signInWithApple();
    final res = _handle(user, failure);
    if (res != null) lastSuccessKey.value = 'auth_login_success';
    return res;
  });

  // Facebook sign-in removed; use Google or email/password

  Future<void> resetPassword() async {
    final v = email.text.trim();
    final err = validateEmail(v);
    if (err != null) {
      errorText.value = err;
      return;
    }
    await _guard(() async {
      final failure = await repo.sendPasswordReset(email: v);
      if (failure != null) {
        final key = _mapFailure(failure);
        errorText.value = key.tr;
        NotificationService.showError(key);
      } else {
        errorText.value = '';
        NotificationService.showSuccess('auth_password_reset_sent');
      }
      return null;
    });
  }

  Future<T?> _guard<T>(Future<T?> Function() body) async {
    if (isLoading.value) return null;
    errorText.value = '';
    isLoading.value = true;
    update();
    try {
      return await body();
    } catch (e) {
      errorText.value = 'auth_unexpected_error'.tr;
      NotificationService.showError('auth_unexpected_error');
      return null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  User? _handle(User? user, AuthFailure? failure) {
    if (failure != null) {
      final key = _mapFailure(failure);
      errorText.value = key.tr;
      NotificationService.showError(key);
      return null;
    }
    return user;
  }

  String _mapFailure(AuthFailure f) {
    if (f is CredentialFailure) {
      switch (f.code) {
        case 'invalid-credential':
        case 'wrong-password':
          return 'auth_wrong_credentials';
        case 'user-not-found':
          return 'auth_account_not_found';
        case 'email-already-in-use':
          return 'auth_email_in_use';
        case 'weak-password':
          return 'auth_weak_password';
        case 'account-exists-with-different-credential':
          return 'auth_account_different_provider';
        default:
          return f.message.isNotEmpty ? f.message : 'auth_authentication_error';
      }
    }
    if (f is NetworkFailure) return 'auth_network_error';
    if (f is UnknownFailure) return 'auth_unknown_error';
    return 'auth_authentication_error';
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}
