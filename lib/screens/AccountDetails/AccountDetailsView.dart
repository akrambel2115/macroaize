import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/services/notification_service.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/presentation/account_controller.dart';
import '../../widgets/VerifyEmailButton.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'change_password_screen.dart';

const Color _kAccent = Color(0xFFFF6B35);

class AccountDetailsView extends StatelessWidget {
  const AccountDetailsView({super.key});

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // Controller
    final repo = FirebaseAuthRepository();
    final acct = Get.put(AccountController(repo), tag: 'account');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'account_details_title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          // Verify Email badge in top-right corner
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: VerifyEmailButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (ctx, snapshot) {
            final liveUser = snapshot.data ?? user;
            return Column(
              children: [
                const SizedBox(height: 8),
                // Avatar
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF4A90E2),
                  child: Text(
                    _initials(liveUser?.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  liveUser?.displayName ?? 'no_name'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  liveUser?.email ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 18),

            // Modern card-based details (clean, spaced, editable)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Row (label only)
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'name_label'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Gap adjusted to 8px
                    // Display name with the edit icon immediately after the name (small gap)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        // Name text — will wrap naturally if long
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          child: Text(
                            liveUser?.displayName ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey[800],
                            ),
                            softWrap: true,
                          ),
                        ),
                        // Small, compact edit icon placed directly after the name
                        GestureDetector(
                          onTap: () async {
                            final res = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              builder:
                                  (ctx) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(ctx).viewInsets.bottom,
                                    ),
                                    child: _EditDisplayNameSheet(
                                      controller: acct,
                                    ),
                                  ),
                            );
                            if (res == true) {
                              NotificationService.showSuccess(
                                'display_name_updated'.tr,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email Row
                    Row(
                      children: [
                        Icon(Icons.email, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'email_label'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      liveUser?.email ?? '-',
                      style: TextStyle(
                        fontSize: 13,
            color: theme.brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Change Password Button (secondary) — only for email/password accounts
                    Builder(
                      builder: (context) {
                        final hasPasswordProvider =
                            liveUser?.providerData.any(
                              (p) => p.providerId == 'password',
                            ) ??
                            false;
                        if (!hasPasswordProvider) {
                          return const SizedBox.shrink();
                        }
                        return Center(
                          child: TextButton(
                            onPressed: () async {
                              // Navigate to a full-screen Change Password page
                              final res = await Get.to<String?>(
                                () => ChangePasswordScreen(controller: acct),
                              );
                              if (res == 'password_changed') {
                                NotificationService.showSuccess(
                                  'password_changed_message'.tr,
                                );
                                Get.offAllNamed('/login');
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _kAccent,
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? AppColor.darkCard
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _kAccent.withOpacity(0.25),
                                ),
                              ),
                            ),
                            child: Text(
                              'change_password'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logout button — prominent
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Get.back();
                    NotificationService.showSuccess('auth_logout_success');
                  } catch (e) {
                    NotificationService.showError('auth_logout_failed');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: _kAccent.withOpacity(0.3),
                  elevation: 6,
                ),
                child: Text(
                  'logout'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      ),
    ),
  );
  }
}

// --- Edit Display Name Sheet ---
class _EditDisplayNameSheet extends StatefulWidget {
  final AccountController controller;
  const _EditDisplayNameSheet({required this.controller});

  @override
  State<_EditDisplayNameSheet> createState() => _EditDisplayNameSheetState();
}

class _EditDisplayNameSheetState extends State<_EditDisplayNameSheet> {
  late final AccountController controller;
  late final String initialNormalized;
  bool isValid = false;
  final _formKey = GlobalKey<FormState>();

  static String _normalize(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    final initial = FirebaseAuth.instance.currentUser?.displayName ?? '';
    initialNormalized = _normalize(initial);
    controller.displayNameController.text = initial;
    controller.displayNameController.addListener(_onChange);
    // Defer initial validation to after first frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChange());
  }

  String? _validateNameField(String? v) {
    final raw = _normalize(v ?? '');
    if (raw.isEmpty) return 'required'.tr;
    if (raw.length < 2) return 'too_short'.tr;
    if (raw.length > 50) return 'too_long'.tr;
    return null;
  }

  void _onChange() {
    final raw = _normalize(controller.displayNameController.text);
    final ok = (_validateNameField(raw) == null) && raw != initialNormalized;
    if (ok != isValid) setState(() => isValid = ok);
  }

  @override
  void dispose() {
    controller.displayNameController.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // local accent is available as _kAccent
    // Wrap content in a scroll view so the sheet can shrink when the keyboard is open
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('edit_display_name'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: controller.displayNameController,
                decoration: InputDecoration(
                  labelText: 'new_display_name'.tr,
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: _validateNameField,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text('cancel'.tr),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final loading = controller.isLoading.value;
                  final enabled = isValid && !loading;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: enabled ? 1.0 : 0.6,
                    child: TextButton(
                      onPressed:
                          enabled
                              ? () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  await controller.updateDisplayName();
                                }
                              }
                              : null,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            enabled
                                ? Colors.green
                                : Colors.green.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              )
                              : Text('save'.tr),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ChangePasswordScreen moved to separate file 'change_password_screen.dart'
