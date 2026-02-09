import 'package:flutter/material.dart';
import 'package:macroaize/SharePrefHelper/ConstantUserMaster.dart';
import 'package:macroaize/constant/AppColor.dart';
import 'package:macroaize/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeightChart extends StatefulWidget {
  const WeightChart({super.key});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AnalyticsController>(
      builder: (controller) {
        final goalWeight = ConstantUserMaster.desiredGoal.toDouble();
        final data = _getDataForTab(controller);
        final currentWeight = data.isNotEmpty ? data.last.weight : 0.0;

        String title;
        switch (_tabController.index) {
          case 0:
            title = 'weight_week_title'.tr;
            break;
          case 1:
            title = 'weight_month_title'.tr;
            break;
          case 2:
            title = 'weight_year_title'.tr;
            break;
          default:
            title = 'weight_week_title'.tr;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs OUTSIDE the card (like calorie chart)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColor.primaryOrange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColor.neutralGrey600,
                labelStyle: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_view_week, size: 16),
                        const SizedBox(width: 8),
                        Text('Week'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_view_month, size: 16),
                        const SizedBox(width: 8),
                        Text('Month'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('Year'.tr),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Chart card (like calorie chart)
            Container(
              height: 300,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: context.theme.cardColor,
              ),
              child: Column(
                children: [
                  // Title row (like calorie chart)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ).paddingOnly(bottom: 15, right: 5),
                      Text(
                        '${currentWeight.toInt()}${'kg'.tr}',
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
                  // Chart
                  Expanded(
                    child: SfCartesianChart(
                      key: ValueKey('${data.length}_$currentWeight'),
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: context.theme.textTheme.labelSmall
                            ?.copyWith(fontSize: 9),
                        interval: 1,
                        labelRotation: _tabController.index == 1 ? -45 : 0,
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(width: 1),
                        labelStyle: context.theme.textTheme.labelSmall
                            ?.copyWith(fontSize: 11),
                        plotBands: [
                          PlotBand(
                            start: goalWeight,
                            end: goalWeight,
                            borderColor: AppColor.success,
                            borderWidth: 2,
                            dashArray: const [8, 4],
                          ),
                        ],
                      ),
                      series: [
                        LineSeries<WeightData, String>(
                          dataSource: data,
                          xValueMapper: (d, _) => d.label.tr,
                          yValueMapper: (d, _) => d.weight,
                          color: AppColor.primaryOrange,
                          width: 3,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            shape: DataMarkerType.circle,
                            width: 8,
                            height: 8,
                            color: AppColor.primaryOrange,
                            borderColor: Colors.white,
                            borderWidth: 2,
                          ),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: _tabController.index == 0,
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
              ),
            ),
          ],
        );
      },
    );
  }

  List<WeightData> _getDataForTab(AnalyticsController controller) {
    switch (_tabController.index) {
      case 0:
        return controller.weeklyWeightData;
      case 1:
        return controller.monthlyWeightData;
      case 2:
        return controller.yearlyWeightData;
      default:
        return [];
    }
  }
}
