import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/SignUpScreens/signup_controller.dart';
import 'package:macroaize/ThemeService/theme_controller.dart';
import 'package:macroaize/widgets/modern_button.dart';

class ThemeChoiceView extends GetView<SignUpController> {
  const ThemeChoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    return GetBuilder<ThemeController>(
      builder: (_) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommended Theme'.tr,
              style: context.theme.textTheme.headlineLarge,
            ).paddingOnly(top: 20),
            Text(
              'Light mode is recommended for better readability and focus while tracking your health. You can always change this later in Settings.'.tr,
              style: context.theme.textTheme.titleSmall?.copyWith(height: 1.4),
            ).paddingOnly(top: 10, bottom: 24),

            // Light mode card (forced)
            _ThemeOptionCard(
              label: 'Light Mode'.tr,
              isDarkOption: false,
              selected: true,
              onTap: () {}, // Forced, so no action needed
            ),

            const Spacer(),

            ModernButton(
              text: 'Continue'.tr,
              onPressed: () async {
                if (themeCtrl.isDarkMode) {
                  await themeCtrl.toggleTheme(false);
                }
                controller.onChangeView();
              },
              style: ModernButtonStyle.primary,
              size: ModernButtonSize.medium,
              borderRadius: BorderRadius.circular(30),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
              height: 50,
              width: double.infinity,
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String label;
  final bool isDarkOption;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.label,
    required this.isDarkOption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg =
        isDarkOption ? const Color(0xFF0D1117) : AppColor.neutralWhite;
    final Color textColor =
        isDarkOption ? AppColor.neutralWhite : AppColor.neutralGrey900;
    final Color subtitleColor =
        isDarkOption ? AppColor.neutralGrey400 : AppColor.neutralGrey600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColor.primaryOrange
                : AppColor.neutralGrey300,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColor.primaryOrange.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock UI preview
            _MockPreview(isDark: isDarkOption),
            const SizedBox(height: 14),

            // Label + check row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDarkOption
                          ? 'Easy on the eyes'.tr
                          : 'Clean & bright'.tr,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColor.primaryOrange
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? AppColor.primaryOrange
                          : AppColor.neutralGrey400,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A tiny mock UI that visually represents the theme appearance.
class _MockPreview extends StatelessWidget {
  final bool isDark;

  const _MockPreview({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color bg = isDark ? const Color(0xFF161B22) : AppColor.neutralGrey100;
    final Color card = isDark ? const Color(0xFF21262D) : AppColor.neutralWhite;
    final Color text = isDark ? AppColor.neutralGrey300 : AppColor.neutralGrey700;
    final Color accent = AppColor.primaryOrange;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        color: bg,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake header bar
            Row(
              children: [
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 8,
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fake card
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.local_fire_department,
                        size: 12, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: text.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: text.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Fake progress bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
