import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config_service.dart';
import 'package:macroaize/constant/app_color.dart';

/// Enforces minimum app version with a blocking update dialog.
/// 
/// Features:
/// - Blocks outdated app versions with non-dismissible dialog
/// - Re-checks on app resume from background
/// - Localized strings
/// - Proper error handling with logging
class UpdateGuardService extends GetxService with WidgetsBindingObserver {
  bool _isDialogShowing = false;
  String? _currentVersion;
  
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDialogShowing) {
      // Re-check version when app returns from background
      enforceMinimumVersion();
    }
  }

  /// Check and enforce minimum app version.
  /// Shows a blocking dialog if the app is outdated.
  Future<void> enforceMinimumVersion() async {
    if (_isDialogShowing) return;
    
    try {
      final config = Get.find<AppConfigService>();
      
      // Ensure config is loaded - refresh if needed
      if (!config.isLoaded) {
        await config.refresh();
      }

      final PackageInfo info = await PackageInfo.fromPlatform();
      _currentVersion = info.version.trim();
      final required = config.minRequiredAppVersion.trim();
      
      // Skip check if required version is default/empty
      if (required.isEmpty || required == '1.0.0') {
        if (kDebugMode) print('[UpdateGuard] Skipping check - default version');
        return;
      }

      if (_isOutdated(_currentVersion!, required)) {
        if (kDebugMode) {
          print('[UpdateGuard] Update required: $_currentVersion < $required');
        }
        
        final message = config.updateMessage.isNotEmpty 
            ? config.updateMessage 
            : 'update_default_message'.tr;
            
        final storeUrl = Platform.isIOS
            ? (config.appStoreUrl.isNotEmpty ? config.appStoreUrl : config.shareUrlIos)
            : (config.playStoreUrl.isNotEmpty ? config.playStoreUrl : config.shareUrlAndroid);

        await _showBlockingDialog(
          message: message,
          storeUrl: storeUrl,
          currentVersion: _currentVersion!,
          requiredVersion: required,
        );
      } else {
        if (kDebugMode) {
          print('[UpdateGuard] Version OK: $_currentVersion >= $required');
        }
      }
    } catch (e, stack) {
      // Log error but don't block app - fail open for better UX
      // In production, you might want to fail closed for security
      if (kDebugMode) {
        print('[UpdateGuard] Error checking version: $e');
        print(stack);
      }
    }
  }

  /// Compare versions ignoring pre-release/build labels.
  /// Returns true if current < required.
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

  Future<void> _showBlockingDialog({
    required String message,
    required String storeUrl,
    required String currentVersion,
    required String requiredVersion,
  }) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    
    await Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Get.theme.dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'update_required_title'.tr,
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
                color: Get.isDarkMode
                    ? AppColor.primaryOrange
                    : Get.theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'v$currentVersion → v$requiredVersion',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.hintColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Get.isDarkMode
                        ? AppColor.primaryOrange
                        : Get.theme.primaryColor,
                    foregroundColor: Get.isDarkMode
                        ? Colors.white
                        : Get.theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openStore(storeUrl),
                  child: Text(
                    'update_now'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    
    // Note: Dialog is blocking, so this won't run until closed
    // But we track state in case of edge cases
    _isDialogShowing = false;
  }
  
  Future<void> _openStore(String storeUrl) async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[UpdateGuard] Error opening store: $e');
    }
  }
}
