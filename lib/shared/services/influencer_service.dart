import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/influencer.dart';
import 'dart:async';

class InfluencerService {
  InfluencerService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Real-time stream of the current user's influencer data.
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

  /// Check if current user is an influencer
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

  /// Get current user's influencer data once
  Future<Influencer?> getInfluencerOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final doc = await _firestore.collection('influencers').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return Influencer.fromFirestore(data);
  }

  /// Validate a promo code
  Future<PromoCodeValidationResult> validatePromoCode(String promoCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    try {
      final callable = _functions.httpsCallable('validatePromoCode');
      final result = await callable.call({
        'promoCode': promoCode.toUpperCase().trim(),
      });

      final data = result.data as Map<String, dynamic>;
      return PromoCodeValidationResult(
        valid: data['valid'] == true,
        discountRate: (data['discountRate'] as num?)?.toDouble() ?? 0.0,
        influencerId: data['influencerId']?.toString(),
      );
    } catch (e) {
      // Return generic error for security
      throw Exception('Invalid promo code or validation failed');
    }
  }

  /// Process a withdrawal request
  Future<WithdrawalResult> processWithdrawal(double amount, String rip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');

    try {
      final callable = _functions.httpsCallable('processWithdrawal');
      final result = await callable.call({'amount': amount, 'rip': rip.trim()});

      final data = result.data as Map<String, dynamic>;
      return WithdrawalResult(
        success: data['success'] == true,
        withdrawalId: data['withdrawalId']?.toString(),
        message: data['message']?.toString() ?? 'Withdrawal processed',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Admin only: Get decrypted RIP for a withdrawal
  /// Requires admin role in Firebase custom claims
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

  /// Admin only: Mark withdrawal as completed or failed
  /// Requires admin role in Firebase custom claims
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
  final String rip; // Decrypted RIP - only for admin use
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
