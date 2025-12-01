import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';
import 'dart:async';

class SubscriptionService {
	SubscriptionService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
			: _firestore = firestore ?? FirebaseFirestore.instance,
				_functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

	final FirebaseFirestore _firestore;
	final FirebaseFunctions _functions;

	// realtime subscription stream
  Stream<Subscription?> get subscriptionStream {
    return _authAwareSubscriptionStream();
  }

  Stream<Subscription?> _authAwareSubscriptionStream() async* {
    await for (final user in FirebaseAuth.instance.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }
      
      yield* _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data();
        if (data == null) return null;
        return Subscription.fromFirestore(data);
      });
    }
  }

  // create chargily checkout
  Future<Uri> createChargilyPayment({required String planType}) async {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null) {
			throw StateError('Not authenticated');
		}
		final callable = _functions.httpsCallable('createChargilyPayment');
		final res = await callable.call({'userId': user.uid, 'planType': planType});
		final data = res.data as Map;
		final url = data['checkoutUrl'] as String;
		return Uri.parse(url);
	}

  Future<Subscription?> getSubscriptionOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final doc = await _firestore.collection('subscriptions').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return Subscription.fromFirestore(data);
  }
}

