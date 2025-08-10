import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/Appkey.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => HomeController());
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        title: Text(appName, style: context.theme.textTheme.headlineMedium),
        actions: [
          GestureDetector(
            onTap: () {
              Get.toNamed(Routes.premiumView);
            },
            child: Image.asset(AppAssets.crownIcon, height: 35, width: 60),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 90,
                child: GetBuilder<HomeController>(
                  builder: (controller) {
                    return ListView.builder(
                      shrinkWrap: true,
                      controller: controller.scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.dates.length,
                      itemBuilder: (context, index) {
                        bool isToday =
                            controller.dates[index].day == controller.today.day;
                        return GestureDetector(
                          onTap: () {
                            controller.dateFilter(index);
                          },
                          child: Container(
                            margin: EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color:
                                  isToday
                                      ? context.theme.focusColor
                                      : context.theme.cardColor,
                            ),
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isToday ? Colors.black : Colors.grey,
                                      style: BorderStyle.solid,
                                      width: isToday ? 2 : 1,
                                    ),
                                    // Dotted effect simulation
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('E')
                                          .format(controller.dates[index])
                                          .substring(0, 1),
                                      // First letter of weekday
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isToday
                                                ? context
                                                    .theme
                                                    .scaffoldBackgroundColor
                                                : context.theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  controller.dates[index].day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: poppins,
                                    fontWeight:
                                        isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        isToday
                                            ? context
                                                .theme
                                                .scaffoldBackgroundColor
                                            : context.theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10),
                child: GetBuilder<HomeController>(
                  builder: (controller) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Track Food".tr,
                              style: context.textTheme.headlineMedium,
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () {
                                showMealSelectionSheet(context);
                              },
                              child: Image.asset(
                                AppAssets.moreIcon,
                                height: 30,
                                color: context.theme.focusColor,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${controller.consumedKcal} kcal",
                                    style:
                                        context.theme.textTheme.headlineMedium,
                                  ),
                                  Text(
                                    "Consumed".tr,
                                    style: context.theme.textTheme.titleSmall,
                                  ),
                                ],
                              ).paddingOnly(right: 5),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 120,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: CircularProgressIndicator(
                                        strokeAlign: 7,
                                        backgroundColor:
                                            context
                                                .theme
                                                .scaffoldBackgroundColor,
                                        value:
                                            controller.isLoading
                                                ? 0.0
                                                : controller.consumedKcal /
                                                    ConstantUserMaster
                                                        .calorieGoal,

                                        strokeWidth: 10,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              context.theme.focusColor,
                                            ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        ConstantUserMaster.calorieGoal
                                            .toString(),
                                        style:
                                            context
                                                .theme
                                                .textTheme
                                                .headlineLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${controller.remainingKcal} kcal",
                                    style:
                                        context.theme.textTheme.headlineMedium,
                                  ),
                                  Text(
                                    "Remaining".tr,
                                    style: context.theme.textTheme.titleSmall,
                                  ),
                                ],
                              ).paddingOnly(left: 5),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: NutrientProgress(
                                name: "Protein".tr,
                                value: controller.consumedProtein.toDouble(),
                                maxValue:
                                    ConstantUserMaster.proteinGoal.toDouble(),
                                color: Colors.pink,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: NutrientProgress(
                                name: "Carbs".tr,
                                value: controller.consumedCarbs.toDouble(),
                                maxValue:
                                    ConstantUserMaster.carbGoal.toDouble(),
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: NutrientProgress(
                                name: "Fats".tr,
                                value: controller.consumedFats.toDouble(),
                                maxValue:
                                    ConstantUserMaster.fatsGoal.toDouble(),
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ).paddingOnly(top: 20, bottom: 10),
                      ],
                    );
                  },
                ),
              ).paddingOnly(top: 15, bottom: 15),
              Row(
                children: [
                  Text("History".tr, style: context.textTheme.headlineMedium),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(
                        Routes.historyView,
                        arguments: {"type": "All"},
                      );
                    },
                    child: Text(
                      "View All".tr,
                      style: TextStyle(
                        color: context.theme.focusColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: poppins,
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(left: 5, right: 5),
              Card(
                color: context.theme.cardColor,
                child: ListTile(
                  onTap: () {
                    Get.toNamed(
                      Routes.historyView,
                      arguments: {"type": "BreakFast"},
                    );
                  },
                  minTileHeight: 70,
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Image.asset(AppAssets.breakfast).paddingAll(10),
                  ),
                  title: Text(
                    "BreakFast".tr,
                    style: context.theme.textTheme.headlineSmall,
                  ),
                ),
              ).paddingOnly(top: 10),
              Card(
                color: context.theme.cardColor,
                child: ListTile(
                  onTap: () {
                    Get.toNamed(
                      Routes.historyView,
                      arguments: {"type": "Lunch"},
                    );
                  },
                  minTileHeight: 70,
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Image.asset(AppAssets.lunch).paddingAll(10),
                  ),
                  title: Text(
                    "Lunch".tr,
                    style: context.theme.textTheme.headlineSmall,
                  ),
                ),
              ).paddingOnly(top: 1),
              Card(
                color: context.theme.cardColor,
                child: ListTile(
                  onTap: () {
                    Get.toNamed(
                      Routes.historyView,
                      arguments: {"type": "snack(s)"},
                    );
                  },
                  minTileHeight: 70,
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Image.asset(AppAssets.snacks).paddingAll(10),
                  ),
                  title: Text(
                    "snack(s)".tr,
                    style: context.theme.textTheme.headlineSmall,
                  ),
                ),
              ).paddingOnly(top: 1),
              Card(
                color: context.theme.cardColor,
                child: ListTile(
                  onTap: () {

                    Get.toNamed(
                      Routes.historyView,
                      arguments: {"type": "Dinner"},
                    );
                  },
                  minTileHeight: 70,
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                    ),
                    child: Image.asset(AppAssets.dinner).paddingAll(10),
                  ),
                  title: Text(
                    "Dinner".tr,
                    style: context.theme.textTheme.headlineSmall,
                  ),
                ),
              ).paddingOnly(top: 1),
            ],
          ),
        ),
      ),
    );
  }

  void showMealSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: context.theme.cardColor,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which meal would you like to track?'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.theme.focusColor,
                  fontFamily: poppins,
                ),
              ).paddingOnly(top: 10),
              const SizedBox(height: 12),
              ...['BreakFast', 'Lunch', 'snack(s)', 'Dinner'].map((meal) {
                return ListTile(
                  title: Text(meal.tr, style: context.textTheme.titleMedium),
                  trailing: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add, color: context.theme.focusColor),
                  ),
                  onTap: () {
                    Navigator.pop(context); // close bottom sheet
                    Get.toNamed(Routes.localFoodView,arguments: {"value" : meal});
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class NutrientProgress extends StatelessWidget {
  final String name;
  final double value;
  final double maxValue;
  final Color color;

  const NutrientProgress({
    super.key,
    required this.name,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: poppins,
            color: context.theme.primaryColor,
          ),
        ),
        SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              height: 10,
              width: (value / maxValue) * 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),

        SizedBox(height: 4),
        Text(
          "$value / $maxValue g",
          style: TextStyle(
            fontSize: 12,
            color: context.theme.primaryColor,
            fontFamily: poppins,
          ),
        ),
      ],
    );
  }
}
