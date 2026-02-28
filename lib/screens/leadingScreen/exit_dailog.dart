
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';

void showExitConfirmationDialog({required BuildContext context}) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text(
        "exit_app_title".tr,
        style: context.textTheme.headlineMedium,
      ),
      content: Text(
        "exit_app_message".tr,
        style: context.textTheme.titleMedium,
      ),
      actions: [
        TextButton(
          child: Text(
            "Cancel".tr,
            style: TextStyle(color: Colors.green),
          ),
          onPressed: () => safeBack(),
        ),
        TextButton(
          child: Text(
            "Exit".tr,
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            // Close the dialog first
            safeBack();

                  // Exit the app using SystemNavigator
                  SystemNavigator.pop();
          },
        ),
      ],
    ),
  );
}
