import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/MonthHistory.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/UpdateWeight.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/WeekHistory.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/YearHistory.dart';
import 'package:get/get.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AnalyticsController());
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          scrolledUnderElevation: 0,
          backgroundColor: context.theme.scaffoldBackgroundColor,
          title: Text(
            "OverView".tr,
            style: context.theme.textTheme.headlineMedium,
          ),
        ),
        body: GetBuilder<AnalyticsController>(builder: (controller) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Weight Goal".tr,
                        style: context.theme.textTheme.titleSmall,
                      ),
                      GestureDetector(
                        onTap: () {
                          showUpdateWeightDialog(context, ConstantUserMaster.desiredGoal.toString(), (p0) async {
                            ConstantUserMaster.desiredGoal = int.parse(p0);
                            controller.update();
                            await SharedPref.saveInt(SharePrefKey.desiredWeight,ConstantUserMaster.desiredGoal);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.theme.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "Update".tr,
                            style: TextStyle(
                              color: context.theme.scaffoldBackgroundColor,
                              fontFamily: poppins,
                              fontSize: 14,
                            ),
                          ),
                        ).paddingOnly(left: 10),
                      ),
                    ],
                  ).paddingOnly(top: 10, bottom: 0),
                  Row(
                    children: [
                      Text(
                        "${ConstantUserMaster.desiredGoal}",
                        style: context.theme.textTheme.headlineMedium,
                      ).paddingOnly(right: 5),
                      Text("kg".tr,style: context.textTheme.headlineMedium,)
                    ],
                  ).paddingOnly(top: 0, bottom: 5),
                  Text(
                    "Current Weight".tr,
                    style: context.theme.textTheme.titleSmall,
                  ).paddingOnly(top: 5, bottom: 0),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ConstantUserMaster.weight.toString(),
                              style: context.theme.textTheme.headlineMedium,
                            ).paddingOnly(right: 5),
                            Text("kg".tr,style: context.textTheme.headlineMedium,)
                          ],
                        ),
                        Text(
                          "Try to update once a week so we can adjust your plan to ensure you hit your goal".tr,
                          style: context.theme.textTheme.titleSmall,
                          maxLines: 3,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                showUpdateWeightDialog(
                                  context,
                                  ConstantUserMaster.weight.toString(),
                                      (p0) async {
                                    ConstantUserMaster.weight = int.parse(p0);
                                    controller.update();
                                    await SharedPref.saveInt(SharePrefKey.weight,ConstantUserMaster.weight);
                                  },
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: context.theme.focusColor,
                                ),
                                child: Text(
                                  "Update Weight".tr,
                                  style: context.theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ],
                        ).paddingOnly(top: 10),
                      ],
                    ),
                  ).paddingOnly(top: 5, bottom: 10),
                  TabBar(
                    unselectedLabelColor: AppColor.grey,
                    physics: NeverScrollableScrollPhysics(),
                    automaticIndicatorColorAdjustment: true,
                    dividerColor: AppColor.grey,
                    enableFeedback: true,
                    indicatorWeight: 1,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: context.theme.focusColor,
                    labelColor: context.theme.focusColor,
                    labelStyle: TextStyle(fontFamily: poppins, fontSize: 16),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: poppins,
                      fontSize: 16,
                    ),
                    tabs: [
                      Tab(text: "Week".tr),
                      Tab(text: "Month".tr),
                      Tab(text: "Year".tr),
                    ],
                  ).paddingOnly(bottom: 20),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        WeekHistory(),
                        MonthHistory(),
                        YearHistory()],
                    ),
                  ),
                ],
              ),
            ),
          );
        },),
      ),
    );
  }
}
