import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_failure.dart';

class AccountController extends GetxController {
  final AuthRepository repo;
  AccountController(this.repo);

  final isLoading = false.obs;
  final errorText = ''.obs;

  final displayNameController = TextEditingController();

  // password fields
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
    }
  }

  Future<void> changePassword() async {
  // client-side validation
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

  // reauthenticate
    final reauthFail = await repo.reauthenticateWithPassword(cur);
    if (reauthFail != null) {
      isLoading.value = false;
      errorText.value = _mapFailure(reauthFail);
      return;
    }

  // update password
    final updateFail = await repo.updatePassword(nw);
    isLoading.value = false;
    if (updateFail != null) {
      errorText.value = _mapFailure(updateFail);
      return;
    }

  // clear sensitive data
    currentPassword.text = '';
    newPassword.text = '';
    confirmPassword.text = '';

  // sign out after password change to require re-login
    await repo.signOut();
    Get.back(result: 'password_changed');
  }

  String _mapFailure(AuthFailure f) {
    if (f is CredentialFailure) {
      switch (f.code) {
        case 'wrong-password':
        case 'invalid-credential':
      return 'current_password_incorrect'.tr;
        case 'too-many-requests':
      return 'too_many_attempts'.tr;
        case 'requires-recent-login':
      return 'please_relogin'.tr;
        default:
      return f.message.isNotEmpty ? f.message : 'auth_authentication_error'.tr;
      }
    }
    if (f is NetworkFailure) return 'auth_network_error'.tr;
    if (f is UnknownFailure) return 'auth_unknown_error'.tr;
    return 'operation_failed'.tr;
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
