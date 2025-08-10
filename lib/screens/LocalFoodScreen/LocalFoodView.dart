import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:get/get.dart';

import '../../constant/FontFamily.dart';

class LocalFoodView extends GetView<LocalFoodController> {
  const LocalFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        leading: AppWidgets.backButton(context, () {
          Get.back();
        }),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: GetBuilder<LocalFoodController>(
          builder: (controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    style: TextStyle(
                      color: context.theme.scaffoldBackgroundColor,
                      fontFamily: poppins,
                      fontWeight: FontWeight.w500,
                    ),
                    onTapOutside: (event) {
                      FocusScope.of(context).unfocus();
                    },
                    controller: controller.textController,
                    onChanged: (value) {
                      controller.textController.text = value;
                      controller.searchFilter(controller.textController.text);
                      controller.update();
                    },
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.theme.focusColor,
                      ),
                      fillColor: context.theme.primaryColor,
                      filled: true,
                      hintText: 'Search by Food Name/Dish'.tr,
                      constraints: const BoxConstraints(
                        minHeight: 30,
                        maxWidth: double.infinity,
                      ),
                      hintStyle: TextStyle(
                        color: context.theme.scaffoldBackgroundColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.theme.focusColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: controller.filteredItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(controller.filteredItems[index].name,style: context.textTheme.titleSmall,),
                        subtitle: Text(
                          controller.filteredItems[index].quantity,
                          style: TextStyle(fontFamily: poppins,fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${controller.filteredItems[index].calories} Cal",
                              style: TextStyle(
                                color: AppColor.grey,
                                fontFamily: poppins,
                                fontSize: 14,
                              ),
                            ).paddingOnly(right: 10),
                            GestureDetector(
                              onTap: () {
                                controller.onAddButton(context,controller.filteredItems[index]);
                              },
                              child: Image.asset(
                                AppAssets.moreIcon,
                                color: context.theme.focusColor,
                                height: 26,
                                width: 26,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
