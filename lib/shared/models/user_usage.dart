import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';

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

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final cfg = Get.isRegistered<AppConfigService>() ? Get.find<AppConfigService>() : null;

    return UserUsage(
      scanCount: (data['scanCount'] as num?)?.toInt() ?? 0,
      chatCount: (data['chatCount'] as num?)?.toInt() ?? 0,
      lastUsageDate: parseDate(data['lastUsageDate']),
      scanLimit: _toInt(data['scanLimit']) != 0
          ? _toInt(data['scanLimit'])
          : (cfg?.freeScanLimit ?? 2),
      chatLimit: _toInt(data['chatLimit']) != 0
          ? _toInt(data['chatLimit'])
          : (cfg?.freeChatLimit ?? 5),
    );
  }

  int get remainingScans => (scanLimit - scanCount).clamp(0, scanLimit);

  int get remainingChats => (chatLimit - chatCount).clamp(0, chatLimit);

  bool get scanLimitReached => scanCount >= scanLimit;

  bool get chatLimitReached => chatCount >= chatLimit;

  bool get isToday {
    if (lastUsageDate == null) return false;
    final now = DateTime.now().toUtc();
    final usageDate = lastUsageDate!;
    return now.year == usageDate.year &&
           now.month == usageDate.month &&
           now.day == usageDate.day;
  }
}
