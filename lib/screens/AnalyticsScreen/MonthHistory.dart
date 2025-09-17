import 'package:flutter/material.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MonthHistory extends GetView<AnalyticsController> {
  const MonthHistory({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AnalyticsController());
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 8, right: 8, bottom: 8),
      child: Column(
        children: [
          GetBuilder<AnalyticsController>(
            builder: (controller) {
              return Container(
                height: 300,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: context.theme.cardColor,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Average Calorie Month :".tr,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ).paddingOnly(bottom: 15, right: 5),
                        Text(
                          "${controller.yourMonthGoal}",
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors
                                        .grey[300] // Light gray for dark mode
                                    : null, // Use default theme color for light mode
                          ),
                        ).paddingOnly(bottom: 15),
                      ],
                    ),
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          majorGridLines: MajorGridLines(width: 0),
                          labelStyle: context.theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 11),
                        ),
                        primaryYAxis: NumericAxis(
                          majorGridLines: MajorGridLines(width: 1),
                          labelStyle: context.theme.textTheme.labelSmall
                              ?.copyWith(fontSize: 11),
                        ),
                        series: [
                          ColumnSeries<SalesData, String>(
                            dataSource: controller.monthData,
                            xValueMapper: (SalesData sales, _) => sales.time,
                            color: context.theme.focusColor,
                            yValueMapper: (SalesData sales, _) => sales.ml,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              textStyle: context.theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300]
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
