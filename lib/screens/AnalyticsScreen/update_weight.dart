import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';

void showUpdateWeightDialog(
  BuildContext context,
  String initialValue,
  Function(String) onUpdate, {
  String? title,
}) {
  const int minWeight = 20; // kg
  const int maxWeight = 150; // kg (cap)

  int initial = int.tryParse(initialValue) ?? minWeight;
  initial = initial.clamp(minWeight, maxWeight);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      int selected = initial;
      final FixedExtentScrollController scrollController =
          FixedExtentScrollController(initialItem: initial - minWeight);

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.theme.cardColor,
            title: Text(
              title ?? "Update Weight".tr,
              style: context.textTheme.headlineMedium,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter new weight (kg)".tr,
                  style: context.theme.textTheme.titleSmall,
                ).paddingOnly(bottom: 10, top: 10),
                Container(
                  height: 160,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColor.darkCard
                            : context.theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CupertinoPicker(
                    scrollController: scrollController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      selected = minWeight + index;
                      setState(() {});
                    },
                    children: List.generate(maxWeight - minWeight + 1, (index) {
                      final value = minWeight + index;
                      return Center(
                        child: Text(
                          "$value kg",
                          style: TextStyle(
                            fontSize: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => safeBack(),
                child: Text(
                  "Cancel".tr,
                  style: TextStyle(color: context.theme.primaryColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  // selected is within range
                  onUpdate(selected.toString());
                  safeBack();
                },
                child: Text(
                  "Update".tr,
                  style: TextStyle(color: context.theme.focusColor),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
