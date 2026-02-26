import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/shared/services/wellness_sync_service.dart';

import 'package:macroaize/shared/services/app_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingController extends GetxController {
  final RxString appVersion = ''.obs;

  WellnessSyncService? get wellnessOrNull =>
      Get.isRegistered<WellnessSyncService>()
          ? Get.find<WellnessSyncService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    if (wellnessOrNull != null) {
      wellnessOrNull!.refreshStatus();
    }
  }

  Future<void> connectWellness() async {
    final service = wellnessOrNull;
    if (service == null) return;
    final ok = await service.connect();
    if (ok) {
      NotificationService.showSuccess('Connected to wellness platform');
    } else {
      NotificationService.showInfo(service.statusMessage.value);
    }
  }

  Future<void> disconnectWellness() async {
    final service = wellnessOrNull;
    if (service == null) return;
    await service.disconnect();
    NotificationService.showInfo('Wellness disconnected');
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.trim();
      final b = info.buildNumber.trim();
      appVersion.value = b.isNotEmpty ? '$v+$b' : v;
    } catch (_) {
      appVersion.value = 'unknown';
    }
  }

  openPrivacy() async {
    final cfg = Get.find<AppConfigService>();
    final Uri url = Uri.parse(cfg.privacyLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  openTerms() async {
    final cfg = Get.find<AppConfigService>();
    final Uri url = Uri.parse(cfg.termsLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
