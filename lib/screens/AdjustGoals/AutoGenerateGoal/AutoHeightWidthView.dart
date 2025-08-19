import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:get/get.dart';
import '../../../widgets/steps/height_weight_step.dart';

class AutoHeightWidth extends GetView<AdjustGoalsController> {
  const AutoHeightWidth({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdjustGoalsController>(
      builder: (c) => HeightWeightStep(
        isMetric: c.isMetric,
        onChangeMetric: (v) {
          c.onChangeMetric(v);
          c.update();
        },
        onHeightCmChanged: (cm) {
          c.selectedCm = cm;
          c.update();
        },
        onHeightFeetInchesChanged: (feet, inches) {
          c.selectedFeet = feet;
          c.selectedInches = inches;
          c.update();
        },
        onWeightKgChanged: (kg) {
          c.selectedWeightKg = kg;
          c.update();
        },
        onWeightLbChanged: (lb) {
          c.selectedWeightLb = lb;
          c.update();
        },
        onBack: () => c.onChangeView(1),
        onContinue: () => c.onChangeView(3),
      ),
    );
  }
}
