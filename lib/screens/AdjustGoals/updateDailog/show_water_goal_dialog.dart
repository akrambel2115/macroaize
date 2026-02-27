import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/constant/font_family.dart';

const int _minWaterGoalMl = 2000;
const int _maxWaterGoalMl = 4000;
const int _stepWaterGoalMl = 250;

void showWaterGoalDialog(
  int currentGoalMl,
  Function(int) onSave,
  BuildContext context,
) {
  // Clamp and snap to nearest valid step
  int tempGoal = currentGoalMl.clamp(_minWaterGoalMl, _maxWaterGoalMl);
  tempGoal =
      ((tempGoal - _minWaterGoalMl) ~/ _stepWaterGoalMl) * _stepWaterGoalMl +
      _minWaterGoalMl;

  Get.dialog(
    StatefulBuilder(
      builder: (ctx, setState) {
        final bool canDecrease = tempGoal > _minWaterGoalMl;
        final bool canIncrease = tempGoal < _maxWaterGoalMl;
        final int cups = tempGoal ~/ 250;

        String errorText = '';
        if (tempGoal <= _minWaterGoalMl) {
          errorText = 'water_goal_min_error'.tr;
        } else if (tempGoal >= _maxWaterGoalMl) {
          errorText = 'water_goal_max_error'.tr;
        }

        return AlertDialog(
          backgroundColor: ctx.theme.cardColor,
          title: Text(
            'water_goal_label'.tr,
            style: ctx.theme.textTheme.headlineMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrease button
                  IconButton(
                    onPressed:
                        canDecrease
                            ? () =>
                                setState(() => tempGoal -= _stepWaterGoalMl)
                            : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color:
                          canDecrease
                              ? AppColor.primaryOrange
                              : AppColor.neutralGrey400,
                      size: 36,
                    ),
                  ),

                  // Value display
                  SizedBox(
                    width: 110,
                    child: Column(
                      children: [
                        Text(
                          '$tempGoal ml',
                          textAlign: TextAlign.center,
                          style: ctx.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$cups ${'water_cups_label'.tr}',
                          textAlign: TextAlign.center,
                          style: ctx.textTheme.bodyMedium?.copyWith(
                            color: AppColor.neutralGrey600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Increase button
                  IconButton(
                    onPressed:
                        canIncrease
                            ? () =>
                                setState(() => tempGoal += _stepWaterGoalMl)
                            : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color:
                          canIncrease
                              ? AppColor.primaryOrange
                              : AppColor.neutralGrey400,
                      size: 36,
                    ),
                  ),
                ],
              ),

              // Error / boundary hint
              if (errorText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  style: ctx.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],

              const SizedBox(height: 10),
              Text(
                '2000 ml – 4000 ml  ·  ±250 ml',
                textAlign: TextAlign.center,
                style: ctx.textTheme.bodySmall?.copyWith(
                  color: AppColor.neutralGrey500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel'.tr,
                style: TextStyle(
                  fontFamily: poppins,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                onSave(tempGoal);
                Get.back();
              },
              child: Text(
                'Save'.tr,
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
    ),
    barrierDismissible: false,
  );
}
