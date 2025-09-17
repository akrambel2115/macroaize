import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/FontFamily.dart';
import 'package:get/get.dart';

void showUpdateGoalDialog(
  int currentGoal,
  Function(int) onSave,
  BuildContext context,
  String hintText,
) {
  TextEditingController controller = TextEditingController(
    text: currentGoal.toString(),
  );

  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text(hintText, style: context.theme.textTheme.headlineMedium),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: TextField(
          controller: controller,
          style: context.textTheme.titleSmall,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: hintText,
            hintStyle: context.theme.textTheme.titleSmall,
            labelStyle: context.theme.textTheme.titleMedium,
            // Set label color
            border: OutlineInputBorder(),
            // Default border
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: context.theme.focusColor,
                width: 2,
              ), // Focus color
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey), // Default color
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color.fromRGBO(189, 189, 189, 1),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            "Cancel".tr,
            style: TextStyle(
              fontFamily: poppins,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            int newGoal = int.tryParse(controller.text) ?? currentGoal;
            onSave(newGoal);
            Get.back(); // Close dialog
          },
          child: Text(
            "Save".tr,
            style: TextStyle(
              fontFamily: poppins,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ),
      ],
    ),
  );
}
