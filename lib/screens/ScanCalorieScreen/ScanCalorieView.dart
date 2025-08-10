import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ScanCalorieView extends GetView<ScanCalorieController> {
  const ScanCalorieView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppWidgets.backButton(context, () {

          Get.back();

        }),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text("Calorie Tracker".tr, style: context.textTheme.headlineMedium),
      ),
      bottomNavigationBar: GetBuilder<ScanCalorieController>(
        builder: (controller) {
          if (controller.calorie != 0) {
            return GestureDetector(
              onTap: () async {
                await controller.onAddButton(context);
              },
              child: Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom+5,
                ),
                height: 50,
                decoration: BoxDecoration(
                  color: context.theme.focusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Add Calorie".tr,
                  style: context.textTheme.headlineMedium,
                ),
              ),
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
      body: GetBuilder<ScanCalorieController>(
        builder: (controller) {
          if (controller.isLoading) {
            return Center(
              child: SizedBox(
                height: 300,
                width: 300,

                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Opacity(
                          opacity: 0.7,
                          child: Image.file(
                            controller.image,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Lottie.asset(AppAssets.scanFood, fit: BoxFit.fill),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Column(
              children: [
                Image.file(
                  controller.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ).paddingOnly(bottom: 10),

                if (controller.calorie != 0)
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Quantity".tr,
                            style: context.textTheme.headlineMedium,
                          ),
                          Spacer(),
                          Container(
                            width: 100,
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: context.theme.focusColor,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => controller.decrementQuantity(),
                                  child: Container(
                                    height: 30,
                                    width: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColor.white,
                                    ),
                                    child: Text(
                                      "-",
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: AppColor.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GetBuilder<ScanCalorieController>(
                                    builder: (controller) {
                                      return Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          controller.quantity.toString(),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: AppColor.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () => controller.incrementQuantity(),
                                  child: Container(
                                    height: 30,
                                    width: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColor.white,
                                    ),

                                    child: Text(
                                      "+",
                                      style: TextStyle(
                                        color: AppColor.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).paddingOnly(left: 10, right: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "Calorie".tr,
                                  style: context.textTheme.headlineMedium,
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.theme.focusColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: GetBuilder<ScanCalorieController>(
                                    builder: (controller) {
                                      return Text(
                                        "${controller.calorie}",
                                        style: context.textTheme.titleMedium,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "Protein".tr,
                                  style: context.textTheme.headlineMedium,
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.theme.focusColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: GetBuilder<ScanCalorieController>(
                                    builder: (controller) {
                                      return Text(
                                        "${controller.protein}",
                                        style: context.textTheme.titleMedium,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).paddingOnly(top: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "Carbs".tr,
                                  style: context.textTheme.headlineMedium,
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.theme.focusColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: GetBuilder<ScanCalorieController>(
                                    builder: (controller) {
                                      return Text(
                                        "${controller.carbs}",
                                        style: context.textTheme.titleMedium,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "Fats".tr,
                                  style: context.textTheme.headlineMedium,
                                ),
                                SizedBox(height: 5),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.theme.focusColor,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: GetBuilder<ScanCalorieController>(
                                    builder: (controller) {
                                      return Text(
                                        "${controller.fats}",
                                        style: context.textTheme.titleMedium,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).paddingOnly(top: 10),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  Routes.chatView,
                                  arguments: {"image": controller.image},
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: context.theme.focusColor,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      AppAssets.ai,
                                      height: 40,
                                    ).paddingOnly(right: 10),
                                    Text(
                                      "Ask With Open AI".tr,
                                      style: context.textTheme.headlineMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).paddingOnly(top: 10),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      "This picture not available Calorie,Protein,Carbs and Fats,".tr,
                      textAlign: TextAlign.center,
                      style: context.textTheme.titleMedium,
                    ),
                  ).marginOnly(top: 100),
              ],
            );
          }
        },
      ),
    );
  }
}
