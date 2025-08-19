import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class StoppingGoalView extends GetView<SignUpController> {
  const StoppingGoalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button handled by the SignUp scaffold
        Text(
          "What's stopping you from reaching your goals?".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20, bottom: 16),

        // Horizontal scrollable chips
        GetBuilder<SignUpController>(builder: (c) {
          final items = <Map<String, dynamic>>[
            {"label": "Lack of consistency".tr, "icon": Icons.schedule, "asset": 'assets/lottie/inconsistence.json'},
            {"label": "Unhealthy eating habits".tr, "icon": Icons.restaurant, "asset": 'assets/lottie/unhealthy.json'},
            {"label": "Lack of supports".tr, "icon": Icons.group_off, "asset": 'assets/lottie/lackSupport.json'},
            {"label": "Busy schedule".tr, "icon": Icons.calendar_month, "asset": 'assets/lottie/busy.json'},
            {"label": "Lack of meal inspiration".tr, "icon": Icons.lightbulb, "asset": 'assets/lottie/lackInspiration.json'},
          ];
          return SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final label = items[index]['label'] as String;
                final icon = items[index]['icon'] as IconData;
                final bool selected = c.selectedStoppingGoal == label;
                return GestureDetector(
                  onTap: () => c.onChangeStoppingGoal(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColor.primaryGradient : null,
                      color: selected ? null : context.theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: selected ? null : Border.all(color: context.theme.dividerColor.withOpacity(0.4)),
                      boxShadow: selected
                          ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: selected ? Colors.white : context.theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: context.theme.textTheme.titleSmall!.copyWith(
                            color: selected ? Colors.white : context.theme.textTheme.titleSmall!.color,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(label),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),

        const SizedBox(height: 14),
        // Lottie preview that expands to fill the remaining space
        GetBuilder<SignUpController>(builder: (c) {
          final items = <Map<String, dynamic>>[
            {"label": "Lack of consistency".tr, "asset": 'assets/lottie/inconsistence.json'},
            {"label": "Unhealthy eating habits".tr, "asset": 'assets/lottie/unhealthy.json'},
            {"label": "Lack of supports".tr, "asset": 'assets/lottie/lackSupport.json'},
            {"label": "Busy schedule".tr, "asset": 'assets/lottie/busy.json'},
            {"label": "Lack of meal inspiration".tr, "asset": 'assets/lottie/lackInspiration.json'},
          ];
          final sel = c.selectedStoppingGoal;
          final matched = sel.isNotEmpty ? items.firstWhere((it) => it['label'] == sel, orElse: () => {}) : {};
          final asset = matched.isNotEmpty ? matched['asset'] as String : null;
            return Expanded(
              child: Center(
                child: asset == null
                    ? const SizedBox.shrink()
                    : SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Lottie.asset(asset, repeat: true),
                          ),
                        ),
                      ),
              ),
            );
        }),

          // Removed Spacer() so Expanded Lottie area can occupy available space
        GetBuilder<SignUpController>(
          builder: (controller) {
            return GestureDetector(
              onTap: () {
                if (controller.selectedStoppingGoal.isNotEmpty) {
                  controller.onChangeView();
                }
              },
              child: Container(
                alignment: Alignment.center,
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal.isNotEmpty
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Continue".tr,
                  style: context.theme.textTheme.titleMedium,
                ),
              ).paddingOnly(top: 30),
            );
          },
        ),
      ],
    );
  }
}
