import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/influencer.dart';
import 'dart:async';

/// Exception for withdrawal-related errors with localization key
class WithdrawalException implements Exception {
  final String localizationKey;
  const WithdrawalException(this.localizationKey);

  @override
  String toString() => localizationKey;
}

/// Influencer service
class InfluencerService {
  InfluencerService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<Influencer?> get influencerStream {
    return _authAwareInfluencerStream();
  }

  Stream<Influencer?> _authAwareInfluencerStream() async* {
    await for (final user in FirebaseAuth.instance.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }

      yield* _firestore.collection('influencers').doc(user.uid).snapshots().map(
        (doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          return Influencer.fromFirestore(data);
        },
      );
    }
  }

  Future<bool> isInfluencer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc =
          await _firestore.collection('influencers').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<Influencer?> getInfluencerOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final doc = await _firestore.collection('influencers').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return Influencer.fromFirestore(data);
  }

  Future<PromoCodeValidationResult> validatePromoCode(String promoCode) async {
    // Promo validation is used during onboarding; ensure we have an authenticated
    // user (anonymous is fine) because the callable enforces auth.
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        throw const PromoCodeValidationException('please_relogin');
      }
    }
    if (user == null) {
      throw const PromoCodeValidationException('please_relogin');
    }

    final normalizedCode = promoCode.toUpperCase().trim();

    try {
      final callable = _functions.httpsCallable('validatePromoCode');
      final result = await callable.call({
        'promoCode': normalizedCode,
      });

      final data = result.data as Map<String, dynamic>;
      return PromoCodeValidationResult(
        valid: data['valid'] == true,
        discountRate: (data['discountRate'] as num?)?.toDouble() ?? 0.0,
        influencerId: data['influencerId']?.toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      final message = (e.message ?? '').toLowerCase();
      if (message.contains('unauthenticated')) {
        throw const PromoCodeValidationException('please_relogin');
      }
      if (message.contains('too many attempts') || message.contains('rate')) {
        throw const PromoCodeValidationException('too_many_attempts');
      }

      // Keep promo validation errors generic for security.
      throw const PromoCodeValidationException('Invalid promo code');
    } catch (e) {
      throw const PromoCodeValidationException('Invalid promo code');
    }
  }

  Future<WithdrawalResult> processWithdrawal(double amount, String rip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const WithdrawalException('auth_required');

    try {
      final callable = _functions.httpsCallable('processWithdrawal');
      final result = await callable.call({'amount': amount, 'rip': rip.trim()});

      final data = result.data as Map<String, dynamic>;
      return WithdrawalResult(
        success: data['success'] == true,
        withdrawalId: data['withdrawalId']?.toString(),
        message: data['message']?.toString() ?? 'Withdrawal processed',
      );
    } on FirebaseFunctionsException catch (e) {
      // Map Firebase error codes to user-friendly localization keys
      switch (e.code) {
        case 'unauthenticated':
          throw const WithdrawalException('auth_required');
        case 'permission-denied':
          throw const WithdrawalException('withdrawal_permission_denied');
        case 'invalid-argument':
          throw WithdrawalException(_mapInvalidArgument(e.message));
        case 'failed-precondition':
          // Insufficient balance
          throw const WithdrawalException('amount_exceeds_balance');
        case 'not-found':
          throw const WithdrawalException('withdrawal_permission_denied');
        case 'internal':
          // Server-side error - don't expose details to user
          throw const WithdrawalException('withdrawal_service_unavailable');
        default:
          throw const WithdrawalException('withdrawal_request_failed');
      }
    } catch (e) {
      // Catch-all for unexpected errors
      throw const WithdrawalException('withdrawal_request_failed');
    }
  }

  /// Maps invalid-argument error messages to localization keys
  String _mapInvalidArgument(String? message) {
    if (message == null) return 'withdrawal_request_failed';
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('amount')) return 'enter_valid_amount';
    if (lowerMessage.contains('rip') || lowerMessage.contains('20 digits')) return 'rip_invalid_format';
    if (lowerMessage.contains('minimum')) return 'withdrawal_minimum_not_met';
    if (lowerMessage.contains('insufficient') || lowerMessage.contains('balance')) return 'amount_exceeds_balance';
    return 'withdrawal_request_failed';
  }

  Future<AdminWithdrawalDetails> adminGetWithdrawalRip(
    String withdrawalId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    try {
      final callable = _functions.httpsCallable('adminGetWithdrawalRip');
      final result = await callable.call({'withdrawalId': withdrawalId.trim()});

      final data = result.data as Map<String, dynamic>;
      return AdminWithdrawalDetails(
        success: data['success'] == true,
        withdrawalId: data['withdrawalId']?.toString() ?? '',
        rip: data['rip']?.toString() ?? '',
        userId: data['userId']?.toString() ?? '',
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        status: data['status']?.toString() ?? 'unknown',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AdminActionResult> adminCompleteWithdrawal(
    String withdrawalId,
    String status,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    if (!['completed', 'failed'].contains(status)) {
      throw ArgumentError('Status must be either "completed" or "failed"');
    }

    try {
      final callable = _functions.httpsCallable('adminCompleteWithdrawal');
      final result = await callable.call({
        'withdrawalId': withdrawalId.trim(),
        'status': status,
      });

      final data = result.data as Map<String, dynamic>;
      return AdminActionResult(
        success: data['success'] == true,
        message: data['message']?.toString() ?? 'Action completed',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

class PromoCodeValidationResult {
  final bool valid;
  final double discountRate;
  final String? influencerId;

  const PromoCodeValidationResult({
    required this.valid,
    required this.discountRate,
    this.influencerId,
  });
}

class PromoCodeValidationException implements Exception {
  final String messageKey;
  const PromoCodeValidationException(this.messageKey);

  @override
  String toString() => messageKey;
}

class WithdrawalResult {
  final bool success;
  final String? withdrawalId;
  final String message;

  const WithdrawalResult({
    required this.success,
    this.withdrawalId,
    required this.message,
  });
}

class AdminWithdrawalDetails {
  final bool success;
  final String withdrawalId;
  final String rip;
  final String userId;
  final double amount;
  final String status;

  const AdminWithdrawalDetails({
    required this.success,
    required this.withdrawalId,
    required this.rip,
    required this.userId,
    required this.amount,
    required this.status,
  });
}

class AdminActionResult {
  final bool success;
  final String message;

  const AdminActionResult({required this.success, required this.message});
}
