import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_failure.dart';

class AccountController extends GetxController {
  final AuthRepository repo;
  AccountController(this.repo);

  final isLoading = false.obs;
  final errorText = ''.obs;

  // Display name editing
  final displayNameController = TextEditingController();

  // Change password fields
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  // Helpers
  Future<void> updateDisplayName() async {
    final raw = displayNameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (raw.length < 2 || raw.length > 50) {
      errorText.value = 'Name must be 2-50 chars';
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    final fail = await repo.updateDisplayName(raw);
    isLoading.value = false;
    if (fail != null) {
      errorText.value = _mapFailure(fail);
    } else {
      errorText.value = '';
      Get.back(result: true);
      // Success notification is handled by caller
    }
  }

  Future<void> changePassword() async {
    // Validate client-side
    final cur = currentPassword.text;
    final nw = newPassword.text;
    final conf = confirmPassword.text;
    if (cur.isEmpty || nw.isEmpty || conf.isEmpty) {
      errorText.value = 'All fields are required';
      return;
    }
    if (nw.length < 8) {
      errorText.value = 'Password too short';
      return;
    }
    final upper = RegExp(r'[A-Z]').hasMatch(nw);
    final lower = RegExp(r'[a-z]').hasMatch(nw);
    final digit = RegExp(r'\d').hasMatch(nw);
    final symbol = RegExp(r'[!@#\$%\^&*(),.?":{}|<>_\-\[\]\\/]').hasMatch(nw);
    if (!(upper && lower && digit && symbol)) {
      errorText.value = 'Password must include upper, lower, number, symbol';
      return;
    }
    if (nw != conf) {
      errorText.value = 'Passwords do not match';
      return;
    }
    if (cur == nw) {
      errorText.value = 'New password must differ from current';
      return;
    }

    if (isLoading.value) return;
    isLoading.value = true;

    // Reauthenticate
    final reauthFail = await repo.reauthenticateWithPassword(cur);
    if (reauthFail != null) {
      isLoading.value = false;
      errorText.value = _mapFailure(reauthFail);
      return;
    }

    // Update password
    final updateFail = await repo.updatePassword(nw);
    isLoading.value = false;
    if (updateFail != null) {
      errorText.value = _mapFailure(updateFail);
      return;
    }

    // Clear sensitive data
    currentPassword.text = '';
    newPassword.text = '';
    confirmPassword.text = '';

    // On success, sign out for security and require re-login (recommended)
    await repo.signOut();
    Get.back(result: 'password_changed');
  }

  String _mapFailure(AuthFailure f) {
    if (f is CredentialFailure) {
      switch (f.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Current password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts, please try later.';
        case 'requires-recent-login':
          return 'Please re-login and try again.';
        default:
          return f.message.isNotEmpty ? f.message : 'Authentication error';
      }
    }
    if (f is NetworkFailure) return 'Network error, check connection.';
    if (f is UnknownFailure) return 'Unexpected error occurred.';
    return 'Operation failed.';
  }

  @override
  void onClose() {
    displayNameController.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}
