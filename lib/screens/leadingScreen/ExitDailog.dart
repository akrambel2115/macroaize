
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart'; // Optional alternative

void showExitConfirmationDialog({required BuildContext context}) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text(
        "Exit App".tr,
        style: context.textTheme.headlineMedium,
      ),
      content: Text(
        "Are you sure you want to exit the app?".tr,
        style: context.textTheme.titleMedium,
      ),
      actions: [
        TextButton(
          child: Text(
            "Cancel".tr,
            style: TextStyle(color: Colors.green),
          ),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text(
            "Exit".tr,
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            // Close the dialog first
            Get.back();

            // Exit the app
            // Option 1: Using SystemNavigator (recommended)
            SystemNavigator.pop();

            // Option 2: Force exit (not recommended)
            // exit(0);
          },
        ),
      ],
    ),
  );
}
