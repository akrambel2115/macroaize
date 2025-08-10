import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsController.dart';
import 'package:get/get.dart';

class AutoWorkoutView extends GetView<AdjustGoalsController> {
  const AutoWorkoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.only(left: 10,right: 10,bottom: MediaQuery.of(context).padding.bottom,top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "How many workout do you per week?".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
          Text(
            "This will used to calibrate your custom plan".tr,
            style: context.theme.textTheme.titleSmall,
          ).paddingOnly(top: 10, bottom: 10),
          GestureDetector(
            onTap: () {
              controller.onChangeWorkout("0-2");
            },
            child: GetBuilder<AdjustGoalsController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWorkOut == "0-2"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "0-2",
                      style: context.theme.textTheme.titleMedium,
                    ),
                    subtitle: Text("Workout Now and then".tr,style: TextStyle(color: context.theme.primaryColor),),
                    leading: Container(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.scaffoldBackgroundColor,
                      ),
                      child: Icon(Icons.circle),
                    ),
                  ),
                ).paddingOnly(bottom: 10, top: 15);
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.onChangeWorkout("3-5");
            },
            child: GetBuilder<AdjustGoalsController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWorkOut == "3-5"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "3-5",
                      style: context.theme.textTheme.titleMedium,
                    ),
                    subtitle: Text("A few workout per week".tr,style: TextStyle(color: context.theme.primaryColor),),
                    leading: Container(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.scaffoldBackgroundColor,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle,size: 13),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,size: 13,),
                              Icon(Icons.circle,size: 13,),
                            ],)
                        ],),
                    ),
                  ),
                ).paddingOnly(bottom: 10, top: 15);
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.onChangeWorkout("6+");
            },
            child: GetBuilder<AdjustGoalsController>(
              builder: (controller) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWorkOut == "6+"
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      "6+",
                      style: context.theme.textTheme.titleMedium,
                    ),
                    subtitle: Text("Dedicated athlete",style: TextStyle(color: context.theme.primaryColor),),
                    leading: Container(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.theme.scaffoldBackgroundColor,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,size: 10,),
                              Icon(Icons.circle,size: 10,),
                            ],),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,size: 10,),
                              Icon(Icons.circle,size: 10,),
                            ],),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle,size: 10,),
                              Icon(Icons.circle,size: 10,),
                            ],)
                        ],),
                    ),
                  ),
                ).paddingOnly(bottom: 10, top: 15);
              },
            ),
          ),
          Spacer(),
          GetBuilder<AdjustGoalsController>(
            builder: (controller) {
              return GestureDetector(
                onTap:() {
                  if(controller.selectedWorkOut.isNotEmpty)
                  {
                    controller.onChangeView(2);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                    controller.selectedWorkOut.isNotEmpty
                        ? context.theme.focusColor
                        : context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Continue".tr,
                    style: context.theme.textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
