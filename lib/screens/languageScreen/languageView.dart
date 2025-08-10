import 'package:flutter/material.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';
import '../../MainController.dart';
import 'languageController.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text("Language".tr,
            style: TextStyle(color: context.theme.primaryColor)),
        leading: AppWidgets.backButton(context, () {
          Get.back();
        },),
      ),
          body: GetBuilder<LanguageController>(
            builder: (controller) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: controller.languageList.length,
                  itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical:5),
                    child: ListTile(
                      onTap: () {
                        controller.onChangeIndex(index);
                        controller.storeCountryCode(controller.countryCode[index]);
                        controller.storeLanguageCode(controller.languageCode[index]);
                        controller.updateLanguage(controller.local[index]);
                        controller.storeLanguage(index);
                        Get.find<MainController>().getLanguageCode();
                        },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // adjust the radius value to your liking
                      ),
                      tileColor: context.theme.cardColor,
                      title: Text(controller.languageList[index].tr,style: context.textTheme.titleSmall,),
                      trailing: controller.selectedIndex == index
                          ? Icon(Icons.check, color: context.theme.focusColor,)
                          : null,
                    ),
                  );
                },),
              );
            },
          ),
    ));
  }
}
