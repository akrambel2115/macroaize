import 'package:cloud_firestore/cloud_firestore.dart';

class Influencer {
  final String promoCode;
  final DateTime? expirationDate;
  final double earningsDzd;
  final double totalEarningsDzd;
  final int usersCount;
  final double minWithdrawal;
  final bool isActive;
  final List<WithdrawalRecord> withdrawHistory;

  const Influencer({
    required this.promoCode,
    this.expirationDate,
    required this.earningsDzd,
    required this.totalEarningsDzd,
    required this.usersCount,
    required this.minWithdrawal,
    required this.isActive,
    required this.withdrawHistory,
  });

  factory Influencer.fromFirestore(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      return null;
    }

    List<WithdrawalRecord> parseWithdrawHistory(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v
            .map((item) {
              if (item is Map<String, dynamic>) {
                return WithdrawalRecord.fromMap(item);
              }
              return null;
            })
            .where((item) => item != null)
            .cast<WithdrawalRecord>()
            .toList();
      }
      return [];
    }

    return Influencer(
      promoCode: data['promoCode']?.toString() ?? '',
      expirationDate: parseDate(data['expirationDate']),
      earningsDzd: (data['earningsDzd'] as num?)?.toDouble() ?? 0.0,
      totalEarningsDzd: (data['totalEarningsDzd'] as num?)?.toDouble() ?? 0.0,
      usersCount: (data['usersCount'] as num?)?.toInt() ?? 0,
      minWithdrawal: (data['minWithdrawal'] as num?)?.toDouble() ?? 2000.0,
      isActive: data['isActive'] == true,
      withdrawHistory: parseWithdrawHistory(data['withdrawHistory']),
    );
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now().toUtc());
  }

  bool get canWithdraw {
    return isActive && earningsDzd >= minWithdrawal;
  }

  Duration? get timeUntilExpiry {
    if (expirationDate == null || isExpired) return null;
    return expirationDate!.difference(DateTime.now().toUtc());
  }
}

class WithdrawalRecord {
  final String id;
  final double amount;
  final String ripLast4;
  final DateTime? requestedAt;
  final String status;
  final String? estimatedProcessingDate;

  const WithdrawalRecord({
    required this.id,
    required this.amount,
    required this.ripLast4,
    this.requestedAt,
    required this.status,
    this.estimatedProcessingDate,
  });

  factory WithdrawalRecord.fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      return null;
    }

    return WithdrawalRecord(
      id: data['id']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      ripLast4: data['ripLast4']?.toString() ?? '',
      requestedAt: parseDate(data['requestedAt']),
      status: data['status']?.toString() ?? 'unknown',
      estimatedProcessingDate: data['estimatedProcessingDate']?.toString(),
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}

