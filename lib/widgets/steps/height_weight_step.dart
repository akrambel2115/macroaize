import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import '../height_weight_picker.dart';

class HeightWeightStep extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final ValueChanged<int> onHeightCmChanged;
  final void Function(int feet, int inches) onHeightFeetInchesChanged;
  final ValueChanged<int> onWeightKgChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final bool showHeaderBack;
  final bool showFooterPrevious;
  final EdgeInsetsGeometry? padding;

  const HeightWeightStep({
    super.key,
    this.title,
    this.subtitle,
    required this.onHeightCmChanged,
    required this.onHeightFeetInchesChanged,
    required this.onWeightKgChanged,
    required this.onContinue,
    this.onBack,
    this.showHeaderBack = false,
    this.showFooterPrevious = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
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
            (title ?? 'Choose your height and weight').tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
          Text(
            (subtitle ??
                    'Select your height and weight to calibrate your custom plan')
                .tr,
            style: context.theme.textTheme.titleSmall,
          ).paddingOnly(top: 10, bottom: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  HeightWeightPicker(
                    onHeightCmChanged: onHeightCmChanged,
                    onHeightFeetInchesChanged: onHeightFeetInchesChanged,
                    onWeightKgChanged: onWeightKgChanged,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
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
              if (showFooterPrevious && onBack != null)
                const SizedBox(width: 10),
              Expanded(
                child: ModernButton(
                  text: 'Continue'.tr,
                  onPressed: onContinue,
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
