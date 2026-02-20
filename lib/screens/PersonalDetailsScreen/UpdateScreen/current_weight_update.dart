import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/screens/PersonalDetailsScreen/personal_details_controller.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/get.dart';

import '../../../constant/font_family.dart';

class CurrentWeightUpdate extends GetView<PersonalDetailsController> {
  const CurrentWeightUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 5,
        right: 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your current weight?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20, bottom: 10, left: 10),

          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              const int minKg = 51;
              const int maxKg = 150;

              final int kgCount = maxKg - minKg + 1;

              final int initialItem =
                  controller.selectedWeightKg < minKg
                      ? 0
                      : (controller.selectedWeightKg > maxKg
                          ? kgCount - 1
                          : controller.selectedWeightKg - minKg);

              final FixedExtentScrollController scrollController =
                  FixedExtentScrollController(initialItem: initialItem);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColor.darkCard
                                    : context.theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoPicker(
                            scrollController: scrollController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              controller.selectedWeightKg = minKg + index;
                              controller.setHasChanges(true);
                              controller.update();
                            },
                            children: List.generate(kgCount, (index) {
                              final value = minKg + index;
                              return Center(
                                child: Text(
                                  "$value${"kg".tr}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
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
        ],
      ),
    );
  }
}
