import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/widgets/steps/goal_step.dart';

class GoalScreen extends GetView<SignUpController> {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      builder: (c) => GoalStep(
        selectedGoal: c.selectedWGoal,
        onSelectGoal: c.onChangeGoal,
        onDesiredWeightChanged: (kg) => c.onChangeDesiredWeight(kg),
        onContinue: () {
          if (c.selectedWGoal.isNotEmpty) {
            c.onChangeView();
          }
        },
  onBack: () {
          c.selectedView = 2; // go back to Height & Weight
          c.update();
        },
  showHeaderBack: false,
        showFooterPrevious: true,
      ),
    );
  }
}
