import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
	final bool isPremium;
	final String? planType; // monthly | yearly
	final DateTime? startDate;
	final DateTime? endDate;

	const Subscription({
		required this.isPremium,
		this.planType,
		this.startDate,
		this.endDate,
	});

  factory Subscription.fromFirestore(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is int) {
        final isSeconds = v.abs() < 1000000000000; // 1e12 ms threshold
        final ms = isSeconds ? v * 1000 : v;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toUtc();
      }
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      return null;
    }

    return Subscription(
      isPremium: data['isPremium'] == true,
      planType: data['planType']?.toString(),
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
    );
  }	bool get isActive {
		if (!isPremium) return false;
		if (endDate == null) return false;
		return endDate!.isAfter(DateTime.now().toUtc());
	}
}

