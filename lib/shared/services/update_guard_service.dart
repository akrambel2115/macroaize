import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config_service.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

/// Enforces minimum app version with a blocking update dialog
class UpdateGuardService extends GetxService {
  Future<void> enforceMinimumVersion() async {
    try {
      final config = Get.find<AppConfigService>();

      final PackageInfo info = await PackageInfo.fromPlatform();
      final current = info.version.trim();
      final required = config.minRequiredAppVersion.trim();

      if (_isOutdated(current, required)) {
        final message = config.updateMessage;
        final storeUrl =
            Platform.isIOS
                ? (config.appStoreUrl.isNotEmpty
                    ? config.appStoreUrl
                    : config.shareUrlIos)
                : (config.playStoreUrl.isNotEmpty
                    ? config.playStoreUrl
                    : config.shareUrlAndroid);

        await _showBlockingDialog(message, storeUrl);
      }
    } catch (_) {}
  }

  /// Compare versions ignoring pre-release/build labels
  bool _isOutdated(String current, String required) {
    List<int> parse(String v) {
      final core = v.split('+').first.split('-').first.trim();
      return core.split('.').map((part) {
        final m = RegExp(r'^(\d+)').firstMatch(part);
        return m != null ? int.parse(m.group(1)!) : 0;
      }).toList();
    }

    final c = parse(current);
    final r = parse(required);
    final len = c.length > r.length ? c.length : r.length;
    for (var i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final rv = i < r.length ? r[i] : 0;
      if (cv < rv) return true;
      if (cv > rv) return false;
    }
    return false; // equal
  }

  Future<void> _showBlockingDialog(String message, String storeUrl) async {
    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: Get.theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Update Required',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update,
                size: 48,
                color:
                    Get.isDarkMode
                        ? AppColor.primaryOrange
                        : Get.theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Get.isDarkMode
                            ? AppColor.primaryOrange
                            : Get.theme.primaryColor,
                    foregroundColor:
                        Get.isDarkMode
                            ? Colors.white
                            : Get.theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(storeUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
