import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodView.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingView.dart';
import 'package:foodcalorietracker/screens/leadingScreen/ExitDailog.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingController.dart';
import 'package:get/get.dart';

class LeadingView extends GetView<LeadingController> {
  const LeadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showExitConfirmationDialog(context: context);
        return Future(() => true,);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton:  FloatingActionButton(onPressed: () {
          print("Hello on Tap");
          Get.toNamed(Routes.chatView);
        },
          backgroundColor: context.theme.focusColor,
          shape: CircleBorder(),
          child:Icon(Icons.chat,color: context.theme.scaffoldBackgroundColor,size: 30,),
        ),
          bottomNavigationBar: GetBuilder<LeadingController>(
            builder: (controller) {
              return SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  // space items evenly
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.changeTabIndex(0);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home,
                              color: controller.currentIndex == 0
                                  ? context.theme.focusColor
                                  : Colors.grey,
                            ),
                            Text(
                              'Home'.tr,
                              style: TextStyle(
                                color: controller.currentIndex == 0
                                    ? context.theme.focusColor
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.changeTabIndex(1);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppAssets.scanHomeIcon,
                              fit: BoxFit.fill,
                              height: 22,
                              width: 22,
                              color: controller.currentIndex == 1
                                  ? context.theme.focusColor
                                  : Colors.grey,
                            ),
                            Text('Calorie'.tr,
                                style: TextStyle(
                                  color: controller.currentIndex == 1
                                      ? context.theme.focusColor
                                      : Colors.grey,
                                )),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.changeTabIndex(2);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Icon(
                              Icons.analytics_outlined,
                              color: controller.currentIndex == 2
                                  ? context.theme.focusColor
                                  : Colors.grey,
                            ),
                            Text('Analytics'.tr,
                                style: TextStyle(
                                  color: controller.currentIndex == 2
                                      ? context.theme.focusColor
                                      : Colors.grey,
                                )),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          controller.changeTabIndex(3);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings,

                              color: controller.currentIndex == 3
                                  ? context.theme.focusColor
                                  : Colors.grey,
                            ),
                            Text('Setting'.tr,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  color: controller.currentIndex == 3
                                      ? context.theme.focusColor
                                      : Colors.grey,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).paddingOnly(bottom: MediaQuery.of(context).padding.bottom+5);
            },
          ),

          body: GetBuilder<LeadingController>(
            builder: (controller) {
              if (controller.currentIndex == 0) {
                return HomeView();
              } else if (controller.currentIndex == 1) {
                return ScanFoodView();
              } else if (controller.currentIndex == 2) {
                return  AnalyticsView();
              } else {
                return SettingView();
              }
            },
          )),
    );
  }
}
