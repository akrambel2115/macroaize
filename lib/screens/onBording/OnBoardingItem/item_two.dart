import 'package:flutter/material.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:foodcalorietracker/screens/onBording/OnBoardingController.dart';
import 'package:get/get.dart';
import '../../../constant/AppColor.dart';
import '../../../widgets/customText.dart';

class OnBoardingTwo extends GetView<OnBoardingController> {
  const OnBoardingTwo({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
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
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: CustomText(
                      textAlign: TextAlign.center,
                      text: '${"Welcome".tr} \n${Get.find<AppConfigService>().appName}',
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
                      text: 'In-depth nutrition analyses'.tr,
                      fontSize: 18.0,
                      fontColor: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Icon(
                        Icons.insights,
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
                          'We will keep your informed about your food choicer and their nutritional content'
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
