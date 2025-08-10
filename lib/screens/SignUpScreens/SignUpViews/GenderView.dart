import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';

class GenderView extends GetView<SignUpController> {
  const GenderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        AppWidgets.backButton(context, () {
          Get.back();
        }),
        Text(
          "Choose Your Gender".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20),
        Text(
          "This Will be used to calibrate your custom plan".tr,
          style: context.theme.textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 10),
        GestureDetector(
          onTap: () {
            controller.onChangeGender("Male");
          },
          child: GetBuilder<SignUpController>(
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
          child: GetBuilder<SignUpController>(
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
        GestureDetector(
          onTap: () {
            controller.onChangeGender("Other");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedGender == "Other"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Other".tr ,
                    style: context.theme.textTheme.titleMedium,
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(AppAssets.other),
                  ),
                ),
              );
            },
          ),
        ),
        Spacer(),
        GetBuilder<SignUpController>(
          builder: (controller) {
            return GestureDetector(
              onTap: () {
                if(controller.selectedGender.isNotEmpty)
                  {
                    controller.onChangeView();
                  }
              },
              child: Container(
                alignment: Alignment.center,
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      controller.selectedGender.isNotEmpty
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Continue".tr,
                  style: context.theme.textTheme.titleMedium,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
