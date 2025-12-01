import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class HeightWeightPicker extends StatelessWidget {
  final void Function(int cm)? onHeightCmChanged;
  final void Function(int feet, int inches)? onHeightFeetInchesChanged;
  final void Function(int kg)? onWeightKgChanged;
  final int? initialHeightCm;
  final int? initialWeightKg;

  const HeightWeightPicker({
    super.key,
    this.onHeightCmChanged,
    this.onHeightFeetInchesChanged,
    this.onWeightKgChanged,
    this.initialHeightCm,
    this.initialWeightKg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Height'.tr,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : AppColor.darkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            (initialHeightCm != null && initialHeightCm! >= 120)
                                ? (initialHeightCm! - 120).clamp(0, 129)
                                : 50, // default visual start ~170cm
                      ),
                      onSelectedItemChanged: (index) {
                        final cm = 120 + index;
                        onHeightCmChanged?.call(cm);
                      },
                      children: List.generate(130, (index) {
                        return Center(
                          child: Text(
                            '${120 + index}${'cm'.tr}',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Weight'.tr,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : AppColor.darkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            (initialWeightKg != null && initialWeightKg! >= 51)
                                ? (initialWeightKg! - 51).clamp(0, 149)
                                : 9, // default visual start ~60kg
                      ),
                      onSelectedItemChanged: (index) {
                        final kg = 51 + index;
                        onWeightKgChanged?.call(kg);
                      },
                      children: List.generate(150, (index) {
                        return Center(
                          child: Text(
                            '${51 + index} ${'kg'.tr}',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
