import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:get/get.dart';
import '../../../constant/FontFamily.dart';

class AutoHeightWidth extends GetView<AdjustGoalsController> {
  const AutoHeightWidth({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How many workout do you per week?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
          Text(
            "This will used to calibrate your custom plan".tr,
            style: context.theme.textTheme.titleSmall,
          ).paddingOnly(top: 10, bottom: 10),
          GetBuilder<AdjustGoalsController>(
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
          GetBuilder<AdjustGoalsController>(
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
                            color:  context.theme.primaryColor,
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
                            color: context.theme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              if (controller.isMetric) {
                                controller.selectedCm = 120 + index;
                              } else {
                                controller.selectedFeet = 3 + index ~/ 12;
                                controller.selectedInches = index % 12;
                              }
                              controller.update();
                            },
                            children:
                                controller.isMetric
                                    ? List.generate(130, (index) {
                                      return Center(
                                        child: Text(
                                          "${120 + index}${"cm".tr}",
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
                                    : List.generate(100, (index) {
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
                            color:  context.theme.primaryColor,
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
                            color: context.theme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              if (controller.isMetric) {
                                controller.selectedWeightKg = 51 + index;
                              } else {
                                controller.selectedWeightLb = 101+ index;
                              }
                              controller.update();
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
                                          "${101 + index} ${"lb".tr}",
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
              controller.onChangeView(3);
            },
            child: Container(
              alignment: Alignment.center,
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.theme.focusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Continue".tr,
                style: context.theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
