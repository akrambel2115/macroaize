import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showUpdateWeightDialog(BuildContext context, String initialValue, Function(String) onUpdate) {
  TextEditingController controller = TextEditingController(text: initialValue);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.theme.cardColor,
        title: Text("Update Weight Goal".tr,style: context.textTheme.headlineMedium,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter new weight (kg)".tr,style: context.theme.textTheme.titleSmall,).paddingOnly(bottom: 10,top: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: context.textTheme.titleSmall,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.primaryColor)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.primaryColor)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.primaryColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: Text("Cancel".tr,style: TextStyle(color: context.theme.primaryColor),),
          ),
          TextButton(
            onPressed: () {
              String newWeight = controller.text.trim();
              onUpdate(newWeight); // pass the new value back
              Navigator.of(context).pop(); // close dialog
            },
            child: Text("Update".tr,style: TextStyle(color: context.theme.focusColor),),
          ),

        ],
      );
    },
  );
}
