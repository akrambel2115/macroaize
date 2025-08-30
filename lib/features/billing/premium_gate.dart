import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PremiumGate extends StatelessWidget {
  const PremiumGate({super.key, required this.builder, this.placeholder});
  final Widget Function(bool isPremium) builder;
  final Widget? placeholder;

  bool _isPremium(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['isPremium'] != true) return false;
    final end = DateTime.tryParse(data['endDate']?.toString() ?? '');
    if (end == null) return false;
    return end.isAfter(DateTime.now().toUtc());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return builder(false);
    final ref = FirebaseFirestore.instance.collection('subscriptions').doc(user.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return placeholder ?? const SizedBox.shrink();
        return builder(_isPremium(snapshot.data!.data()));
      },
    );
  }
}
