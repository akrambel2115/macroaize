import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/app_color.dart';

class NotificationService {
  /// success snackbar.
  static void showSuccess(String messageKey, {Map<String, String>? params}) {
    final message =
        params == null ? messageKey.tr : messageKey.trParams(params);
    _show(
      title: 'success'.tr,
      message: message,
      backgroundColor: AppColor.success,
      duration: const Duration(seconds: 3),
    );
  }

  // error snackbar.
  static void showError(String messageKey, {Map<String, String>? params}) {
    final message =
        params == null ? messageKey.tr : messageKey.trParams(params);
    _show(
      title: 'error'.tr,
      message: message,
      backgroundColor: AppColor.error,
      duration: const Duration(seconds: 3),
    );
  }

  /// snackbar for general messages (replaces Fluttertoast).
  static void showInfo(String message, {Duration? duration}) {
    _show(
      message: message,
      backgroundColor: Colors.black87,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  static void _show({
    String? title,
    required String message,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final context = Get.overlayContext ?? Get.context;
    final marginBottom = _bottomSafeArea(context) + 12;

    if (context != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: backgroundColor,
            duration: duration,
            margin: EdgeInsets.only(left: 12, right: 12, bottom: marginBottom),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: _buildContent(title: title, message: message),
          ),
        );
        return;
      }
    }

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.rawSnackbar(
      backgroundColor: backgroundColor,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.only(left: 12, right: 12, bottom: marginBottom),
      borderRadius: 12,
      duration: duration,
      messageText: _buildContent(title: title, message: message),
    );
  }

  static Widget _buildContent({String? title, required String message}) {
    if (title == null || title.isEmpty) {
      return Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(message, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  /// Get the bottom safe area inset for iOS devices with home indicator.
  static double _bottomSafeArea(BuildContext? context) {
    try {
      if (context != null) {
        return MediaQuery.of(context).padding.bottom;
      }
    } catch (_) {}
    return 0;
  }
}
