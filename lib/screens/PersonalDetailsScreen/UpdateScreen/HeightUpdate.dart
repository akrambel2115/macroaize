import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';
import '../../../constant/FontFamily.dart';

import 'package:foodcalorietracker/constant/AppColor.dart';

class HeightUpdate extends GetView<PersonalDetailsController> {
  const HeightUpdate({super.key});

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
            "What's your height?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20, bottom: 10, left: 10),

          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              const int minCm = 121;
              final int cmInitialItem = controller.selectedCm - minCm;

              final scrollController = FixedExtentScrollController(
                initialItem: cmInitialItem,
              );

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
                              controller.selectedCm = minCm + index;
                              controller.setHasChanges(true);
                              controller.update();
                            },
                            children: List.generate(130, (index) {
                              return Center(
                                child: Text(
                                  "${minCm + index} ${"cm".tr}",
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
