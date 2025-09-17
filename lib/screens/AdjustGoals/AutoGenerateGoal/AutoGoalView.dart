import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:get/get.dart';
import '../../../widgets/steps/goal_step.dart';

class AutoGoalView extends GetView<AdjustGoalsController> {
  const AutoGoalView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdjustGoalsController>(
      builder:
          (c) => GoalStep(
            selectedGoal: c.selectedWGoal,
            onSelectGoal: c.onChangeGoal,
            onDesiredWeightChanged: (kg) => c.onChangeDesiredWeight(kg),
            onBack: () => c.onChangeView(2),
            onContinue: () {
              if (c.selectedWGoal.isNotEmpty) {
                c.setHasChanges(true);
                c.saveOnSql();
              }
            },
          ),
    );
  }
}
