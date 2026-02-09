import 'package:flutter/material.dart';
import 'package:macroaize/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeekHistory extends GetView<AnalyticsController> {
  const WeekHistory({super.key});

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
                          "Calorie Your Week :".tr,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ).paddingOnly(bottom: 15, right: 5),
                        Text(
                          "${controller.yourWeeklyGoal}",
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors
                                        .grey[300] // light gray for dark mode
                                    : null, // default theme color for light
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
                          ColumnSeries<SalesData, String>(
                            dataSource: controller.weeklyData,
                            xValueMapper: (SalesData sales, _) => sales.time.tr,
                            color: context.theme.focusColor,
                            yValueMapper: (SalesData sales, _) => sales.ml,
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
