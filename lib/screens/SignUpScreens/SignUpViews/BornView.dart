import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class BornView extends GetView<SignUpController> {
  const BornView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button is in the SignUp scaffold
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
            // Month picker
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color:
                      context.theme.brightness == Brightness.light
                          ? Colors.white
                          : AppColor.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(
                  builder: (controller) {
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
                          controller.months.map((month) {
                            return Center(
                              child: Text(
                                month.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      context.theme.brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            // Day picker
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color:
                      context.theme.brightness == Brightness.light
                          ? Colors.white
                          : AppColor.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(
                  builder: (controller) {
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
                          controller.days.map((day) {
                            return Center(
                              child: Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      context.theme.brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color:
                      context.theme.brightness == Brightness.light
                          ? Colors.white
                          : AppColor.darkCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GetBuilder<SignUpController>(
                  builder: (controller) {
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
                          controller.years.map((year) {
                            return Center(
                              child: Text(
                                year.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      context.theme.brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
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
        ),

        const SizedBox(height: 12),
        // Birthday animation
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
              child: ModernButton(
                text: 'Previous'.tr,
                onPressed: () {
                  controller.selectedView = 3;
                  controller.update();
                },
                style: ModernButtonStyle.secondary,
                size: ModernButtonSize.medium,
                borderRadius: BorderRadius.circular(30),
                height: 50,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ModernButton(
                text: "Continue".tr,
                onPressed: controller.onChangeView,
                style: ModernButtonStyle.primary,
                size: ModernButtonSize.medium,
                borderRadius: BorderRadius.circular(30),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                height: 50,
              ),
            ),
          ],
        ).paddingOnly(top: 30),
      ],
    );
  }
}
