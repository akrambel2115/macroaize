import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import '../../../widgets/AppWidgets.dart';

class StoppingGoalView extends GetView<SignUpController> {
  const StoppingGoalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppWidgets.backButton(context, () {
          Get.back();
        }),
        Text(
          "What's stopping you from reaching your goals?".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20, bottom: 20),
        GestureDetector(
          onTap: () {
            controller.onChangeStoppingGoal("Lack of consistency");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal == "Lack of consistency"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Lack of consistency".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),

                  leading: Container(
                    height: 50,
                    width: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(Icons.bar_chart),
                  ),
                ),
              ).paddingOnly(bottom: 10, top: 15);
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.onChangeStoppingGoal("Unhealthy eating habits");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal ==
                              "Unhealthy eating habits"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Unhealthy eating habits".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),

                  leading: Container(
                    height: 50,
                    width: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(Icons.bar_chart),
                  ),
                ),
              ).paddingOnly(bottom: 10, top: 15);
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.onChangeStoppingGoal("Lack of supports");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal == "Lack of supports"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Lack of supports".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),

                  leading: Container(
                    height: 50,
                    width: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(Icons.support),
                  ),
                ),
              ).paddingOnly(bottom: 10, top: 15);
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.onChangeStoppingGoal("Busy schedule");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal == "Busy schedule"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Busy schedule".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),

                  leading: Container(
                    height: 50,
                    width: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(Icons.date_range),
                  ),
                ),
              ).paddingOnly(bottom: 10, top: 15);
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.onChangeStoppingGoal("Lack of meal inspiration");
          },
          child: GetBuilder<SignUpController>(
            builder: (controller) {
              return Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal ==
                              "Lack of meal inspiration"
                          ? context.theme.focusColor
                          : context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    "Lack of meal inspiration".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),

                  leading: Container(
                    height: 50,
                    width: 50,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Icon(Icons.apple),
                  ),
                ),
              ).paddingOnly(bottom: 10, top: 15);
            },
          ),
        ),
        Spacer(),
        GetBuilder<SignUpController>(
          builder: (controller) {
            return GestureDetector(
              onTap: () {
                if (controller.selectedStoppingGoal.isNotEmpty) {
                  controller.onChangeView();
                }
              },
              child: Container(
                alignment: Alignment.center,
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      controller.selectedStoppingGoal.isNotEmpty
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
    );
  }
}
