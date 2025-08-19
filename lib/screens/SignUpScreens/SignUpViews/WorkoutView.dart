import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:foodcalorietracker/widgets/steps/workout_step.dart';
import 'package:get/get.dart';

class WorkoutView extends GetView<SignUpController> {
  const WorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      builder: (c) => WorkoutStep(
        selectedId: c.selectedWorkOut,
        onSelect: c.onChangeWorkout,
        onContinue: () {
          if (c.selectedWorkOut.isNotEmpty) {
            c.onChangeView();
          }
        },
        onBack: () {
          // go to Gender screen in the SignUp flow
          c.selectedView = 0;
          c.update();
        },
  showHeaderBack: false,
      ),
    );
  }

}
