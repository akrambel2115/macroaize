import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/auth/presentation/account_controller.dart';
import '../../widgets/password_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final AccountController controller;
  const ChangePasswordScreen({required this.controller, super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final AccountController controller;
  final _formKey = GlobalKey<FormState>();
  // Password fields are obscured by default; eye toggles match login/register
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
  // No per-keystroke listeners to avoid rebuilds; validation happens on submit.
  }
  @override
  void dispose() {
  // No listeners to remove
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
  title: Text('change_password'.tr, style: theme.textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                PasswordField(
                  controller: controller.currentPassword,
                  label: 'current_password_label'.tr,
                  validator: (v) => (v == null || v.isEmpty) ? 'required'.tr : null,
                  autofocus: false,
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: controller.newPassword,
                  label: 'new_password_label'.tr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'required'.tr;
                    if (v.length < 8) return 'min_8_chars'.tr;
                    final upper = RegExp(r'[A-Z]').hasMatch(v);
                    final lower = RegExp(r'[a-z]').hasMatch(v);
                    final digit = RegExp(r'\d').hasMatch(v);
                    final symbol = RegExp(r'[!@#\$%\^&*(),.?":{}|<>_\-\[\]\\\/]').hasMatch(v);
                    if (!(upper && lower && digit && symbol)) return 'password_complexity_hint'.tr;
                    if (v == controller.currentPassword.text) return 'must_differ_from_current'.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: controller.confirmPassword,
                  label: 'confirm_new_password_label'.tr,
                  validator: (v) => (v != controller.newPassword.text) ? 'does_not_match'.tr : null,
                ),
                const SizedBox(height: 18),
                Obx(() => Text(
                      controller.errorText.value,
                      style: TextStyle(color: theme.colorScheme.error),
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('cancel'.tr),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final loading = controller.isLoading.value;
                      // Button is enabled unless a request is in progress. Validation is
                      // performed when the user taps the button (same pattern as register).
                      final enabled = !loading;
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: enabled ? 1.0 : 0.6,
                        child: TextButton(
                          onPressed: enabled
                              ? () async {
                                  // Validate on press (not during build)
                                  if (!(_formKey.currentState?.validate() ?? false)) {
                                    controller.errorText.value = 'please_fix_errors'.tr;
                                    return;
                                  }
                                  await controller.changePassword();
                                }
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: enabled ? Colors.green : Colors.green.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: loading
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                              : Text('change_password_cta'.tr),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
