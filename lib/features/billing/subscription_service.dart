import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
