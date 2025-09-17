import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';

class BornUpdate extends GetView<PersonalDetailsController> {
  const BornUpdate({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom+10,left: 8,right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Text(
                  "Month".tr,
                  textAlign: TextAlign.center,
                  style: context.theme.textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: Text(
                  "Day".tr,
                  textAlign: TextAlign.center,
                  style: context.theme.textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: Text(
                  "Year".tr,
                  textAlign: TextAlign.center,
                  style: context.theme.textTheme.headlineSmall,
                ),
              ),
            ],
          ).paddingOnly(top: 20,bottom: 20),
        GetBuilder<PersonalDetailsController>(builder: (controller) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Month picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : context.theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GetBuilder<PersonalDetailsController>(
                    builder: (controller) {
                      return CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: controller.selectedMonth,
                        ),
                        onSelectedItemChanged: (index) {
                          controller.selectedMonth = index;
                          controller.updateDaysInMonth(); // refresh days when month changes
                          controller.setHasChanges(true);
                          controller.update();
                        },
                        children: controller.months.map((month) {
                          return Center(
                            child: Text(
                              month,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Day picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : context.theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GetBuilder<PersonalDetailsController>(
                    builder: (controller) {
                      return CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: controller.selectedDay - 1,
                        ),
                        onSelectedItemChanged: (index) {
                          controller.selectedDay = index + 1;
                          controller.setHasChanges(true);
                          controller.update();
                        },
                        children: controller.days.map((day) {
                          return Center(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Year picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade900
                        : context.theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GetBuilder<PersonalDetailsController>(
                    builder: (controller) {
                      return CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: controller.years.indexOf(controller.selectedYear),
                        ),
                        onSelectedItemChanged: (index) {
                          controller.selectedYear = controller.years[index];
                          controller.updateDaysInMonth(); // handle Feb/leap year
                          controller.setHasChanges(true);
                          controller.update();
                        },
                        children: controller.years.map((year) {
                          return Center(
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },),


        ],
      ),
    );
  }

  Widget pickerText(String text, bool isSelected,BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ?context.theme.scaffoldBackgroundColor : Colors.grey,
        ),
      ),
    );
  }
}
