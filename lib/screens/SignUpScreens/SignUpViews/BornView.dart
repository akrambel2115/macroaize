import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class BornView extends GetView<SignUpController> {
  const BornView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  // Back button moved to the SignUp scaffold to keep layout consistent
        Text(
          "Where were you born?".tr,
          style: context.theme.textTheme.headlineLarge,
        ).paddingOnly(top: 20),
        Text(
          "This Will be used to calibrate your custom plan".tr,
          style: context.theme.textTheme.titleSmall,
        ).paddingOnly(top: 10, bottom: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
    // Month Picker
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
      color: context.theme.brightness == Brightness.light ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(builder: (controller) {
                  return CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: controller.selectedMonth,
                    ),
                    onSelectedItemChanged: (index) {
                      controller.selectedMonth = index;
                      controller.update();
                    },
                    children:
                    controller.months
                        .map(
                          (month) => pickerText(
                        month.tr,
                        controller.selectedMonth ==
                            controller.months.indexOf(month),context,
                      ),
                    )
                        .toList(),
                  );
                },),
              ),
            ),
            SizedBox(width: 10),
    // Day Picker
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
      color: context.theme.brightness == Brightness.light ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(builder: (controller) {
                  return CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: controller.selectedDay - 1,
                    ),
                    onSelectedItemChanged: (index) {
                      controller.selectedDay = index + 1;
                      controller.updateDaysInMonth();
                      controller.update();
                    },
                    children:
                    controller.days
                        .map((day) => pickerText(
                        day.toString(),
                        controller.selectedDay == day,context,
                      ),
                    ).toList(),
                  );
                },),
              ),
            ),
            SizedBox(width: 10),
    Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
      color: context.theme.brightness == Brightness.light ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(builder: (controller) {
                  return CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: controller.years.indexOf(
                        controller.selectedYear,
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      controller.selectedYear = controller.years[index];
                      controller.update();
                    },
                    children:
                    controller.years
                        .map(
                          (year) => pickerText(
                        year.toString(),
                        controller.selectedYear == year,context,
                      ),
                    )
                        .toList(),
                  );
                },),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        // Birthday Lottie: expand to fill the space between scrollers and footer
        Expanded(
          child: Center(
            child: Lottie.asset(
              'assets/lottie/birthdate.json',
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // go back to Goal screen
                  controller.selectedView = 3;
                  controller.update();
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Previous'.tr,
                    style: context.theme.textTheme.titleMedium?.copyWith(color: context.theme.primaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  controller.onChangeView();
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.theme.focusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Continue".tr,
                    style: context.theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ).paddingOnly(top: 30),
      ],
    );
  }

  Widget pickerText(String text, bool isSelected,BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: context.theme.brightness == Brightness.light
        ? Colors.black
        : (isSelected ? context.theme.scaffoldBackgroundColor : Colors.grey),
        ),
      ),
    );
  }
}
