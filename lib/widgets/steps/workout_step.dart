import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/modern_button.dart';
import '../workout_selector_radial.dart';

class WorkoutStep extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String selectedId;
  final void Function(String id) onSelect;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final bool showHeaderBack;
  final bool showFooterPrevious;
  final EdgeInsetsGeometry? padding;

  const WorkoutStep({
    super.key,
    this.title,
    this.subtitle,
    required this.selectedId,
    required this.onSelect,
    required this.onContinue,
    this.onBack,
    this.showHeaderBack = false,
    this.showFooterPrevious = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedId.isNotEmpty;
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).padding.bottom,
            top: 10,
          ),
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
            (title ?? 'How many workout do you per week?').tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
          Text(
            (subtitle ?? 'This will used to calibrate your custom plan').tr,
            style: context.theme.textTheme.titleSmall,
          ).paddingOnly(top: 10, bottom: 10),
          WorkoutSelectorRadial(selectedId: selectedId, onSelect: onSelect),
          const Spacer(),
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
              if (showFooterPrevious && onBack != null)
                const SizedBox(width: 10),
              Expanded(
                child: ModernButton(
                  text: 'Continue'.tr,
                  onPressed: hasSelection ? onContinue : null,
                  style: ModernButtonStyle.primary,
                  size: ModernButtonSize.medium,
                  borderRadius: BorderRadius.circular(30),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                  height: 50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
