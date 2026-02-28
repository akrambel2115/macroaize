import 'package:flutter/material.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:macroaize/widgets/chart_share_button.dart';

class MonthHistory extends GetView<AnalyticsController> {
  const MonthHistory({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AnalyticsController());
    final chartBoundaryKey = GlobalKey();
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 8),
      child: Column(
        children: [
          GetBuilder<AnalyticsController>(
            builder: (controller) {
              return RepaintBoundary(
                key: chartBoundaryKey,
                child: Container(
                  height: 300,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: context.theme.cardColor,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Average Calorie Month :".tr,
                                  style: context.theme.textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ).paddingOnly(bottom: 15, right: 5),
                                Text(
                                  "${controller.yourMonthGoal}",
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
                                ?.copyWith(fontSize: 11),
                          ),
                          primaryYAxis: NumericAxis(
                            majorGridLines: const MajorGridLines(width: 1),
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
                                textStyle: context.theme.textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[300]
                                              : Colors.grey[800],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
