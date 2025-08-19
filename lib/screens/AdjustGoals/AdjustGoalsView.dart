import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AutoGenerateGoal/AutoGoalView.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AutoGenerateGoal/AutoHeightWidthView.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AutoGenerateGoal/AutoWorkoutView.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/updateDailog/showUpdateGoalDialog.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:foodcalorietracker/widgets/customButton.dart';
import 'package:get/get.dart';

import '../../constant/AppColor.dart';
import '../SettingScreen/SettingController.dart';

class AdjustGoalsView extends GetView<AdjustGoalsController> {
  const AdjustGoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (controller.isAutoGenerate == false) {
          if (Get.isRegistered<SettingController>()) {
            Get.find<SettingController>().update();
          }
          Get.back();
        } else {
          controller.onChangeAutoGenerate(false);
        }
        return Future(() => true,);
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: AppWidgets.backButton(context, () {
            if (controller.isAutoGenerate == false) {
              if (Get.isRegistered<SettingController>()) {
                Get.find<SettingController>().update();
              }
              Get.back();
            } else {
              controller.onChangeAutoGenerate(false);
            }
          }),
          backgroundColor: context.theme.scaffoldBackgroundColor,
          title: Text(
            "Adjust Goals".tr,
            style: context.theme.textTheme.headlineMedium,
          ),
          // No Save button in AppBar; saving occurs in each edit dialog
          actions: const [],
        ),
        body: GetBuilder<AdjustGoalsController>(builder: (controller) {
          if(controller.isAutoGenerate)
            {
              if(controller.selectedUpdateGoalView==1)
                {
                  return AutoWorkoutView();
                }else if(controller.selectedUpdateGoalView==2)
              {
                return AutoHeightWidth();
              }else{
                return AutoGoalView();
              }
            }else{
            return Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            showUpdateGoalDialog(
                              ConstantUserMaster.calorieGoal,
                                  (p0) {
                                controller.updateCalorieGoal(p0);
                              },
                              context,
                              "Update Calorie Goal".tr,
                            );
                          },
                          title: Text(
                            "Calorie Goal".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: GetBuilder<AdjustGoalsController>(
                            builder: (controller) {
                              return Text(
                                ConstantUserMaster.calorieGoal.toString(),
                                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColor.primaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: context.theme.scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                        Center(child: FractionallySizedBox(widthFactor: 0.92, child: Divider(color: AppColor.neutralGrey200))),
                        ListTile(
                          onTap: () {
                            showUpdateGoalDialog(
                              ConstantUserMaster.proteinGoal,
                                  (p0) {
                                controller.updateProteinGoal(p0);
                              },
                              context,
                              "Update Protein Goal".tr,
                            );
                          },
                          title: Text(
                            "Protein goal".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: GetBuilder<AdjustGoalsController>(
                            builder: (controller) {
                              return Text(
                                 ConstantUserMaster.proteinGoal.toString(),
                                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColor.primaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: context.theme.scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                        Center(child: FractionallySizedBox(widthFactor: 0.92, child: Divider(color: AppColor.neutralGrey200))),
                        ListTile(
                          onTap: () {
                            showUpdateGoalDialog(
                              ConstantUserMaster.carbGoal,
                                  (p0) {
                                controller.updateCarbGoal(p0);
                              },
                              context,
                              "Update Carb Goal".tr,
                            );
                          },
                          title: Text(
                            "Carb goal".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: GetBuilder<AdjustGoalsController>(
                            builder: (controller) {
                              return Text(
                                ConstantUserMaster.carbGoal.toString(),
                                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColor.primaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: context.theme.scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                        Center(child: FractionallySizedBox(widthFactor: 0.92, child: Divider(color: AppColor.neutralGrey200))),
                        ListTile(
                          onTap: () {
                            showUpdateGoalDialog(
                              ConstantUserMaster.fatsGoal,
                                  (p0) {
                                controller.updateFatGoal(p0);
                              },
                              context,
                              "Update Fat Goal".tr,
                            );
                          },
                          title: Text(
                            "Fats".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: GetBuilder<AdjustGoalsController>(
                            builder: (controller) {
                              return Text(
                                ConstantUserMaster.fatsGoal.toString(),
                                style: context.theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                          trailing: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColor.primaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: context.theme.scaffoldBackgroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).paddingOnly(bottom: 10),
                  CustomButtom(
                    backgroundcolor: context.theme.focusColor,
                    btncolor: context.theme.brightness == Brightness.light ? Colors.white : context.theme.primaryColor,
                    btntext: "Auto Generate Goal".tr,
                    ontap: () {
                      controller.onChangeAutoGenerate(true);
                    },
                  ).paddingOnly(top: 20),
                ],
              ),
            );
          }

        },),
      ),
    );
  }
}
