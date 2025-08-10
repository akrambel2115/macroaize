import 'package:flutter/cupertino.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
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
            int minWeight = 50;

            FixedExtentScrollController weightController = FixedExtentScrollController(
              initialItem: ConstantUserMaster.desiredGoal - minWeight,
            );

            return Container(
              margin: const EdgeInsets.all(15),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.theme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CupertinoPicker(
                scrollController: weightController,
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  controller.onChangeDesiredWeight(minWeight + index);
                },
                children: List.generate(40, (index) {
                  return Center(
                    child: Text(
                      "${minWeight + index}${"kg".tr}",
                      style: TextStyle(
                        fontSize: 18,
                        color: context.theme.scaffoldBackgroundColor,
                        fontFamily: poppins,
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
          Spacer(),
          GetBuilder<PersonalDetailsController>(
            builder: (controller) {
              return GestureDetector(
                onTap: () {
                  ConstantUserMaster.desiredGoal = controller.selectedDesiredWeight;
                  SharedPref.saveInt(SharePrefKey.desiredWeight,ConstantUserMaster.desiredGoal);
                  controller.onChangeSelectedView(0);
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  margin: EdgeInsets.only(left: 8,right: 8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.theme.focusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Update".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),
                ).paddingOnly(top: 30),
              );
            },
          ),
        ],
      ),
    );
  }
}
