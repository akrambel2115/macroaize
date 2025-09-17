import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SetupView extends GetView<SignUpController> {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            textAlign: TextAlign.center,
            "We're setting".tr,
            style: context.theme.textTheme.headlineLarge,
          ).paddingOnly(top: 20),
        ],
      ),
        Text(
        textAlign: TextAlign.center,
        "everything up for you".tr,
        style: context.theme.textTheme.headlineLarge,
      ).paddingOnly(top: 5),
      Text(
        "Customizing health plan....".tr,
        textAlign: TextAlign.center,
        style: context.theme.textTheme.titleSmall,
      ).paddingOnly(top: 15),
        Lottie.asset(
          'assets/lottie/loader.json',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ).paddingOnly(top: 15)
    ],);
  }
}
