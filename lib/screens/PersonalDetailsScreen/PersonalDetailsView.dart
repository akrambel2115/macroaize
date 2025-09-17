import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/UpdateScreen/BornUpdate.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/UpdateScreen/CurrentWeightUpdate.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpViews/GenderView.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/UpdateScreen/HeightUpdate.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/UpdateScreen/UpdateGoal.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';

// View displaying and navigating personal detail editing screens.
class PersonalDetailsView extends GetView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.selectedView == 0) {
          if (Get.isRegistered<SettingController>()) {
            Get.find<SettingController>().update();
          }
          Get.back();
        } else {
          controller.onChangeSelectedView(0);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          title: Text(
            "Personal Details".tr,
            style: context.theme.textTheme.headlineMedium,
          ),
          actions: [
            GetBuilder<PersonalDetailsController>(builder: (ctrl) {
              if (ctrl.selectedView == 0) return SizedBox.shrink();
              return TextButton(
                onPressed: ctrl.hasChanges ? () => ctrl.saveCurrentView() : null,
                child: Text(
                  'Save'.tr,
                  style: TextStyle(
                    color: ctrl.hasChanges ? AppColor.primaryOrange : AppColor.neutralGrey200,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
          leading: AppWidgets.backButton(context, () {
            if (controller.selectedView == 0) {
              if (Get.isRegistered<SettingController>()) {
                Get.find<SettingController>().update();
              }
              Get.back();
            } else {
              controller.onChangeSelectedView(0);
            }
          }),
        ),
        body: GetBuilder<PersonalDetailsController>(builder: (controller) {
          if (controller.selectedView == 0) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
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
                          title: Text(
                            "Goal Weight".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            "${ConstantUserMaster.desiredGoal}${'kg'.tr}",
                            style: context.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              controller.onChangeSelectedView(1);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
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
                        ),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.92,
                            child: Divider(
                              color: context.theme.brightness == Brightness.dark
                                  ? AppColor.neutralGrey700
                                  : AppColor.neutralGrey200,
                            ),
                          ),
                        ),

                        ListTile(
                          onTap: () {
                            controller.onChangeSelectedView(2);
                          },
                          title: Text(
                            "Current Weight".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            "${ConstantUserMaster.weight}${"kg".tr}",
                            style: context.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(5),
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
                              color: context.theme.brightness == Brightness.dark
                                  ? AppColor.neutralGrey700
                                  : AppColor.neutralGrey200,
                            ),
                          ),
                        ),

                        ListTile(
                          onTap: () {
                            controller.onChangeSelectedView(3);
                          },
                          title: Text(
                            "Height".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            "${ConstantUserMaster.height}${"cm".tr}",
                            style: context.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(5),
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
                              color: context.theme.brightness == Brightness.dark
                                  ? AppColor.neutralGrey700
                                  : AppColor.neutralGrey200,
                            ),
                          ),
                        ),

                        ListTile(
                          onTap: () {
                            controller.onChangeSelectedView(4);
                          },
                          title: Text(
                            "Date Of Birth".tr,
                            style: context.theme.textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            ConstantUserMaster.bornDay,
                            style: context.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(5),
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
                ],
              ),
            );
          } else if (controller.selectedView == 1) {
            return GoalUpdate();
          } else if (controller.selectedView == 2) {
            return CurrentWeightUpdate();
          } else if (controller.selectedView == 3) {
            return HeightUpdate();
          } else if (controller.selectedView == 4) {
            return BornUpdate();
          } else {
            return GenderView();
          }
        })
      ),
    );
  }
}
