import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';

import '../../../constant/FontFamily.dart';

class GoalUpdate extends GetView<PersonalDetailsController> {
  const GoalUpdate({super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding:  EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom+10,left: 5,right: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Text(
            "Choose your desired weight?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20,bottom: 10,left: 10),

        GetBuilder<PersonalDetailsController>(
          builder: (controller) {
            const int minWeight = 50;
            const int maxWeight = 150; // set cap at 150kg
            final int count = maxWeight - minWeight + 1;

            final int initialItem = ConstantUserMaster.desiredGoal < minWeight
                ? 0
                : (ConstantUserMaster.desiredGoal > maxWeight ? count - 1 : ConstantUserMaster.desiredGoal - minWeight);

            final FixedExtentScrollController weightController = FixedExtentScrollController(
              initialItem: initialItem,
            );

            return Container(
              margin: const EdgeInsets.all(15),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : context.theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CupertinoPicker(
                scrollController: weightController,
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  controller.onChangeDesiredWeight(minWeight + index);
                  controller.setHasChanges(true);
                },
                children: List.generate(count, (index) {
                  final value = minWeight + index;
                  return Center(
                    child: Text(
                      "$value${"kg".tr}",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        fontFamily: poppins,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
        ],
      ),
    );
  }
}
