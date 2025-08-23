import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import '../goal_and_weight_picker.dart';

class GoalStep extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String selectedGoal;
  final void Function(String id) onSelectGoal;
  final ValueChanged<int> onDesiredWeightChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final bool showHeaderBack;
  final bool showFooterPrevious;
  final EdgeInsetsGeometry? padding;

  const GoalStep({
    super.key,
    this.title,
    this.subtitle,
    required this.selectedGoal,
    required this.onSelectGoal,
    required this.onDesiredWeightChanged,
    required this.onContinue,
    this.onBack,
  this.showHeaderBack = false,
  this.showFooterPrevious = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedGoal.isNotEmpty;
    return SingleChildScrollView(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeaderBack && onBack != null)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
              ),
            Text(
              (title ?? 'What is your goal?').tr,
              style: context.theme.textTheme.headlineLarge,
            ).paddingOnly(top: 20),
            Text(
              (subtitle ?? 'This helps is generate a plan for your calorie intake.').tr,
              style: context.theme.textTheme.titleSmall,
            ).paddingOnly(top: 10, bottom: 10),
            GoalAndWeightPicker(
              selectedGoal: selectedGoal,
              onSelectGoal: onSelectGoal,
              onDesiredWeightChanged: onDesiredWeightChanged,
            ),
      Row(
              children: [
        if (showFooterPrevious && onBack != null)
                  Expanded(
                    child: ModernButton(
                      text: 'Previous'.tr,
                      onPressed: onBack,
                      style: ModernButtonStyle.secondary,
                      size: ModernButtonSize.medium,
                      borderRadius: BorderRadius.circular(30),
                      height: 50,
                    ),
                  ),
        if (showFooterPrevious && onBack != null) const SizedBox(width: 10),
                Expanded(
                  child: ModernButton(
                    text: 'Continue'.tr,
                    onPressed: hasSelection ? onContinue : null,
                    style: ModernButtonStyle.primary,
                    size: ModernButtonSize.medium,
                    borderRadius: BorderRadius.circular(30),
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    height: 50,
                  ),
                ),
              ],
            ).paddingOnly(top: 30),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
