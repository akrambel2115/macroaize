import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateUsService {
  static const String _kRateUsShownKey = 'rate_us_shown_v1';
  static const String _kFoodLogCountKey = 'rate_us_food_log_count';
  static const String _kFoodScanCountKey = 'rate_us_food_scan_count';
  static const String _kChatCountKey = 'rate_us_chat_count';
  static const int _kRequiredActionCount = 3;

  static const String actionFoodLog = 'food_log';
  static const String actionFoodScan = 'food_scan';
  static const String actionChat = 'chat';

  // show review if eligible
  static Future<void> showRateUsIfEligible(String actionType) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_kRateUsShownKey) ?? false;

    if (hasShown) {
      return;
    }

    String countKey;
    switch (actionType) {
      case actionFoodLog:
        countKey = _kFoodLogCountKey;
        break;
      case actionFoodScan:
        countKey = _kFoodScanCountKey;
        break;
      case actionChat:
        countKey = _kChatCountKey;
        break;
      default:
        return;
    }

    final currentCount = prefs.getInt(countKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(countKey, newCount);

    if (newCount >= _kRequiredActionCount) {
      final InAppReview inAppReview = InAppReview.instance;
      final isAvailable = await inAppReview.isAvailable();
      debugPrint('🌟 RateUs: isAvailable=$isAvailable (actionCount=$newCount)');

      if (isAvailable) {
        // mark shown before request
        await prefs.setBool(_kRateUsShownKey, true);

        // delay for ux
        await Future.delayed(const Duration(seconds: 2));

        await inAppReview.requestReview();
      }
    }
  }

  static Future<void> showRateUsForOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_kRateUsShownKey) ?? false;

    if (hasShown) return;

    final InAppReview inAppReview = InAppReview.instance;
    final isAvailable = await inAppReview.isAvailable();
    debugPrint('🌟 RateUs onboarding: isAvailable=$isAvailable');

    if (isAvailable) {
      // Wait for any ongoing transitions to fully settle before presenting
      // the review dialog – iOS silently drops the request when the UI is
      // still mid-transition.
      await Future.delayed(const Duration(seconds: 2));

      await inAppReview.requestReview();

      // Mark as shown *after* the request so a throttled iOS prompt can
      // be retried on the next eligible trigger.
      await prefs.setBool(_kRateUsShownKey, true);

      // Give the native review dialog time to render before the caller
      // navigates to a new screen (which would dismiss it on iOS).
      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}  
