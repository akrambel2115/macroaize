import 'package:flutter/material.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeekWorkoutHistory extends GetView<AnalyticsController> {
  const WeekWorkoutHistory({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AnalyticsController());

    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 8),
      child: Column(
        children: [
          Container(
            height: 300,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: context.theme.cardColor,
            ),
            child: GetBuilder<AnalyticsController>(
              builder: (controller) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Workout This Week:".tr,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ).paddingOnly(bottom: 15, right: 5),
                        Text(
                          "${controller.yourWeeklyWorkoutTotal} ${"min".tr}",
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : null,
                          ),
                        ).paddingOnly(bottom: 15),
                      ],
                    ),
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          majorGridLines: MajorGridLines(width: 0),
                          labelStyle: context.theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 9),
                          interval: 1,
                          labelRotation: -45,
                        ),
                        primaryYAxis: NumericAxis(
                          majorGridLines: MajorGridLines(width: 1),
                          labelStyle: context.theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 11),
                        ),
                        series: [
                          ColumnSeries<WorkoutData, String>(
                            dataSource: controller.workoutWeeklyData,
                            xValueMapper:
                                (WorkoutData data, _) => data.label.tr,
                            color: context.theme.focusColor,
                            yValueMapper: (WorkoutData data, _) => data.minutes,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              textStyle: context.theme.textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[300]
                                            : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
