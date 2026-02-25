import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';
import 'dart:async';

/// Service to handle promo code storage and post-login validation
class PromoCodeService {
  static final PromoCodeService _instance = PromoCodeService._internal();
  factory PromoCodeService() => _instance;
  PromoCodeService._internal();

  StreamSubscription<User?>? _authSubscription;
  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Initialize the service - listens for auth state changes
  void initialize() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  /// Store a promo code locally during onboarding (no validation)
  Future<void> storePendingPromoCode(String code) async {
    final normalized = code.toUpperCase().trim();
    await SharedPref.saveString(SharePrefKey.pendingPromoCode, normalized);
  }

  /// Get the pending promo code
  Future<String?> getPendingPromoCode() async {
    final code = await SharedPref.readString(SharePrefKey.pendingPromoCode);
    return code.isNotEmpty ? code : null;
  }

  /// Clear pending promo code
  Future<void> clearPendingPromoCode() async {
    await SharedPref.remove(SharePrefKey.pendingPromoCode);
  }

  /// Check if promo code is already activated
  Future<bool> isPromoCodeActivated() async {
    return await SharedPref.readBool(SharePrefKey.promoCodeActivated) ?? false;
  }

  /// Get activated promo code
  Future<String?> getActivatedPromoCode() async {
    final code = await SharedPref.readString(SharePrefKey.activatedPromoCode);
    return code.isNotEmpty ? code : null;
  }

  /// Called when auth state changes - validate pending promo if user signs in
  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null || user.isAnonymous) return;

    // User is authenticated (non-anonymous) - check for pending promo
    final pending = await getPendingPromoCode();
    if (pending == null || pending.isEmpty) return;

    // Already activated? Skip
    final alreadyActivated = await isPromoCodeActivated();
    if (alreadyActivated) return;

    // Try to validate and activate
    await _validateAndActivatePendingPromo(pending);
  }

  /// Validate pending promo code with Firebase and activate if valid.
  Future<void> _validateAndActivatePendingPromo(String code) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // First validate the promo code
        final validateResult = await _functions
            .httpsCallable('validatePromoCode')
            .call({'promoCode': code});

        final data = validateResult.data as Map<String, dynamic>;
        final isValid = data['valid'] == true;

        if (isValid) {
          // Promo is valid - store it for the user
          await _functions.httpsCallable('storePromoCodeForPurchase').call({
            'promoCode': code,
          });

          // Mark as activated
          await SharedPref.saveBool(SharePrefKey.promoCodeActivated, true);
          await SharedPref.saveString(SharePrefKey.activatedPromoCode, code);
        }

        // Clear pending promo on definitive result (valid or invalid)
        await clearPendingPromoCode();
        return;
      } catch (_) {
        // On last attempt, keep the pending code so it can be retried on next login
        if (attempt >= maxRetries) {
          // Don't clear — leave pending so next auth state change retries
          return;
        }
        // Exponential backoff before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
}
