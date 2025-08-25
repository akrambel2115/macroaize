import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/AppColor.dart';

class NotificationService {
  /// Show a localized success snackbar.
  /// [messageKey] is a translation key; [params] may provide values for trParams.
  static void showSuccess(String messageKey, {Map<String, String>? params}) {
    // close any existing
    Get.closeAllSnackbars();

    final message = params == null ? messageKey.tr : messageKey.trParams(params);

    Get.showSnackbar(GetSnackBar(
      titleText: Text('success'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      // Use semantic success color (green)
      backgroundColor: AppColor.success,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    ));
  }

  /// Show a localized error snackbar.
  /// Uses semantic error color (red).
  static void showError(String messageKey, {Map<String, String>? params}) {
    Get.closeAllSnackbars();

    final message = params == null ? messageKey.tr : messageKey.trParams(params);

    Get.showSnackbar(GetSnackBar(
      titleText: Text('error'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      messageText: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColor.error,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    ));
  }
}
