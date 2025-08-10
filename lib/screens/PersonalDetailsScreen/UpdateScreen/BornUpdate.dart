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
              // Month Picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor,
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
                          controller.updateDaysInMonth(); // update day list if month changes
                          controller.update();
                        },
                        children: controller.months.map((month) {
                          final isSelected = controller.months.indexOf(month) == controller.selectedMonth;
                          return pickerText(month, isSelected, context);
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Day Picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor,
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
                          controller.update();
                        },
                        children: controller.days.map((day) {
                          final isSelected = controller.selectedDay == day;
                          return pickerText(day.toString(), isSelected, context);
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Year Picker
              Expanded(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor,
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
                          controller.updateDaysInMonth(); // in case Feb/Leap year
                          controller.update();
                        },
                        children: controller.years.map((year) {
                          final isSelected = controller.selectedYear == year;
                          return pickerText(year.toString(), isSelected, context);
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },),


        Spacer(),
          GestureDetector(
            onTap: () {
              controller.updateBornDay();
              controller.onChangeSelectedView(0);
            },
            child: Container(
              alignment: Alignment.center,
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.theme.focusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Update".tr,
                style: context.theme.textTheme.titleMedium,
              ),
            ).paddingOnly(top: 30),
          ),
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
