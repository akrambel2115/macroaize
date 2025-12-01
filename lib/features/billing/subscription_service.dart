import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<DocumentSnapshot<Map<String, dynamic>>> subscribeAndWatch({required String planType}) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final callable = _functions.httpsCallable('createChargilyPayment');
    final res = await callable.call({
      'userId': user.uid,
      'planType': planType,
    });

    final url = (res.data is Map && (res.data['checkoutUrl'] is String)) ? res.data['checkoutUrl'] as String : (res.data as Map)['checkoutUrl'] as String;

    // return stream of subscription doc, ui can open the url and listen for changes separately
    yield* _firestore.collection('subscriptions').doc(user.uid).snapshots();
  }

  Stream<Map<String, dynamic>?> watchSubscription() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('subscriptions').doc(user.uid).snapshots().map((s) => s.data());
  }

  static bool isActive(Map<String, dynamic>? sub) {
    if (sub == null) return false;
    if (sub['isPremium'] != true) return false;
    final end = DateTime.tryParse(sub['endDate']?.toString() ?? '');
    if (end == null) return false;
    return end.isAfter(DateTime.now().toUtc());
  }
}
