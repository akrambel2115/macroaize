import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/app_color.dart';

class NotificationService {
  /// success snackbar.
  static void showSuccess(String messageKey, {Map<String, String>? params}) {
    Get.closeAllSnackbars();

    final message = params == null ? messageKey.tr : messageKey.trParams(params);

    Get.showSnackbar(GetSnackBar(
      titleText: Text('success'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColor.success,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: _bottomSafeArea + 12,
      ),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    ));
  }

  // error snackbar.
  static void showError(String messageKey, {Map<String, String>? params}) {
    Get.closeAllSnackbars();

    final message = params == null ? messageKey.tr : messageKey.trParams(params);

    Get.showSnackbar(GetSnackBar(
      titleText: Text('error'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColor.error,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: _bottomSafeArea + 12,
      ),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    ));
  }

  /// snackbar for general messages (replaces Fluttertoast).
  static void showInfo(String message, {Duration? duration}) {
    Get.closeAllSnackbars();

    Get.showSnackbar(GetSnackBar(
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.black87,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: _bottomSafeArea + 12,
      ),
      borderRadius: 12,
      duration: duration ?? const Duration(seconds: 2),
    ));
  }

  /// Get the bottom safe area inset for iOS devices with home indicator.
  static double get _bottomSafeArea {
    try {
      final context = Get.context;
      if (context != null) {
        return MediaQuery.of(context).viewPadding.bottom;
      }
    } catch (_) {}
    return 0;
  }
}
