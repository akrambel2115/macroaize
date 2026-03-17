import 'package:flutter/material.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:macroaize/widgets/chart_share_button.dart';

class MonthWorkoutHistory extends GetView<AnalyticsController> {
  const MonthWorkoutHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final chartBoundaryKey = GlobalKey();

    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 8),
      child: Column(
        children: [
          RepaintBoundary(
            key: chartBoundaryKey,
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.theme.cardColor,
              ),
              child: GetBuilder<AnalyticsController>(
                builder: (controller) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Workout This Month:".tr,
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ).paddingOnly(bottom: 15, right: 5),
                                Text(
                                  "${controller.yourMonthlyWorkoutTotal} ${"min".tr}",
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[300]
                                                : Colors.grey[800],
                                      ),
                                ).paddingOnly(bottom: 15),
                              ],
                            ),
                          ),
                          ChartShareButton(boundaryKey: chartBoundaryKey),
                        ],
                      ),
                      Expanded(
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(
                            majorGridLines: const MajorGridLines(width: 0),
                            labelStyle: context.theme.textTheme.labelSmall
                                ?.copyWith(fontSize: 8),
                            interval: 5,
                            labelRotation: 0,
                          ),
                          primaryYAxis: NumericAxis(
                            majorGridLines: const MajorGridLines(width: 1),
                            labelStyle: context.theme.textTheme.labelSmall
                                ?.copyWith(fontSize: 11),
                          ),
                          series: [
                            ColumnSeries<WorkoutData, String>(
                              dataSource: controller.workoutMonthData,
                              xValueMapper: (WorkoutData data, _) => data.label,
                              color: context.theme.focusColor,
                              yValueMapper:
                                  (WorkoutData data, _) => data.minutes,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: false,
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
          ),
        ],
      ),
    );
  }
}
