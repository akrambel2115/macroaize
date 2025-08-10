import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';

import '../../../widgets/AppWidgets.dart';

class HeightWidth extends GetView<SignUpController> {
  const HeightWidth({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppWidgets.backButton(context, () {
          Get.back();
        }),
        Text(
          "How many workout do you per week?".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20),
        Text(
          "This will used to calibrate your custom plan".tr,
          style: context.theme.textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 10),
        GetBuilder<SignUpController>(
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
            );
          },
        ),
        const SizedBox(height: 20),

        // Height and Weight Pickers
        GetBuilder<SignUpController>(
          builder: (controller) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
                    children: [
                       Text(
                        "Height".tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: poppins,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CupertinoPicker(
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            if (controller.isMetric) {
                              controller.selectedCm = 121 + index;

                            } else {
                              controller.selectedFeet = 3 + index ~/ 12;
                              controller.selectedInches = index % 12;
                            }
                          },
                          children:
                              controller.isMetric
                                  ? List.generate(130, (index) {
                                    return Center(
                                      child: Text(
                                        "${121 + index} ${"cm".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: context.theme.scaffoldBackgroundColor,
                                          fontFamily: poppins,
                                        ),
                                      ),
                                    );
                                  })
                                  : List.generate(150, (index) {
                                    return Center(
                                      child: Text(
                                        "${3 + index ~/ 12} ${"ft".tr} ${index % 12} ${"in".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color:
                                          context
                                              .theme
                                              .scaffoldBackgroundColor,
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
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    children: [
                       Text(
                        "Weight".tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: poppins,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CupertinoPicker(
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            if (controller.isMetric) {
                              controller.selectedWeightKg = 51 + index;

                            } else {
                              controller.selectedWeightLb = 100 + index;
                            }
                          },
                          children:
                              controller.isMetric
                                  ? List.generate(150, (index) {
                                    return Center(
                                      child: Text(
                                        "${51 + index} ${"kg".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color:
                                              context
                                                  .theme
                                                  .scaffoldBackgroundColor,
                                          fontFamily: poppins,
                                        ),
                                      ),
                                    );
                                  })
                                  : List.generate(150, (index) {
                                    return Center(
                                      child: Text(
                                        "${100 + index} ${"lb".tr}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color:
                                              context
                                                  .theme
                                                  .scaffoldBackgroundColor,
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
            );
          },
        ),
        Spacer(),
        GestureDetector(
          onTap: () {
            controller.onChangeView();
          },
          child: Container(
            alignment: Alignment.center,
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color:context.theme.focusColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Continue".tr,
              style: context.theme.textTheme.titleMedium,
            ),
          ),
        )
      ],
    );
  }
}
