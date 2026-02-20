import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:get/get.dart';

import '../../../shared/services/app_config_service.dart';
import '../../../widgets/custom_text.dart';

class OnBoardingOne extends StatelessWidget {
  const OnBoardingOne({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      body: Stack(
        children: [
          SizedBox(
            height: height * 0.8,
            child: Column(
              children: [
                Container(
                  height: height * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0, 0, 1],
                    ),
                  ),
                ),
                Container(height: height * 0.54, color: Colors.black),
                Container(
                  height: height * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0, 0, 0, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            // center content
            alignment: Alignment.center,
            child: SingleChildScrollView(
              // prevents overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // prevent infinite height
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: CustomText(
                      textAlign: TextAlign.center,
                      text:
                          '${"Welcome".tr} \n${Get.find<AppConfigService>().appName}',
                      fontSize: 26.0,
                      fontColor: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: CustomText(
                      textAlign: TextAlign.center,
                      text: 'Calorie tracking made easy'.tr,
                      fontSize: 18.0,
                      fontColor: Colors.white,
                    ),
                  ),
                  // Illustration placeholder
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 120,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 25,
                    ),
                    child: CustomText(
                      textAlign: TextAlign.center,
                      text:
                          'Just snap a quick photo of your meal and we'
                                  'll do the rest'
                              .tr,
                      fontSize: 16.0,
                      fontColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
