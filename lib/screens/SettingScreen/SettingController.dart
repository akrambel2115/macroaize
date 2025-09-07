import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingController extends GetxController{

  final RxString appVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
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


  openPrivacy()
  async {
  final cfg = Get.find<AppConfigService>();
  final Uri url = Uri.parse(cfg.privacyLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  openTerms()
  async {
  final cfg = Get.find<AppConfigService>();
  final Uri url = Uri.parse(cfg.termsLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }


}