import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';

import 'package:macroaize/widgets/widget_preview_cards.dart';

class WidgetPromotionService {
  static const String _prefsKey = 'widget_promotion_shown';

  Future<void> showPromotionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_prefsKey) ?? false;

    if (!hasShown) {
      await Future.delayed(const Duration(milliseconds: 600));
      await showPromotion();
      await prefs.setBool(_prefsKey, true);
    }
  }

  /// forces the promotion to show
  Future<void> showPromotion() async {
    if (Platform.isAndroid) {
      _showAndroidInstructionDialog();
    } else if (Platform.isIOS) {
      _showIOSBottomSheet();
    }
  }

  /// Dismisses the promotion popup safely on both platforms.
  /// Uses the shared [safeBack] helper which pops via the overlay
  /// navigator, bypassing GetX state issues with
  /// PopScope(canPop: false) on the underlying route.
  void _dismiss() {
    safeBack();
  }

  void _showAndroidInstructionDialog() {
    final isDark = Get.isDarkMode;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColor.darkBackground : Colors.white,
        title: Text(
          'widget_promo_title'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppColor.neutralGrey900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Image
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: const WidgetPreviewCards(),
              ),
            ),
            Text(
              'widget_promo_android_instructions'.tr,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColor.neutralGrey600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => _dismiss(), child: Text('ok'.tr)),
        ],
      ),
    );
  }

  void _showIOSBottomSheet() {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColor.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'widget_promo_title'.tr,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : AppColor.neutralGrey900,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color:
                            isDark ? Colors.white54 : AppColor.neutralGrey600,
                      ),
                      onPressed: () => _dismiss(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Preview Image
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: const WidgetPreviewCards(),
                  ),
                ),
                _buildStep(1, 'widget_promo_ios_step1'.tr),
                _buildStep(2, 'widget_promo_ios_step2'.tr),
                _buildStep(3, 'widget_promo_ios_step3'.tr),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _dismiss(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'widget_promo_got_it'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildStep(int number, String text) {
    final isDark = Get.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColor.primaryOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: AppColor.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColor.neutralGrey600,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
