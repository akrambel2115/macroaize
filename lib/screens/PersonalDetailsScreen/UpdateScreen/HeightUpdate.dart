import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';
import '../../../constant/FontFamily.dart';

class HeightUpdate extends GetView<PersonalDetailsController> {
  const HeightUpdate({super.key});

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
                      color:
                          controller.isMetric
                              ? Colors.grey
                              : context.theme.primaryColor,
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
                      color:
                          controller.isMetric
                              ? context.theme.primaryColor
                              : Colors.grey,
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
              int minCm = 121; // Range: 121cm to 250cm
              int cmInitialItem = controller.selectedCm - minCm;

              int totalInches =
                  (controller.selectedFeet * 12) + controller.selectedInches;
              int minInches = 3 * 12; // 3ft minimum
              int inchInitialItem = totalInches - minInches;

              final scrollController = FixedExtentScrollController(
                initialItem:
                    controller.isMetric ? cmInitialItem : inchInitialItem,
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "Height".tr,
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
                            color: context.theme.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            scrollController: scrollController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              if (controller.isMetric) {
                                controller.selectedCm = minCm + index;
                              } else {
                                int inches = minInches + index;
                                controller.selectedFeet = inches ~/ 12;
                                controller.selectedInches = inches % 12;
                              }
                              controller.update();
                            },
                            children:
                                controller.isMetric
                                    ? List.generate(130, (index) {
                                      return Center(
                                        child: Text(
                                          "${minCm + index} ${"cm".tr}",
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
                                      int inches = minInches + index;
                                      int ft = inches ~/ 12;
                                      int inch = inches % 12;
                                      return Center(
                                        child: Text(
                                          "$ft${"ft".tr} $inch${"in".tr}",
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
              ).marginOnly(left: 10, right: 10);
            },
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              controller.updateHeight();
              controller.onChangeSelectedView(0);
            },
            child: Container(
              alignment: Alignment.center,
              height: 50,
              margin: EdgeInsets.only(left: 8, right: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.theme.focusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Update".tr,
                style: context.theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
