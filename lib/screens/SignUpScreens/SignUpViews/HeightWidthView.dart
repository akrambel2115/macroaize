import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';

import 'package:foodcalorietracker/widgets/steps/height_weight_step.dart';

class HeightWidth extends GetView<SignUpController> {
  const HeightWidth({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SignUpController>(
      builder: (c) => HeightWeightStep(
        onHeightCmChanged: (cm) => c.selectedCm = cm,
        onHeightFeetInchesChanged: (feet, inches) {
          c.selectedFeet = feet;
          c.selectedInches = inches;
        },
        onWeightKgChanged: (kg) => c.selectedWeightKg = kg,
  onBack: () {
          c.selectedView = 1; // go back to Workout
          c.update();
        },
  showHeaderBack: false,
        showFooterPrevious: true,
        onContinue: () => c.onChangeView(),
      ),
    );
  }
}
