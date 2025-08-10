import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import '../../../constant/FontFamily.dart';
import '../../../widgets/AppWidgets.dart';

class GoalScreen extends GetView<SignUpController> {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWidgets.backButton(context, () {
            Get.back();
          }),
          Text(
            "What is your goal?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
          Text(
            "This helps is generate a plan for your calorie intake.".tr,
            style: context.theme.textTheme.titleSmall,
          ).paddingOnly(top: 10, bottom: 10),
          GestureDetector(
            onTap: () {
              controller.onChangeGoal("Gain Weight");
            },
            child: GetBuilder<SignUpController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWGoal == "Gain Weight"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "Gain Weight".tr,
                      style: context.theme.textTheme.titleMedium,
                    ),
                  ),
                ).paddingOnly(bottom: 10, top: 15);
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.onChangeGoal("Lose Weight");
            },
            child: GetBuilder<SignUpController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWGoal == "Lose Weight"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "Lose Weight".tr,
                      style: context.theme.textTheme.titleMedium,
                    ),
      
                  ),
                ).paddingOnly(bottom: 10, top: 15);
              },
            ),
          ),
          Text(
            "Choose your desired weight?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20,bottom: 10),
          GetBuilder<SignUpController>(builder: (controller) {
            return Text(
              controller.selectedWGoal,
              style: context.theme.textTheme.titleSmall,
            ).paddingOnly(top: 10, bottom: 10);
          },),
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
                controller.onChangeDesiredWeight(50 + index);
              },
              children:List.generate(40, (index) {
                return Center(
                  child: Text(
                    "${50 + index} ${"kg".tr}",
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
          GetBuilder<SignUpController>(
            builder: (controller) {
              return GestureDetector(
                onTap: () {
                  if(controller.selectedWGoal.isNotEmpty)
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
                    controller.selectedWGoal.isNotEmpty
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Continue".tr,
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
