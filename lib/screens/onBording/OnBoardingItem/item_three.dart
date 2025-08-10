
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:get/get.dart';

import '../../../constant/AppAssets.dart';
import '../../../constant/AppColor.dart';
import '../../../constant/Appkey.dart';
import '../../../widgets/customText.dart';

class OnBoardingThree extends StatelessWidget {
  const OnBoardingThree({super.key});

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
                      text: 'Transform your body'.tr,
                      fontSize: 18.0,
                      fontColor: Colors.white,
                    ),
                  ),
                  Opacity(
                    opacity: 0.9,
                    child: Container(
                      alignment: Alignment.bottomRight,
                      height: 300,
                      padding: EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.fitWidth,
                          image: AssetImage(AppAssets.manBody),
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColor.black.withOpacity(0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              text: "Weight Goal".tr,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                              fontFamily: poppins,
                              fontSize: 16,
                            ),
                            CustomText(
                              text: "65 ${"Kg".tr}",
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                              fontFamily: poppins,
                              fontSize: 18,
                            ),
                          ],
                        ),
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
                          'Today is best time to start working toward your dream body'
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
