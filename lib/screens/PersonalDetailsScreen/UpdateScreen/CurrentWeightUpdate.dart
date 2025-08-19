import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';

import '../../../constant/FontFamily.dart';

class CurrentWeightUpdate extends GetView<PersonalDetailsController> {
  const CurrentWeightUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom+10,left: 5,right: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Imperial".tr,
                    style: TextStyle(
                      fontSize: 18,

                      fontWeight:
                      controller.isMetric
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: controller.isMetric ? Colors.grey : context.theme.primaryColor,
                    ),
                  ),
                  Switch(
                    activeColor: context.theme.focusColor,
                    value: controller.isMetric,
                    onChanged: (value) {
                      controller.onChangeMetric(value);
                    },
                  ),
                  Text(
                    "Metric".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      controller.isMetric
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: controller.isMetric ? context.theme.primaryColor : Colors.grey,
                    ),
                  ),
                ],
              ).paddingOnly(top: 35);
            },
          ),
          const SizedBox(height: 20),

          // Height and Weight Pickers
          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              const int minKg = 51;
              const int maxKg = 150; // cap at 150kg
              const int minLb = 100; // imperial fallback (unchanged)

              final int kgCount = (maxKg - minKg + 1);

              final int initialItem = controller.isMetric
                  ? (controller.selectedWeightKg < minKg
                      ? 0
                      : (controller.selectedWeightKg > maxKg ? kgCount - 1 : controller.selectedWeightKg - minKg))
                  : (controller.selectedWeightLb - minLb);

              final FixedExtentScrollController scrollController = FixedExtentScrollController(
                initialItem: initialItem,
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "Weight".tr,
                          style: TextStyle(
                            color: context.theme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: poppins,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // adapt wheel background to current theme (dark/light)
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : context.theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            scrollController: scrollController, // 👈 important
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              if (controller.isMetric) {
                                controller.selectedWeightKg = minKg + index;
                              } else {
                                controller.selectedWeightLb = minLb + index;
                              }
                              controller.setHasChanges(true);
                              controller.update();
                            },
                            children: controller.isMetric
                                ? List.generate(kgCount, (index) {
                                    final value = minKg + index;
                                    return Center(
                                      child: Text(
                                        "${value}${"kg".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                                          fontFamily: poppins,
                                        ),
                                      ),
                                    );
                                  })
                                : List.generate(150, (index) {
                                    return Center(
                                      child: Text(
                                        "${minLb + index}${"lb".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? context.theme.scaffoldBackgroundColor
                                              : Colors.black,
                                          fontFamily: poppins,
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
              ).marginOnly(left: 10, right: 10);
            },
          ),

          // bottom Update button removed; use Save in AppBar
        ],
      ),
    );
  }
}
