import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:foodcalorietracker/widgets/customButton.dart';
import 'package:get/get.dart';

import '../../constant/FontFamily.dart';

class PremiumView extends GetView<PremiumController> {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppWidgets.backButton(context, () {
                    Get.back();
                  }).paddingOnly(left: 10, right: 10),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      controller.inAppPurchase.restorePurchases();
                    },
                    child: Text(
                      "Restore".tr,
                      style: context.textTheme.headlineMedium,
                    ).paddingOnly(right: 10),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Get Premium".tr, style: context.textTheme.headlineLarge),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Get All The New Exciting Features".tr,
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ).marginOnly(top: 5, bottom: 10),
              Opacity(opacity: 0.8, child: Image.asset(AppAssets.oneBodyImage)),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ).marginOnly(left: 20, right: 20),
                  Expanded(
                    child: Text(
                      'Unlock Food Scanner'.tr,
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontFamily: poppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(top: 20),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ).marginOnly(left: 20, right: 20),
                  Expanded(
                    child: Text(
                      'Unlock Food Calorie'.tr,
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontFamily: poppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(top: 5),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ).marginOnly(left: 20, right: 20),
                  Expanded(
                    child: Text(
                      'Unlock Unlimited Chat with Ai'.tr,
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontFamily: poppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(top: 5),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ).marginOnly(left: 20, right: 20),
                  Expanded(
                    child: Text(
                      'Unlimited Food Scanner To Calorie'.tr,
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontFamily: poppins,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ).paddingOnly(top: 5),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: GetBuilder<PremiumController>(
                  builder: (controller) {
                    return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(right: 5, left: 5),
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: controller.products.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            controller.onChangeSelectedIndex(index);
                          },
                          child: Container(
                            margin: EdgeInsets.only(left: 5, right: 5),
                            width: MediaQuery.of(context).size.width / 3.3,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color:
                                  controller.selected == index
                                      ? context.theme.cardColor
                                      : context.theme.cardColor,
                              border: Border.all(
                                color:
                                    controller.selected == index
                                        ? context.theme.focusColor
                                        : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (index == 0)
                                  Container(
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: context.theme.focusColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Week".tr,
                                      style: context.textTheme.headlineSmall,
                                    ),
                                  ),
                                if (index == 1)
                                  Container(
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: context.theme.focusColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Month".tr,
                                      style: context.textTheme.headlineSmall,
                                    ),
                                  ),
                                if (index == 2)
                                  Container(
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: context.theme.focusColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "Most Popular".tr,
                                      style: context.textTheme.headlineSmall,
                                    ),
                                  ),
          
                                Text(
                                  controller.products[index].title,
                                  style: context.textTheme.titleMedium,
                                ).paddingOnly(top: 10),
                                Text(
                                  "Subscription".tr,
                                  style: context.textTheme.titleMedium,
                                ),
                                Divider(),
                                Text(
                                  controller.products[index].price,
                                  style: context.textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ).paddingOnly(top: 25),
              SizedBox(height: 10),
              CustomButtom(
                backgroundcolor: context.theme.focusColor,
                btncolor: context.theme.primaryColor,
                btntext: "BUY NOW".tr,
                ontap: () {
                  controller.buy();
                },
              ).marginOnly(left: 20, right: 20, top: 10, bottom: 5),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.openPrivacy();
                      },
                      child: Text(
                        textAlign: TextAlign.center,
                        "Privacy Policy".tr,
                        style: context.theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.openTerms();
                      },
                      child: Text(
                        textAlign: TextAlign.center,
                        "Terms of Condition".tr,
                        style: context.theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
