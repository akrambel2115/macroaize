import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/MainController.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:foodcalorietracker/routes/app_pages.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingController.dart';
import 'package:get/get.dart';
import '../../ThemeService/ThemeController.dart';

class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SettingController());
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        title: Text(
          "Setting".tr,
          style: context.theme.textTheme.headlineMedium,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              GestureDetector(
                onTap: () {
                  Get.toNamed(Routes.premiumView);
                },
                child: Container(
                  decoration: BoxDecoration(color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Image.asset(AppAssets.crownIcon,height: 35,width: 35,),
                    title: Text("Upgrade to premium",style: context.textTheme.headlineSmall,),
                    subtitle: Text("Unlock unlimited access"),
                  ),


                ),
              ),
              
              ListTile(
                title: Text(
                  "Age".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: GetBuilder<SettingController>(builder: (controller) {
                  return Text(
                    ConstantUserMaster.age.toString(),
                    style: context.textTheme.headlineSmall,
                  );
                },),
              ),
              ListTile(
                title: Text(
                  "Height".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: GetBuilder<SettingController>(builder: (controller) {
                  return Text(
                    "${ConstantUserMaster.height.toString()} cm",
                    style: context.textTheme.headlineSmall,
                  );
                },),
              ),
              ListTile(
                title: Text(
                  "Current Weight".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: GetBuilder<SettingController>(builder: (controller) {
                  return Text(
                    "${ConstantUserMaster.weight.toString()} kg",
                    style: context.textTheme.headlineSmall,
                  );
                },),
              ),
              Divider(color: AppColor.grey),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Customization".tr,
                  style: context.theme.textTheme.titleMedium,
                ),
              ),
              ListTile(
                onTap: () {
                  Get.toNamed(Routes.personalDetailsView);
                },
                title: Text(
                  "Dark Mode".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: CupertinoSwitch(
                  value: Get.find<ThemeController>().isDarkMode,
                  onChanged: (value) async {
                    await Get.find<ThemeController>().toggleTheme(value);
                  },
                ),
              ),
              ListTile(
                onTap: () {
                  Get.toNamed(Routes.languageView);
                },
                title: Text(
                  "Language".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Get.find<MainController>().language,
                      style: context.textTheme.titleSmall,
                    ),
                    Icon(Icons.arrow_forward_ios_outlined, size: 15),
                  ],
                ),
              ),
              ListTile(
                onTap: () {
                  Get.toNamed(Routes.personalDetailsView);
                },
                title: Text(
                  "Personal details".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),

              ListTile(
                onTap: () {
                  Get.toNamed(Routes.adjustGoalsView);
                },
                title: Text(
                  "Adjust goals".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  "Calories,carbs,fat and protein".tr,
                  style: TextStyle(fontFamily: poppins),
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),
              ListTile(
                onTap: () {
                  Get.toNamed(Routes.chatHistoryView);
                },
                title: Text(
                  "Chat history".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),
              Divider(color: AppColor.grey),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Legal".tr,
                  style: context.theme.textTheme.titleMedium,
                ),
              ),
              ListTile(
                onTap: () {
                  controller.openPrivacy();
                },
                title: Text(
                  "Terms and Condition".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),
              ListTile(
                onTap: () {
                  controller.openTerms();
                },
                title: Text(
                  "Privacy Policy".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),
              ListTile(
                onTap: () {
                  showDeleteDialog(context);
                },
                title: Text(
                  "Reset Data?".tr,
                  style: context.theme.textTheme.titleSmall,
                ),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 15),
              ),
              Divider(color: AppColor.grey),
              ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "VERSION".tr,
                      style: context.theme.textTheme.titleSmall,
                    ).paddingOnly(right: 5),
                    Text("1.0.0", style: context.theme.textTheme.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        title: Text(
          "Confirm Reset".tr,
          style: context.theme.textTheme.headlineMedium,
        ),
        content: Text(
          "Are you sure you want to Reset Data?".tr,
          style: context.theme.textTheme.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // Close the dialog
            child: Text(
              "Cancel".tr,
              style: TextStyle(color: Colors.green, fontFamily: poppins),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close the dialog
              await logoutUser();
            },
            child: Text(
              "Reset".tr,
              style: TextStyle(color: Colors.red, fontFamily: poppins),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logoutUser() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.sqlClear();
    SharedPref.clear();
    await Get.find<ThemeController>().toggleTheme(true);
    Get.snackbar(
      "Reset".tr,
      "You have been Reset Account".tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    Get.offAllNamed(AppPages.initial);
  }
}
