import 'package:flutter/material.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/screens/AdjustGoals/adjust_goals_controller.dart';
import 'package:macroaize/screens/AdjustGoals/AutoGenerateGoal/auto_goal_view.dart';
import 'package:macroaize/screens/AdjustGoals/AutoGenerateGoal/auto_height_width_view.dart';
import 'package:macroaize/screens/AdjustGoals/AutoGenerateGoal/auto_workout_view.dart';
import 'package:macroaize/screens/AdjustGoals/updateDailog/show_update_goal_dialog.dart';
import 'package:macroaize/widgets/app_widgets.dart';
import 'package:macroaize/widgets/custom_button.dart';
import 'package:get/get.dart';

import '../../constant/app_color.dart';
import '../SettingScreen/setting_controller.dart';

class AdjustGoalsView extends GetView<AdjustGoalsController> {
  const AdjustGoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (controller.isAutoGenerate == false) {
          if (Get.isRegistered<SettingController>()) {
            Get.find<SettingController>().update();
          }
        } else {
          controller.onChangeAutoGenerate(false);
        }
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
          actions: const [],
        ),
        body: GetBuilder<AdjustGoalsController>(
          builder: (controller) {
            if (controller.isAutoGenerate) {
              if (controller.selectedUpdateGoalView == 1) {
                return AutoWorkoutView();
              } else if (controller.selectedUpdateGoalView == 2) {
                return AutoHeightWidth();
              } else {
                return AutoGoalView();
              }
            } else {
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
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
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
                                color: AppColor.neutralWhite,
                              ),
                            ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey700
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
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
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
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
                                color: AppColor.neutralWhite,
                              ),
                            ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey800
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
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
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
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
                                color: AppColor.neutralWhite,
                              ),
                            ),
                          ),
                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.92,
                              child: Divider(
                                color:
                                    context.theme.brightness == Brightness.dark
                                        ? AppColor.neutralGrey800
                                        : AppColor.neutralGrey200,
                              ),
                            ),
                          ),
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
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
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
                                color: AppColor.neutralWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).paddingOnly(bottom: 10),
                    CustomButtom(
                      backgroundcolor: context.theme.focusColor,
                      btncolor:
                          context.theme.brightness == Brightness.light
                              ? Colors.white
                              : context.theme.primaryColor,
                      btntext: "Auto Generate Goal".tr,
                      ontap: () {
                        controller.onChangeAutoGenerate(true);
                      },
                    ).paddingOnly(top: 20),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
