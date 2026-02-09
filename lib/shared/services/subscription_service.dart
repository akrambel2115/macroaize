import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';
import 'dart:async';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // realtime subscription stream combining Firestore + Local RevenueCat
  Stream<Subscription?> get subscriptionStream {
    return _authAwareSubscriptionStream();
  }

  Stream<Subscription?> _authAwareSubscriptionStream() {
    return FirebaseAuth.instance.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null);
      }

      // 1. Firestore Stream
      final firestoreStream = _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .snapshots()
          .map(
            (doc) =>
                doc.exists ? Subscription.fromFirestore(doc.data()!) : null,
          );

      // 2. Local RevenueCat Stream
      final rcStream = Stream<CustomerInfo>.multi((controller) {
        Purchases.addCustomerInfoUpdateListener((info) {
          controller.add(info);
        });
        // Emit initial value
        Purchases.getCustomerInfo()
            .then((info) => controller.add(info))
            .catchError((_) {});
      });

      // Combine: Prefer Firestore if valid, fallback to RC if FS is expired/null but RC is active
      return Rx.combineLatest2<Subscription?, CustomerInfo, Subscription?>(
        firestoreStream,
        rcStream,
        (fsSub, rcInfo) {
          final fsActive = fsSub?.isActive == true;
          if (fsActive) return fsSub;

          // Check local entitlements
          final rcActive = rcInfo.entitlements.active.isNotEmpty;
          if (rcActive) {
            // Synthesize active subscription from local data
            final ent = rcInfo.entitlements.active.values.first;
            return Subscription(
              isPremium: true,
              planType:
                  ent.productIdentifier.contains('year') ? 'yearly' : 'monthly',
              startDate: DateTime.tryParse(ent.latestPurchaseDate)?.toUtc(),
              endDate: DateTime.tryParse(ent.expirationDate ?? '')?.toUtc(),
              provider: 'revenuecat_local',
              status: 'active',
              productId: ent.productIdentifier,
            );
          }

          return fsSub;
        },
      );
    });
  }

  Future<Subscription?> getSubscriptionOnce() async {
    // Try local RC first for immediate check
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.isNotEmpty) {
        final ent = info.entitlements.active.values.first;
        return Subscription(
          isPremium: true,
          planType:
              ent.productIdentifier.contains('year') ? 'yearly' : 'monthly',
          startDate: DateTime.tryParse(ent.latestPurchaseDate)?.toUtc(),
          endDate: DateTime.tryParse(ent.expirationDate ?? '')?.toUtc(),
          provider: 'revenuecat_local',
          status: 'active',
          productId: ent.productIdentifier,
        );
      }
    } catch (_) {}

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('subscriptions').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return Subscription.fromFirestore(data);
  }
}
