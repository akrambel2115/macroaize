import 'package:flutter/material.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import '../../SharePrefHelper/ConstantUserMaster.dart' as CUM;
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsController.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/MonthHistory.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/UpdateWeight.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/WeekHistory.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/YearHistory.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/WeightJourney.dart';
import 'package:foodcalorietracker/widgets/CelebrationStrip.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => AnalyticsController());
  return DefaultTabController(
      length: 3,
      child: Scaffold(
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

                  _buildAnalyticsTabs(context),

                  const SizedBox(height: 20),

                  _buildTabContent(),
                ],
              ),
            );
          },
        ),
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

  Widget _buildCombinedWeightSection(BuildContext context, AnalyticsController controller) {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isLosing 
                    ? AppColor.accent.withOpacity(0.1)
                    : AppColor.success.withOpacity(0.1),
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

          CelebrationStrip(
            message: difference == 0
                ? "goal_achieved_message".tr
                : ((ConstantUserMaster.weight > ConstantUserMaster.desiredGoal)
                    ? "on_a_roll_message".tr
                    : "keep_momentum_message".tr),
            height: 46,
          ),

          const SizedBox(height: 0),

          WeightJourney(
            currentWeight: currentWeight,
            goalWeight: goalWeight,
            onEditCurrent: () {
              showUpdateWeightDialog(
                context,
                ConstantUserMaster.weight.toString(),
                (value) async {
                  final newWeight = int.parse(value);
                  ConstantUserMaster.weight = newWeight;
                  controller.update();
                  await SharedPref.saveInt(
                    SharePrefKey.weight,
                    ConstantUserMaster.weight,
                  );
                  final bmr = _estimateBMR(ConstantUserMaster.height, newWeight, ConstantUserMaster.age, ConstantUserMaster.gender);
                  final activity = _getActivityFactor(ConstantUserMaster.workOutDay);
                  final tdee = bmr * activity;
                  final adjustedCalories = adjustCaloriesForGoal(tdee, newWeight, ConstantUserMaster.desiredGoal, ConstantUserMaster.goalWeight);
                  final macros = CUM.calculateMacrosFromTDEE(adjustedCalories.toDouble(), newWeight);
                  await SharedPref.saveInt(SharePrefKey.calorie, macros['calories']);
                  await SharedPref.saveInt(SharePrefKey.protein, macros['protein']);
                  await SharedPref.saveInt(SharePrefKey.carbs, macros['carbs']);
                  await SharedPref.saveInt(SharePrefKey.fat, macros['fat']);
                  ConstantUserMaster.calorieGoal = macros['calories']!;
                  ConstantUserMaster.proteinGoal = macros['protein']!;
                  ConstantUserMaster.carbGoal = macros['carbs']!;
                  ConstantUserMaster.fatsGoal = macros['fat']!;
                  NotificationService.showSuccess('update_targets_body');
                  try {
                    Get.find<HomeController>().getAllData();
                  } catch (_) {
                  }
                },
              );
            },
            onEditGoal: () {
              showUpdateWeightDialog(
                context,
                ConstantUserMaster.desiredGoal.toString(),
                (value) async {
                  final newGoal = int.parse(value);
                  ConstantUserMaster.desiredGoal = newGoal;
                  controller.update();
                  await SharedPref.saveInt(
                    SharePrefKey.desiredWeight,
                    ConstantUserMaster.desiredGoal,
                  );
                  final bmr = _estimateBMR(ConstantUserMaster.height, ConstantUserMaster.weight, ConstantUserMaster.age, ConstantUserMaster.gender);
                  final activity = _getActivityFactor(ConstantUserMaster.workOutDay);
                  final tdee = bmr * activity;
                  final adjustedCalories = adjustCaloriesForGoal(tdee, ConstantUserMaster.weight, newGoal, ConstantUserMaster.goalWeight);
                  final macros = CUM.calculateMacrosFromTDEE(adjustedCalories.toDouble(), ConstantUserMaster.weight);
                  await SharedPref.saveInt(SharePrefKey.calorie, macros['calories']);
                  await SharedPref.saveInt(SharePrefKey.protein, macros['protein']);
                  await SharedPref.saveInt(SharePrefKey.carbs, macros['carbs']);
                  await SharedPref.saveInt(SharePrefKey.fat, macros['fat']);
                  ConstantUserMaster.calorieGoal = macros['calories']!;
                  ConstantUserMaster.proteinGoal = macros['protein']!;
                  ConstantUserMaster.carbGoal = macros['carbs']!;
                  ConstantUserMaster.fatsGoal = macros['fat']!;
                  NotificationService.showSuccess('update_targets_body');
                  try {
                    Get.find<HomeController>().getAllData();
                  } catch (_) {
                  }
                },
              );
            },
          ),

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
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.4),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _wrapWithCard(WeekHistory()),
            _wrapWithCard(MonthHistory()),
            _wrapWithCard(YearHistory()),
          ],
        ),
      ),
    );
  }

  Widget _wrapWithCard(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// estimate BMR and activity factor.
double _estimateBMR(int heightCm, int weightKg, int age, String gender) {
  if (gender.toLowerCase() == 'male') {
    return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }
  return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
}

double _getActivityFactor(String workOutDays) {
  switch (workOutDays) {
    case '0-2':
      return 1.2;
    case '3-5':
      return 1.55;
    case '6+':
      return 1.725;
    default:
      return 1.2;
  }
}

