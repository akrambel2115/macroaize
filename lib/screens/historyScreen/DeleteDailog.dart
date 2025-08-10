
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showCustomDeleteDialog({required VoidCallback onDelete,required BuildContext context}) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text("Delete Item".tr,style: context.textTheme.headlineMedium,),
      content: Text("Are you sure you want to delete this item?".tr,style: context.textTheme.titleMedium,),
      actions: [
        TextButton(
          child: Text("Cancel".tr,style: TextStyle(color: Colors.green),),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text("Delete".tr,style: TextStyle(color: Colors.red),),
          onPressed: () {
            onDelete();
            Get.back();
          },
        ),

      ],
    ),
  );
}
