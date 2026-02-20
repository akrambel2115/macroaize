import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:macroaize/features/auth/presentation/auth_modal.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/widgets/modern_button.dart';

/// A view that requires user to be logged in before proceeding to promo code step.
/// If user is already logged in, they can continue directly.
/// If not, they must login/register first.
class AuthRequiredView extends StatefulWidget {
  const AuthRequiredView({super.key});

  @override
  State<AuthRequiredView> createState() => _AuthRequiredViewState();
}

class _AuthRequiredViewState extends State<AuthRequiredView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User already logged in - proceed directly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleContinue();
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    final success = await AuthModal.show();
    if (success) {
      // Login successful - proceed directly to next step
      _handleContinue();
    }
  }

  void _handleContinue() {
    final controller = Get.find<SignUpController>();
    controller.onChangeView();
  }

  void _handleSkip() {
    // Skip login but show promo code page
    final controller = Get.find<SignUpController>();
    controller.skipToPromoCode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'auth_required_title'.tr,
          style: theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20),

        // Description
        Text(
          'auth_required_desc'.tr,
          style: theme.textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 10),

        const Spacer(),

        // Lottie animation in the middle
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Lottie.asset(
              'assets/lottie/login.json',
              fit: BoxFit.contain,
            ),
          ),
        ),

        const Spacer(),

        // Main action button - same style as other steps
        ModernButton(
          text: 'login_or_register'.tr,
          onPressed: _handleLogin,
          style: ModernButtonStyle.primary,
          size: ModernButtonSize.medium,
          borderRadius: BorderRadius.circular(30),
          icon: const Icon(Icons.login_rounded, color: Colors.white),
          height: 50,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        // Skip option - shown under button
        Center(
          child: TextButton(
            onPressed: _handleSkip,
            child: Text(
              'skip_for_now'.tr,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
