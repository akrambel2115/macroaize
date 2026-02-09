import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final bool isPremium;
  final String? planType; // monthly | yearly
  final DateTime? startDate;
  final DateTime? endDate;
  final String? provider;
  final String? status; // active | canceled | expired | past_due | ...
  final String? productId;
  final bool promoExtensionApplied;

  const Subscription({
    required this.isPremium,
    this.planType,
    this.startDate,
    this.endDate,
    this.provider,
    this.status,
    this.productId,
    this.promoExtensionApplied = false,
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

    DateTime? start = parseDate(data['startDate']);
    DateTime? end = parseDate(data['endDate']);
    final plan = data['planType']?.toString();

    // Adjust cases where end is missing or not after start (e.g., provider sent equal timestamps).
    if (start != null && (end == null || !end.isAfter(start))) {
      if (plan == 'yearly') {
        end = DateTime.utc(
          start.year + 1,
          start.month,
          start.day,
          start.hour,
          start.minute,
          start.second,
        );
      } else {
        end = DateTime.utc(
          start.year,
          start.month + 1,
          start.day,
          start.hour,
          start.minute,
          start.second,
        );
      }
    }

    return Subscription(
      isPremium: data['isPremium'] == true,
      planType: plan,
      startDate: start,
      endDate: end,
      provider: data['provider']?.toString(),
      status: data['status']?.toString(),
      productId: data['productId']?.toString(),
      promoExtensionApplied: data['promoExtensionApplied'] == true,
    );
  }

  bool get isActive {
    if (!isPremium) return false;
    if (endDate == null) return false;
    return endDate!.isAfter(DateTime.now().toUtc());
  }
}
