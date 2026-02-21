import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/shared/services/influencer_service.dart';
import 'package:macroaize/shared/services/promo_code_service.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/modern_button.dart';

import 'package:lottie/lottie.dart';

class PromoCodeView extends StatefulWidget {
  const PromoCodeView({super.key});

  @override
  State<PromoCodeView> createState() => _PromoCodeViewState();
}

class _PromoCodeViewState extends State<PromoCodeView> {
  final SignUpController _controller = Get.find<SignUpController>();
  final InfluencerService _influencerService = InfluencerService();
  final TextEditingController _promoController = TextEditingController();

  bool _isValidating = false;
  bool _isValid = false;
  bool _isLinked =
      false; // Promo code has been linked to account (cannot be changed)
  String? _errorMessageKey;

  /// Check if user is logged in (non-anonymous)
  bool get _isUserLoggedIn {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous;
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _clearErrorAndValidity() {
    // Don't allow clearing if already linked
    if (_isLinked) return;

    if (_errorMessageKey != null || _isValid) {
      setState(() {
        _errorMessageKey = null;
        _isValid = false;
      });
    }
  }

  Future<void> _validatePromo() async {
    if (_isValidating || _isLinked) return;

    final code = _promoController.text.toUpperCase().trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessageKey = 'Please enter a promo code';
        _isValid = false;
      });
      return;
    }

    // Check if user is logged in (non-anonymous)
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;

    if (isLoggedIn) {
      // User is logged in - validate with Firebase
      await _validateWithFirebase(code);
    } else {
      // User not logged in - store locally without validation
      await _storePromoLocally(code);
    }
  }

  /// Validate promo code with Firebase (when user is logged in)
  Future<void> _validateWithFirebase(String code) async {
    setState(() {
      _isValidating = true;
      _errorMessageKey = null;
    });

    try {
      final result = await _influencerService.validatePromoCode(code);
      if (!mounted) return;

      if (result.valid) {
        // Promo code is valid - now link it to user's account via Cloud Function
        try {
          final functions = FirebaseFunctions.instanceFor(
            region: 'europe-west1',
          );
          await functions.httpsCallable('storePromoCodeForPurchase').call({
            'promoCode': code,
          });

          if (!mounted) return;

          // Successfully linked to account
          setState(() {
            _isValidating = false;
            _isValid = true;
            _isLinked = true; // Mark as linked - cannot be changed
            _errorMessageKey = null;
          });
          _controller.promoCode = code;
          _controller.update();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isValidating = false;
            _isValid = false;
            _errorMessageKey = 'Failed to link promo code. Please try again.';
          });
        }
      } else {
        setState(() {
          _isValidating = false;
          _isValid = false;
          _errorMessageKey = 'Invalid promo code';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isValidating = false;
        _isValid = false;
        if (e is PromoCodeValidationException) {
          _errorMessageKey = e.messageKey;
        } else {
          _errorMessageKey = 'Invalid promo code';
        }
      });
    }
  }

  /// Store promo code locally without validation (when user is not logged in)
  Future<void> _storePromoLocally(String code) async {
    setState(() => _isValidating = true);

    try {
      await PromoCodeService().storePendingPromoCode(code);

      if (!mounted) return;

      // Success - show as valid (will be validated after sign-in)
      setState(() {
        _isValidating = false;
        _isValid = true;
        _isLinked = true; // Lock the field
        _errorMessageKey = null;
      });
      _controller.promoCode = code;
      _controller.update();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _isValid = false;
        _errorMessageKey = 'Failed to save promo code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'promo_code_title'.tr,
          textAlign: TextAlign.center,
          style: context.theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).paddingOnly(top: 20),

        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lottie animation
                Lottie.asset(
                  'assets/lottie/gift.json',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  repeat: true,
                ),

                const SizedBox(height: 28),

                // Playful subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Enter your code below to unlock',
                      textAlign: TextAlign.center,
                      style: context.theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color:
                          _isLinked
                              ? Colors.grey.withValues(alpha: 0.1)
                              : context.theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _promoController,
                      enabled: !_isLinked, // Disable if linked
                      style: TextStyle(
                        color:
                            _isLinked
                                ? Colors.grey
                                : context.theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ENTER CODE'.tr,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.normal,
                          letterSpacing: 0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        suffixIcon:
                            _isValid
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : null,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      onChanged: (_) => _clearErrorAndValidity(),
                    ),
                  ),

                  if (_errorMessageKey != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _errorMessageKey!.tr,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],

                  // Green success box - only show when logged in
                  if (_isValid && _isUserLoggedIn) ...[
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'promo_code_linked_success'.tr,
                              style: context.theme.textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Only show validate button if not linked yet
                  if (!_isLinked)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ModernButton(
                        text: 'Validate Code'.tr,
                        onPressed: _isValidating ? null : _validatePromo,
                        style: ModernButtonStyle.secondary,
                        size: ModernButtonSize.medium,
                        borderRadius: BorderRadius.circular(30),
                        height: 50,
                        icon:
                            _isValidating
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                    ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        Row(
          children: [
            // Only show Previous button if promo is not linked
            if (!_isLinked)
              Expanded(
                child: ModernButton(
                  text: 'Previous'.tr,
                  onPressed: () {
                    _controller.selectedView = 6; // Go back to AuthRequiredView
                    _controller.update();
                  },
                  style: ModernButtonStyle.secondary,
                  size: ModernButtonSize.medium,
                  borderRadius: BorderRadius.circular(30),
                  height: 50,
                ),
              ),
            if (!_isLinked) const SizedBox(width: 10),
            Expanded(
              child: ModernButton(
                text: 'Continue'.tr,
                onPressed: () => _controller.onChangeView(),
                style: ModernButtonStyle.primary,
                size: ModernButtonSize.medium,
                borderRadius: BorderRadius.circular(30),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                height: 50,
              ),
            ),
          ],
        ).paddingOnly(bottom: 20, left: 20, right: 20),
      ],
    );
  }
}
