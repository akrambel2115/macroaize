
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/screens/historyScreen/DeleteDailog.dart';
import 'package:foodcalorietracker/screens/historyScreen/HistoryController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: AppWidgets.backButton(context, () {
          Get.back();
        }),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text("History".tr, style: context.textTheme.headlineMedium),
      ),
      body: GetBuilder<HistoryController>(
        builder: (controller) {
          if(controller.sqlHistory.isNotEmpty)
            {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: controller.sqlHistory.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(top: 10),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: context.theme.cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(controller.sqlHistory[index].type.toString(),style: context.textTheme.headlineMedium,),
                              Spacer(),
                              GestureDetector(
                                  onTap: () {
                                    showCustomDeleteDialog(onDelete: () {
                                      controller.dbHelper.deleteCalorieHistory(controller.sqlHistory[index].id!);
                                      controller.getHistory();
                                    },context: context);
                                  },
                                  child: Icon(Icons.delete_outline,color: Colors.red,size: 30,))

                            ],).paddingOnly(bottom: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                foregroundImage: controller.sqlHistory[index].image != null ? FileImage(
                                  File(controller.sqlHistory[index].image),
                                ) : AssetImage(AppAssets.oneBodyImage),
                              ),
                              Expanded(child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                Column(children: [
                                  Text("Calorie".tr,style: context.textTheme.titleSmall,),
                                  Text(controller.sqlHistory[index].calorie.toString(),style: context.textTheme.headlineMedium,),
                                  SizedBox(height: 10,),
                                  Text("Carbs".tr,style: context.textTheme.titleSmall,),
                                  Text(controller.sqlHistory[index].carbs.toString(),style: context.textTheme.headlineMedium,)
                                ],),
                                Column(children: [
                                  Text("Protein".tr,style: context.textTheme.titleSmall,),
                                  Text(controller.sqlHistory[index].protein.toString(),style: context.textTheme.headlineMedium,),
                                  SizedBox(height: 10,),
                                  Text("Fats".tr,style: context.textTheme.titleSmall,),
                                  Text(controller.sqlHistory[index].fats.toString(),style: context.textTheme.headlineMedium,)
                                ],
                                ),
                              ],))
                            ],).paddingOnly(top: 10),

                        ],
                      ),
                    );
                  },
                ),
              );
            }else{
            return   Center(
              child: Text(
                "History not found".tr,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
              ),
            );
          }
        },
      ),
    );
  }
}
