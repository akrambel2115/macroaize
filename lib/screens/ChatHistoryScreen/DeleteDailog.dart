
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showChatDeleteDialog({required VoidCallback onDelete,required BuildContext context}) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text("Delete Item",style: context.textTheme.headlineMedium,),
      content: Text("Are you sure you want to delete this item?",style: context.textTheme.titleMedium,),
      actions: [
        TextButton(
          child: Text("Cancel",style: TextStyle(color: Colors.green),),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text("Delete",style: TextStyle(color: Colors.red),),
          onPressed: () {
            onDelete();
            Get.back();
          },
        ),

      ],
    ),
  );
}
