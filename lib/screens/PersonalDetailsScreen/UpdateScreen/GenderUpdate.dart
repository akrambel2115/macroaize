import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';
import '../../../constant/AppAssets.dart';

class GenderUpdate extends GetView<PersonalDetailsController> {
  const GenderUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(bottom:MediaQuery.of(context).padding.bottom+10,right: 8,left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Update Your Gender".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20,bottom: 20),

          GestureDetector(
            onTap: () {
              controller.onChangeGender("Male");
            },
            child: GetBuilder<PersonalDetailsController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedGender == "Male"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "Male".tr,
                      style: context.theme.textTheme.titleMedium,
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(AppAssets.maleIcon),
                    ),
                  ),
                ).paddingOnly(bottom: 10);
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.onChangeGender("Female");
            },
            child: GetBuilder<PersonalDetailsController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedGender == "Female"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "Female".tr,
                      style: context.theme.textTheme.titleMedium,
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(AppAssets.female),
                    ),
                  ),
                ).paddingOnly(bottom: 10);
              },
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
