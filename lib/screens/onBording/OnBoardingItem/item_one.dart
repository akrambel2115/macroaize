import 'package:flutter/material.dart';
// AppAssets removed as legacy images are no longer used
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:get/get.dart';

import '../../../constant/Appkey.dart';
import '../../../widgets/customText.dart';

class OnBoardingOne extends StatelessWidget {
  const OnBoardingOne({super.key});

  @override
  Widget build(BuildContext context) {
    final Height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: Stack(
        children: [
          SizedBox(
            height: Height * 0.8,
            child: Column(
              children: [
                Container(
                  height: Height * 0.13,
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
                Container(height: Height * 0.54, color: Colors.black),
                Container(
                  height: Height * 0.13,
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
            // Fixed: Used Align instead of Center
            alignment: Alignment.center,
            child: SingleChildScrollView(
              // Fixed: Prevents overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Important: Prevents infinite height issue
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: CustomText(
                      textAlign: TextAlign.center,
                      text: '${"Welcome".tr} \n$appName',
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
                  // Legacy illustration removed; using neutral placeholder
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
