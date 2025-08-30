import 'package:cloud_firestore/cloud_firestore.dart';

class UserUsage {
  final int scanCount;
  final int chatCount;
  final DateTime? lastUsageDate;
  final int scanLimit;
  final int chatLimit;

  const UserUsage({
    required this.scanCount,
    required this.chatCount,
    this.lastUsageDate,
    this.scanLimit = 2,
    this.chatLimit = 5,
  });

  factory UserUsage.fromFirestore(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is DateTime) return v.toUtc();
      if (v is String) return DateTime.tryParse(v)?.toUtc();
      return null;
    }

    return UserUsage(
      scanCount: (data['scanCount'] as num?)?.toInt() ?? 0,
      chatCount: (data['chatCount'] as num?)?.toInt() ?? 0,
      lastUsageDate: parseDate(data['lastUsageDate']),
      scanLimit: 2, // Free tier limits
      chatLimit: 5,
    );
  }

  /// Returns remaining scans for today
  int get remainingScans => (scanLimit - scanCount).clamp(0, scanLimit);

  /// Returns remaining chats for today
  int get remainingChats => (chatLimit - chatCount).clamp(0, chatLimit);

  /// Check if scan limit has been reached
  bool get scanLimitReached => scanCount >= scanLimit;

  /// Check if chat limit has been reached
  bool get chatLimitReached => chatCount >= chatLimit;

  /// Check if this is usage from today
  bool get isToday {
    if (lastUsageDate == null) return false;
    final now = DateTime.now().toUtc();
    final usageDate = lastUsageDate!;
    return now.year == usageDate.year &&
           now.month == usageDate.month &&
           now.day == usageDate.day;
  }
}
