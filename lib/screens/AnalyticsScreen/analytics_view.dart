import 'package:flutter/material.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:get/get.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_controller.dart';
import 'package:macroaize/screens/AnalyticsScreen/month_history.dart';
import 'package:macroaize/screens/AnalyticsScreen/update_weight.dart';
import 'package:macroaize/screens/AnalyticsScreen/week_history.dart';
import 'package:macroaize/screens/AnalyticsScreen/year_history.dart';
import 'package:macroaize/screens/AnalyticsScreen/week_workout_history.dart';
import 'package:macroaize/screens/AnalyticsScreen/month_workout_history.dart';
import 'package:macroaize/screens/AnalyticsScreen/year_workout_history.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/weight_journey.dart';
import 'package:macroaize/widgets/weight_chart.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _workoutTabController;
  late final AnalyticsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AnalyticsController>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _workoutTabController = TabController(length: 3, vsync: this);
    _workoutTabController.addListener(() {
      if (!_workoutTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workoutTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      body: GetBuilder<AnalyticsController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCombinedWeightSection(context, controller),

                const SizedBox(height: 24),

                Text(
                  "Calorie Overview".tr,
                  style: context.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _buildAnalyticsTabs(context),

                const SizedBox(height: 20),

                _buildTabContent(),

                const SizedBox(height: 8),

                Text(
                  "Workout Overview".tr,
                  style: context.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                _buildWorkoutTabs(context),

                const SizedBox(height: 20),

                _buildWorkoutTabContent(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      title: Row(
        children: [
          Text(
            "OverView".tr,
            style: context.theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedWeightSection(
    BuildContext context,
    AnalyticsController controller,
  ) {
    int currentWeight = ConstantUserMaster.weight;
    int goalWeight = ConstantUserMaster.desiredGoal;
    int difference = (goalWeight - currentWeight).abs();
    bool isLosing = currentWeight > goalWeight;

    return ModernFadeSlideTransition(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Weight Overview".tr,
                  style: context.theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isLosing
                          ? AppColor.accent.withValues(alpha: 0.1)
                          : AppColor.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLosing ? Icons.trending_down : Icons.trending_up,
                      color: isLosing ? AppColor.accent : AppColor.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$difference${'kg'.tr} ${'to go'.tr}",
                      style: context.theme.textTheme.labelMedium?.copyWith(
                        color: isLosing ? AppColor.accent : AppColor.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          WeightJourney(
            currentWeight: currentWeight,
            goalWeight: goalWeight,
            onEditCurrent: () {
              showUpdateWeightDialog(
                context,
                ConstantUserMaster.weight.toString(),
                (value) => controller.updateCurrentWeight(int.parse(value)),
                title: 'Update Weight'.tr,
              );
            },
            onEditGoal: () {
              showUpdateWeightDialog(
                context,
                ConstantUserMaster.desiredGoal.toString(),
                (value) => controller.updateDesiredGoal(int.parse(value)),
                title: 'Update Weight Goal'.tr,
              );
            },
          ),

          const SizedBox(height: 16),

          // Weight History Chart
          const WeightChart(),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTabs(BuildContext context) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: Container(
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
                color: AppColor.primaryOrange.withValues(alpha: 0.3),
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
                  Text("Week".tr),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_view_month, size: 16),
                  const SizedBox(width: 8),
                  Text("Month".tr),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text("Year".tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    Widget content;
    switch (_tabController.index) {
      case 0:
        content = WeekHistory();
        break;
      case 1:
        content = MonthHistory();
        break;
      case 2:
        content = YearHistory();
        break;
      default:
        content = WeekHistory();
    }

    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.4),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: _wrapWithCard(content),
      ),
    );
  }

  Widget _wrapWithCard(Widget child) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }

  Widget _buildWorkoutTabs(BuildContext context) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TabBar(
          controller: _workoutTabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColor.primaryOrange,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColor.primaryOrange.withValues(alpha: 0.1),
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
                  Text("Week".tr),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_view_month, size: 16),
                  const SizedBox(width: 8),
                  Text("Month".tr),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text("Year".tr),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutTabContent() {
    Widget content;
    switch (_workoutTabController.index) {
      case 0:
        content = WeekWorkoutHistory();
        break;
      case 1:
        content = MonthWorkoutHistory();
        break;
      case 2:
        content = YearWorkoutHistory();
        break;
      default:
        content = WeekWorkoutHistory();
    }

    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.4),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: _wrapWithCard(content),
      ),
    );
  }
}
