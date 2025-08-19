import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import '../../../widgets/steps/workout_step.dart';
import 'package:get/get.dart';

class AutoWorkoutView extends GetView<AdjustGoalsController> {
  const AutoWorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdjustGoalsController>(
      builder: (c) => WorkoutStep(
        selectedId: c.selectedWorkOut,
        onSelect: c.onChangeWorkout,
        onContinue: () {
          if (c.selectedWorkOut.isNotEmpty) {
            c.onChangeView(2);
          }
        },
      ),
    );
  }
}
