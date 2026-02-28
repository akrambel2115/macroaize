import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';

void showDeleteDialog({
  required VoidCallback onDelete,
  required BuildContext context,
  String? title,
  String? message,
}) {
  Get.dialog(
    AlertDialog(
      backgroundColor: context.theme.cardColor,
      title: Text(
        title ?? 'delete_item'.tr,
        style: context.textTheme.headlineMedium,
      ),
      content: Text(
        message ?? 'delete_item_confirmation'.tr,
        style: context.textTheme.titleMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => safeBack(),
          child: Text('cancel'.tr, style: const TextStyle(color: Colors.green)),
        ),
        TextButton(
          onPressed: () {
            onDelete();
            safeBack();
          },
          child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
