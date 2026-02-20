import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/modern_button.dart';
import '../goal_and_weight_picker.dart';

class GoalStep extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final String selectedGoal;
  final void Function(String id) onSelectGoal;
  final ValueChanged<int> onDesiredWeightChanged;
  final int? initialWeight;
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
    this.initialWeight,
    required this.onContinue,
    this.onBack,
    this.showHeaderBack = false,
    this.showFooterPrevious = true,
    this.padding,
  });

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleGoalSelection(String id) {
    widget.onSelectGoal(id);
    // Auto-scroll to bottom to reveal the Continue button
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selectedGoal.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showHeaderBack && widget.onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: widget.onBack,
                        ),
                      ),
                    Text(
                      (widget.title ?? 'What is your goal?').tr,
                      style: context.theme.textTheme.headlineLarge,
                    ).paddingOnly(top: 20),
                    Text(
                      (widget.subtitle ??
                              'This helps us generate a plan for your calorie intake.')
                          .tr,
                      style: context.theme.textTheme.titleSmall,
                    ).paddingOnly(top: 10, bottom: 10),
                    GoalAndWeightPicker(
                      selectedGoal: widget.selectedGoal,
                      onSelectGoal: _handleGoalSelection,
                      onDesiredWeightChanged: widget.onDesiredWeightChanged,
                      initialWeight: widget.initialWeight,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (widget.showFooterPrevious && widget.onBack != null)
                          Expanded(
                            child: ModernButton(
                              text: 'Previous'.tr,
                              onPressed: widget.onBack,
                              style: ModernButtonStyle.secondary,
                              size: ModernButtonSize.medium,
                              borderRadius: BorderRadius.circular(30),
                              height: 50,
                            ),
                          ),
                        if (widget.showFooterPrevious && widget.onBack != null)
                          const SizedBox(width: 10),
                        Expanded(
                          child: ModernButton(
                            text: 'Continue'.tr,
                            onPressed: hasSelection ? widget.onContinue : null,
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
                    ).paddingOnly(top: 30),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
