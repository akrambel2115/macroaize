import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/gestures.dart';

import '../data/firebase_auth_repository.dart';
import '../data/auth_service.dart';
import 'auth_controller.dart';
import 'auth_theme.dart';
import '../../../shared/services/notification_service.dart';
import '../../../widgets/app_widgets.dart';
import 'package:macroaize/shared/services/app_config_service.dart';

class AuthModal extends StatelessWidget {
  final bool isFullScreen;
  const AuthModal({super.key, this.isFullScreen = false});

  static Future<bool> show() async {
    final repo = FirebaseAuthRepository();
    Get.put(AuthController(repo), tag: 'auth');
    // open full-screen auth
    final res = await Get.to<bool?>(() => const AuthModal(isFullScreen: true));
    // if controller set a success key, show it after the screen closes
    final controller =
        Get.isRegistered<AuthController>(tag: 'auth')
            ? Get.find<AuthController>(tag: 'auth')
            : null;
    final successKey = controller?.lastSuccessKey.value ?? '';
    // delete controller after current frame to avoid dispose timing issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>(tag: 'auth')) {
        Get.delete<AuthController>(tag: 'auth', force: true);
      }
    });
    if (res == true) {
      // persist legacy login flag
      await AuthService.syncLoginFlag();
    }
    if (successKey.isNotEmpty) {
      NotificationService.showSuccess(successKey);
    }
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // For full screen presentation we avoid rounded top corners and use scaffold background
    final content = DefaultTabController(
      length: 2,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            if (!isFullScreen) ...[
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'auth_modal_title'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TabBar(
              tabs: [Tab(text: 'login'.tr), Tab(text: 'register'.tr)],
              labelStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Builder(
              builder: (context) {
                // compute available height (account for keyboard) and clamp
                final media = MediaQuery.of(context);
                final screenH = media.size.height;
                final keyboardH = media.viewInsets.bottom;
                final availableH = (screenH - keyboardH).clamp(360.0, screenH);
                // use up to 85% of available height for the modal body
                final double bodyHeight = (availableH * 0.85).clamp(
                  360.0,
                  720.0,
                );

                return SizedBox(
                  height: bodyHeight,
                  child: TabBarView(children: [_LoginTab(), _RegisterTab()]),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text('auth_modal_title'.tr),
          leading: AppWidgets.backButton(context, () => Get.back()),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
              return SingleChildScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - keyboardHeight,
                  ),
                  child: IntrinsicHeight(child: content),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration:
          isFullScreen
              ? BoxDecoration(color: theme.scaffoldBackgroundColor)
              : BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
      child: content,
    );
  }
}

class _LoginTab extends GetView<AuthController> {
  const _LoginTab();

  @override
  String? get tag => 'auth';

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: c.loginKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: c.email,
                decoration: modernInput(
                  'email'.tr,
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: c.validateEmail,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextFormField(
                  controller: c.password,
                  decoration: modernInput(
                    'password'.tr,
                    errorStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ).copyWith(
                    suffixIcon:
                        c.showPasswordEye.value
                            ? IconButton(
                              icon: Icon(
                                c.loginObscure.value
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                color: Colors.orange,
                              ),
                              onPressed: () => c.toggleLoginObscure(),
                            )
                            : null,
                  ),
                  obscureText: c.loginObscure.value,
                  validator: c.validatePassword,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => c.resetPassword(),
                  child: Text('forgot_password'.tr),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  c.errorText.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => FilledButton(
                  onPressed:
                      c.isLoading.value
                          ? null
                          : () async {
                            // validate on press
                            if (!(c.loginKey.currentState?.validate() ??
                                false)) {
                              c.errorText.value = 'please_fix_errors'.tr;
                              return;
                            }
                            final user = await c.loginEmail();
                            if (user != null) Get.back(result: true);
                          },
                  style: modernFilledButton(context),
                  child:
                      c.isLoading.value
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text('login'.tr),
                ),
              ),
              const SizedBox(height: 12),
              const _SocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterTab extends GetView<AuthController> {
  const _RegisterTab();

  @override
  String? get tag => 'auth';

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: c.registerKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: c.firstName,
                      decoration: modernInput(
                        'first_name'.tr,
                        errorStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                      validator: c.validateName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: c.lastName,
                      decoration: modernInput(
                        'last_name'.tr,
                        errorStyle: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                      validator: c.validateName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: c.email,
                decoration: modernInput(
                  'Email',
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: c.validateEmail,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextFormField(
                  controller: c.password,
                  decoration: modernInput(
                    'password'.tr,
                    errorStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ).copyWith(
                    suffixIcon:
                        c.showPasswordEye.value
                            ? IconButton(
                              icon: Icon(
                                c.registerPasswordObscure.value
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                color: Colors.orange,
                              ),
                              onPressed:
                                  () => c.toggleRegisterPasswordObscure(),
                            )
                            : null,
                  ),
                  obscureText: c.registerPasswordObscure.value,
                  validator: c.validatePassword,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => TextFormField(
                  controller: c.confirmPassword,
                  decoration: modernInput(
                    'confirm_password'.tr,
                    errorStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ).copyWith(
                    suffixIcon:
                        c.showConfirmEye.value
                            ? IconButton(
                              icon: Icon(
                                c.registerConfirmObscure.value
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                color: Colors.orange,
                              ),
                              onPressed: () => c.toggleRegisterConfirmObscure(),
                            )
                            : null,
                  ),
                  obscureText: c.registerConfirmObscure.value,
                  validator: c.validateConfirm,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final base = (theme.textTheme.bodySmall ?? const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    );
                final linkStyle = base.copyWith(
                  decoration: TextDecoration.underline,
                  color: theme.colorScheme.primary,
                );
                final recognizer =
                    TapGestureRecognizer()
                      ..onTap = () async {
                        final uri = Uri.parse(
                          Get.find<AppConfigService>().termsLink,
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      };
                return InkWell(
                  onTap: () => c.tosAccepted.value = !c.tosAccepted.value,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: c.tosAccepted.value,
                        onChanged: (v) => c.tosAccepted.value = v ?? false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'by_registering_agree'.tr,
                                style: base,
                              ),
                              TextSpan(
                                text: 'terms_of_service'.tr,
                                style: linkStyle,
                                recognizer: recognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  c.errorText.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => FilledButton(
                  onPressed:
                      c.isLoading.value
                          ? null
                          : () async {
                            // Validate on press
                            if (!(c.registerKey.currentState?.validate() ??
                                false)) {
                              c.errorText.value = 'please_fix_errors'.tr;
                              return;
                            }
                            if (!c.tosAccepted.value) {
                              c.errorText.value = 'accept_terms_of_service'.tr;
                              return;
                            }
                            final user = await c.registerEmail();
                            if (user != null) {
                              Get.back(result: true);
                              // navigate to email verification screen
                              Get.offAllNamed('/EmailVerificationView');
                            }
                          },
                  style: modernFilledButton(context),
                  child:
                      c.isLoading.value
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text('register'.tr),
                ),
              ),
              const SizedBox(height: 12),
              const _SocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButtons extends GetView<AuthController> {
  const _SocialButtons();
  @override
  String? get tag => 'auth';

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      // ensure reactive reads are inside Obx
      final loading = c.isLoading.value;
      return Column(
        children: [
          OutlinedButton.icon(
            icon: const Icon(
              FontAwesomeIcons.google,
              size: 18,
              color: Colors.redAccent,
            ),
            label: Text('continue_with_google'.tr),
            style: modernOutlinedButton(context),
            onPressed:
                loading
                    ? null
                    : () async {
                      final user = await c.google();
                      if (user != null) Get.back(result: true);
                    },
          ),
          const SizedBox(height: 8),
          if (Platform.isIOS)
            FutureBuilder<bool>(
              future: SignInWithApple.isAvailable(),
              builder: (context, snapshot) {
                final available = snapshot.data ?? false;
                if (!available) return const SizedBox.shrink();
                return Column(
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(
                        FontAwesomeIcons.apple,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      label: Text('continue_with_apple'.tr),
                      style: modernOutlinedButton(context),
                      onPressed:
                          loading
                              ? null
                              : () async {
                                final user = await c.apple();
                                if (user != null) Get.back(result: true);
                              },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
        ],
      );
    });
  }
}
