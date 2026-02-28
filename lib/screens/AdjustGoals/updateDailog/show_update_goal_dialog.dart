import 'package:flutter/material.dart';
import 'package:macroaize/constant/font_family.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';

void showUpdateGoalDialog(
  int currentGoal,
  Function(int) onSave,
  BuildContext context,
  String hintText, {
  int? minValue,
  int? maxValue,
}) {
  TextEditingController controller = TextEditingController(
    text: currentGoal.toString(),
  );

  Get.dialog(
    Builder(
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (stfCtx, setState) {
            return AlertDialog(
              backgroundColor: context.theme.cardColor,
              title: Text(
                hintText,
                style: context.theme.textTheme.headlineMedium,
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      style: context.textTheme.titleSmall,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: hintText,
                        hintStyle: context.theme.textTheme.titleSmall,
                        labelStyle: context.theme.textTheme.titleMedium,
                        errorText: errorText,
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: context.theme.focusColor,
                            width: 2,
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        disabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(189, 189, 189, 1),
                          ),
                        ),
                      ),
                    ),
                    if (minValue != null || maxValue != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _buildRangeHint(minValue, maxValue),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColor.neutralGrey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                    final parsed = int.tryParse(controller.text);
                    if (parsed == null || parsed <= 0) {
                      setState(
                        () => errorText = 'enter_valid_number'.tr,
                      );
                      return;
                    }
                    if (minValue != null && parsed < minValue) {
                      setState(
                        () => errorText =
                            '${'minimum_value'.tr} $minValue',
                      );
                      return;
                    }
                    if (maxValue != null && parsed > maxValue) {
                      setState(
                        () => errorText =
                            '${'maximum_value'.tr} $maxValue',
                      );
                      return;
                    }
                    onSave(parsed);
                    Navigator.of(dialogContext).pop();
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
            );
          },
        );
      },
    ),
  );
}

String _buildRangeHint(int? min, int? max) {
  if (min != null && max != null) return '$min – $max';
  if (min != null) return '${'minimum_value'.tr} $min';
  if (max != null) return '${'maximum_value'.tr} $max';
  return '';
}
