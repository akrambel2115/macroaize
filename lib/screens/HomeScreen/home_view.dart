import 'package:flutter/material.dart';
import 'dart:io';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/shared/services/app_config_service.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/screens/HomeScreen/home_controller.dart';
import '../DailyStreakScreen/daily_streak_view.dart';
import '../DailyStreakScreen/daily_streak_controller.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:macroaize/widgets/modern_card.dart';
import 'package:macroaize/widgets/energy_orbs.dart';
import 'package:macroaize/widgets/calorie_ring.dart';
import 'package:macroaize/widgets/nutrition_badge.dart';
import 'package:macroaize/shared/services/meal_share_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/screens/leadingScreen/leading_view.dart';
import 'package:macroaize/screens/leadingScreen/leading_controller.dart';
import '../../widgets/verify_email_button.dart';
import 'package:lottie/lottie.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_controller.dart';

class HomeView extends GetView<HomeController> {
  static const double _kMealCardSpacing = 8.0;

  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => HomeController());
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.getSqlCalorie();
          controller.getAllData();
        },
        color: AppColor.primaryOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(context),

              const SizedBox(height: 24),
              _buildTrackingCarousel(context),

              const SizedBox(height: 24),

              _buildNutritionProgress(context),

              const SizedBox(height: 32),

              _buildMealTrackerSection(context),

              const SizedBox(height: 24),

              _buildWaterTrackerSection(context),

              const SizedBox(height: 24),

              _buildHistorySection(context),

              const SizedBox(height: 16),

              _buildLastLoggedMealCard(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildModernFAB(context),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Get.find<AppConfigService>().appName.tr,
            style: context.theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'track_subtitle'.tr.isNotEmpty
                ? 'track_subtitle'.tr
                : 'Track your daily nutrition',
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: AppColor.neutralGrey600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: const VerifyEmailButton(),
        ),
        Obx(
          () => InkWell(
            onTap: () {
              Get.put(DailyStreakController());
              Get.bottomSheet(
                const DailyStreakView(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Image.asset(AppAssets.fireIcon, width: 24, height: 24),
                  const SizedBox(width: 4),
                  Text(
                    "${controller.streakCount.value}",
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ModernButton(
            text: '',
            style: ModernButtonStyle.ghost,
            size: ModernButtonSize.small,
            onPressed: () => Get.toNamed(Routes.premiumView),
            icon: Image.asset(AppAssets.crownIcon, height: 24, width: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return ModernFadeSlideTransition(
      child: SizedBox(
        height: 90,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = 70.0;
            final itemSpacing = 12.0;
            final visibleCount = 4;
            final totalItemWidth = itemWidth + itemSpacing;
            final totalWidth = constraints.maxWidth;
            final sidePadding =
                (totalWidth - (visibleCount * totalItemWidth) + itemSpacing) /
                2;
            return GetBuilder<HomeController>(
              builder: (controller) {
                return ListView.builder(
                  controller: controller.scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: sidePadding > 0 ? sidePadding : 0,
                  ),
                  itemCount: controller.dates.length,
                  itemBuilder: (context, index) {
                    bool isToday =
                        controller.dates[index].day == controller.today.day;
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                        end:
                            index == controller.dates.length - 1
                                ? 0
                                : itemSpacing,
                      ),
                      child: ModernScaleTransition(
                        child: GestureDetector(
                          onTap: () => controller.dateFilter(index),
                          child: SizedBox(
                            width: itemWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient:
                                    isToday ? AppColor.primaryGradient : null,
                                color: isToday ? null : context.theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isToday
                                          ? Colors.transparent
                                          : (context.theme.brightness ==
                                                  Brightness.dark
                                              ? AppColor.neutralGrey800
                                              : AppColor.neutralGrey200),
                                  width: 1,
                                ),
                                boxShadow: [
                                  if (isToday)
                                    BoxShadow(
                                      color: AppColor.primaryOrange.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (() {
                                      final weekdayKeys = [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ];
                                      final lang =
                                          Get.locale?.languageCode ??
                                          Get.deviceLocale?.languageCode ??
                                          'en';
                                      final key =
                                          weekdayKeys[controller
                                                  .dates[index]
                                                  .weekday -
                                              1];
                                      final label = key.tr;
                                      return lang == 'en'
                                          ? label.toUpperCase()
                                          : label;
                                    })(),
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color:
                                              isToday
                                                  ? Colors.white
                                                  : AppColor.neutralGrey600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color:
                                          isToday
                                              ? Colors.white
                                              : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        controller.dates[index].day.toString(),
                                        style: context.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isToday
                                                      ? AppColor.primaryOrange
                                                      : context
                                                          .theme
                                                          .primaryColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalorieTrackingCard(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        double progress =
            controller.isLoading
                ? 0.0
                : (controller.consumedKcal / ConstantUserMaster.calorieGoal)
                    .clamp(0.0, 1.0);

        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.2),
          child: SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ModernCard(
                  enableGradient: true,
                  margin: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColor.primaryOrange.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: AppColor.primaryOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Track Food".tr,
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          _InlineEditIcon(
                            onTap: () => Get.toNamed(Routes.adjustGoalsView),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calorie goal'.tr,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: AppColor.neutralGrey600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0.0,
                                    end:
                                        ConstantUserMaster.calorieGoal
                                            .toDouble(),
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedValue, _) {
                                    return Text(
                                      NumberFormat.decimalPattern().format(
                                        animatedValue.round(),
                                      ),
                                      style: context.textTheme.headlineLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                _buildMiniNutrientRow(
                                  context,
                                  label: 'Protein'.tr,
                                  value: controller.consumedProtein,
                                  goal: ConstantUserMaster.proteinGoal,
                                  color: AppColor.primaryOrange,
                                ),
                                const SizedBox(height: 8),
                                _buildMiniNutrientRow(
                                  context,
                                  label: 'Carbs'.tr,
                                  value: controller.consumedCarbs,
                                  goal: ConstantUserMaster.carbGoal,
                                  color: AppColor.primaryOrange,
                                ),
                                const SizedBox(height: 8),
                                _buildMiniNutrientRow(
                                  context,
                                  label: 'Fats'.tr,
                                  value: controller.consumedFats,
                                  goal: ConstantUserMaster.fatsGoal,
                                  color: AppColor.primaryOrange,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            flex: 2,
                            child: Center(
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CalorieRing(
                                      progress: progress,
                                      size: 140,
                                      strokeWidth: 16,
                                      progressColor: AppColor.primaryOrange,
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(
                                            begin: 0.0,
                                            end:
                                                controller.remainingKcal
                                                    .toDouble(),
                                          ),
                                          duration: const Duration(
                                            milliseconds: 700,
                                          ),
                                          curve: Curves.easeOut,
                                          builder: (context, animatedValue, _) {
                                            return Text(
                                              animatedValue.round().toString(),
                                              style: context
                                                  .textTheme
                                                  .headlineLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 26,
                                                  ),
                                            );
                                          },
                                        ),
                                        Text(
                                          'Cal Left'.tr,
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                                color: AppColor.neutralGrey600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      Center(
                        child: Material(
                          key: controller.addFoodButtonKey, // tutorial key
                          color: AppColor.neutralGrey800,
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => showMealSelectionSheet(context),
                            splashColor: Colors.white.withValues(alpha: 0.08),
                            highlightColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
    );
  }

  Widget _buildTrackingCarousel(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Column(
          children: [
            SizedBox(
              height: 420,
              child: PageView(
                controller: controller.trackingPageController,
                onPageChanged: controller.onTrackingPageChanged,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: _buildCalorieTrackingCard(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: _buildActivityTrackingCard(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                final isActive = controller.trackingPageIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? AppColor.primaryOrange
                            : (context.isDarkMode
                                ? AppColor.neutralGrey800
                                : AppColor.neutralGrey200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityTrackingCard(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        final totalWaterMl =
            controller.waterGlasses * HomeController.glassVolumeMl;
        final waterGoalMl =
            HomeController.maxGlasses * HomeController.glassVolumeMl;

        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.2),
          child: SizedBox.expand(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // 1. Water Intake Card (Full Width)
                ModernCard(
                  enableGradient: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      // Water Drop Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WATER INTAKE',
                              style: context.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColor.neutralGrey500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                _buildAnimatedCount(
                                  context,
                                  value: totalWaterMl,
                                  durationMs: 700,
                                  useGrouping: true,
                                  style: context.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  ' / $waterGoalMl ml',
                                  style: context.textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColor.neutralGrey400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Add button
                      Material(
                        color:
                            context.isDarkMode
                                ? AppColor.neutralGrey800
                                : AppColor.neutralGrey200,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => controller.addWaterGlass(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.add, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Grid for Steps & Activity
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Steps Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.editStepGoal(),
                          child: ModernCard(
                            enableGradient: false,
                            padding: const EdgeInsets.all(16),
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STEPS',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                context.isDarkMode
                                                    ? AppColor.neutralGrey500
                                                    : AppColor.neutralGrey700,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.lightGreen.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.directions_run_rounded,
                                        color: Colors.lightGreen,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                _buildAnimatedCount(
                                  context,
                                  value: controller.currentSteps,
                                  durationMs: 700,
                                  useGrouping: true,
                                  style: context.textTheme.displayMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color:
                                            context.isDarkMode
                                                ? AppColor.neutralGrey300
                                                : AppColor.neutralGrey800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Goal: ${ConstantUserMaster.stepGoal} steps',
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColor.neutralGrey400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Activity Card
                      Expanded(
                        child: ModernCard(
                          enableGradient: false,
                          padding: const EdgeInsets.all(16),
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACTIVITY',
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              context.isDarkMode
                                                  ? AppColor.neutralGrey500
                                                  : AppColor.neutralGrey700,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.show_chart,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              _buildAnimatedCount(
                                context,
                                value: controller.caloriesBurned,
                                durationMs: 700,
                                useGrouping: true,
                                style: context.textTheme.displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color:
                                          context.isDarkMode
                                              ? AppColor.neutralGrey300
                                              : AppColor.neutralGrey800,
                                    ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Calories burned',
                                      style: context.textTheme.labelMedium
                                          ?.copyWith(
                                            color: AppColor.neutralGrey400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color:
                                        context.isDarkMode
                                            ? AppColor.neutralGrey800
                                            : AppColor.neutralGrey200,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap:
                                          () => Get.toNamed(
                                            Routes.workoutView,
                                            arguments: {
                                              'targetDate':
                                                  controller.today
                                                      .toIso8601String(),
                                            },
                                          ),
                                      child: const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: Icon(Icons.add, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Weigh In Card (fills remaining space)
                Expanded(
                  child: ModernCard(
                    enableGradient: false,
                    padding: const EdgeInsets.all(16),
                    margin: EdgeInsets.zero,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.monitor_weight_rounded,
                            color: Colors.orange,
                            size: 44,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weigh in',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      context.isDarkMode
                                          ? AppColor.neutralGrey300
                                          : AppColor.neutralGrey800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildAnimatedCount(
                                context,
                                value: controller.displayedWeight,
                                durationMs: 700,
                                useGrouping: true,
                                suffix: ' kg',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: AppColor.neutralGrey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed:
                              controller.isSelectedDateToday
                                  ? () => controller.editWeight()
                                  : null,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color:
                                  context.isDarkMode
                                      ? AppColor.neutralGrey600
                                      : AppColor.neutralGrey400,
                            ),
                            foregroundColor:
                                context.isDarkMode
                                    ? AppColor.neutralGrey300
                                    : AppColor.neutralGrey700,
                          ),
                          child: const Text('Record'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionProgress(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnergyOrbs(
                proteinConsumed: controller.consumedProtein,
                carbsConsumed: controller.consumedCarbs,
                fatsConsumed: controller.consumedFats,
                proteinGoal: ConstantUserMaster.proteinGoal,
                carbsGoal: ConstantUserMaster.carbGoal,
                fatsGoal: ConstantUserMaster.fatsGoal,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaterTrackerSection(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (ctrl) {
        final totalMl = ctrl.waterGlasses * HomeController.glassVolumeMl;
        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.4),
          child: ModernCard(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'water_title'.tr,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildAnimatedCount(
                        context,
                        value: totalMl,
                        durationMs: 700,
                        useGrouping: true,
                        suffix: ' ${'water_ml_label'.tr}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              ctrl.waterGlasses >= HomeController.maxGlasses
                                  ? AppColor.info
                                  : context.theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // glass grid – 2 rows of 4
                  Column(
                    children: [
                      _buildGlassRow(context, 0, 4, ctrl),
                      const SizedBox(height: 12),
                      _buildGlassRow(context, 4, 8, ctrl),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassRow(
    BuildContext context,
    int start,
    int end,
    HomeController ctrl,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(end - start, (i) {
        final index = start + i;
        final isFilled = index < ctrl.waterGlasses;
        final isNextEmpty =
            index == ctrl.waterGlasses &&
            ctrl.waterGlasses < HomeController.maxGlasses;

        return GestureDetector(
          onTap: () {
            if (isFilled) {
              ctrl.removeWaterGlass();
            } else if (isNextEmpty) {
              ctrl.addWaterGlass();
            }
          },
          child: SizedBox(
            width: 52,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // water glass icon
                CustomPaint(
                  size: const Size(40, 48),
                  painter: _WaterGlassPainter(
                    isFilled: isFilled,
                    filledColor: AppColor.info,
                    emptyColor:
                        context.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                  ),
                ),
                // "+" badge on the next empty glass
                if (isNextEmpty)
                  Positioned(
                    left: 0,
                    bottom: 4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.theme.cardColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.4),
      child: Row(
        children: [
          Text(
            "History".tr,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ModernButton(
            text: "View All".tr,
            style: ModernButtonStyle.ghost,
            size: ModernButtonSize.small,
            onPressed: () {
              Get.toNamed(Routes.historyView, arguments: {"type": "All"});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealTrackerSection(BuildContext context) {
    final meals = [
      {'name': 'BreakFast', 'icon': AppAssets.breakfast},
      {'name': 'Lunch', 'icon': AppAssets.lunch},
      {'name': 'snack(s)', 'icon': AppAssets.snacks},
      {'name': 'Dinner', 'icon': AppAssets.dinner},
    ];

    return Column(
      children:
          meals.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> meal = entry.value;

            return ModernFadeSlideTransition(
              beginOffset: Offset(0, 0.5 + (index * 0.1)),
              child: ModernCard(
                margin: const EdgeInsets.only(bottom: _kMealCardSpacing),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryOrange.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                onTap: null,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColor.primaryOrange.withValues(alpha: 0.1),
                            AppColor.primaryOrange.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(meal['icon']),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        (meal['name'] as String).tr,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.toNamed(
                          Routes.localFoodView,
                          arguments: {"value": meal['name']},
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.add_circle,
                          color: AppColor.primaryOrange,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        final scanController =
                            Get.isRegistered<ScanFoodController>()
                                ? Get.find<ScanFoodController>()
                                : Get.put(ScanFoodController());
                        scanController.onChangeIdentify(meal['name']);
                        if (Get.isRegistered<LeadingController>()) {
                          Get.find<LeadingController>().changeTabIndex(2);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: AppColor.primaryOrange,
                              size: 24,
                            ),
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.primaryOrange,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: context.theme.cardColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Text(
                                  "AI",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 8, // Reduced font size for AI tag
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildLastLoggedMealCard(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        final meal = controller.lastLoggedMeal;

        if (meal == null) {
          return ModernFadeSlideTransition(
            child: ModernCard(
              margin: const EdgeInsets.only(bottom: _kMealCardSpacing),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  "No history yet".tr,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutralGrey600,
                  ),
                ),
              ),
            ),
          );
        }

        const Color chipColor = AppColor.primaryOrange;
        String chipIconAsset = '';
        switch (meal.type.toLowerCase()) {
          case 'breakfast':
            chipIconAsset = AppAssets.breakfast;
            break;
          case 'lunch':
            chipIconAsset = AppAssets.lunch;
            break;
          case 'dinner':
            chipIconAsset = AppAssets.dinner;
            break;
          case 'snack(s)':
          case 'snacks':
          case 'snack':
            chipIconAsset = AppAssets.snacks;
            break;
          default:
            chipIconAsset = AppAssets.moreIcon;
        }

        final String displayTitle =
            (meal.title == null || meal.title!.trim().isEmpty)
                ? 'unknown_meal'.tr
                : meal.title!.trim();

        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.5),
          child: ModernCard(
            margin: const EdgeInsets.only(bottom: _kMealCardSpacing),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      chipIconAsset.isNotEmpty
                          ? Image.asset(chipIconAsset, width: 24, height: 24)
                          : Icon(
                            Icons.cookie_outlined,
                            size: 24,
                            color: chipColor,
                          ),
                      const SizedBox(width: 6),
                      Text(
                        meal.type.tr,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: chipColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Builder(
                        builder: (ctx) {
                          return IconButton(
                            icon: const Icon(Icons.share_outlined),
                            tooltip: 'Share Meal'.tr,
                            onPressed: () {
                              final box = ctx.findRenderObject() as RenderBox?;
                              final rect =
                                  box != null
                                      ? box.localToGlobal(Offset.zero) &
                                          box.size
                                      : null;
                              MealShareService.shareHistoryMeal(
                                meal,
                                sharePositionOrigin: rect,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _buildHistoryMealPreview(
                    context,
                    title: displayTitle,
                    imagePath:
                        meal.image is String ? meal.image as String : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NutritionBadge(
                        label: "Calorie".tr,
                        value: meal.calorie.toString(),
                        iconWidget: Image.asset(
                          'assets/icons/calorie.png',
                          width: 28,
                          height: 28,
                        ),
                        accentColor: AppColor.historyAccent,
                        iconSize: 28,
                        unit: 'kcal_unit'.tr,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: NutritionBadge(
                        label: "Protein".tr,
                        value: meal.protein.toString(),
                        iconWidget: Image.asset(
                          AppAssets.protein,
                          width: 28,
                          height: 28,
                        ),
                        accentColor: AppColor.historyAccent,
                        iconSize: 28,
                        unit: 'protein_unit'.tr,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: NutritionBadge(
                        label: "Carbs".tr,
                        value: meal.carbs.toString(),
                        iconWidget: Image.asset(
                          AppAssets.carb,
                          width: 28,
                          height: 28,
                        ),
                        accentColor: AppColor.historyAccent,
                        iconSize: 28,
                        unit: 'carbs_unit'.tr,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: NutritionBadge(
                        label: "Fats".tr,
                        value: meal.fats.toString(),
                        iconWidget: Image.asset(
                          AppAssets.fat,
                          width: 28,
                          height: 28,
                        ),
                        accentColor: AppColor.historyAccent,
                        iconSize: 28,
                        unit: 'fat_unit'.tr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColor.neutralGrey500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      meal.date,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColor.neutralGrey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: FloatingActionButton(
        key: LeadingView.aiCoachButtonKey,
        onPressed: () => Get.toNamed(Routes.chatView),
        backgroundColor: AppColor.primaryOrange,
        elevation: 4,
        shape: const CircleBorder(),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Lottie.asset(
            'assets/lottie/chat.json',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryMealPreview(
    BuildContext context, {
    required String title,
    String? imagePath,
  }) {
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.theme.colorScheme.onSurface,
            ),
          ),
          if (hasImage) const SizedBox(height: 10),
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(imagePath),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                cacheWidth: 160,
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColor.neutralGrey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood_rounded, size: 24),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  // Small, reusable nutrient row used by the redesigned Track Food card.
  Widget _buildMiniNutrientRow(
    BuildContext context, {
    required String label,
    required int value,
    required int goal,
    required Color color,
  }) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColor.neutralGrey600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          context.theme.brightness == Brightness.dark
                              ? AppColor.neutralGrey800
                              : AppColor.neutralGrey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${value.toString()}/${goal.toString()}',
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColor.neutralGrey600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCount(
    BuildContext context, {
    required int value,
    required TextStyle? style,
    int durationMs = 700,
    bool useGrouping = false,
    String suffix = '',
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${value}_$suffix'),
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOut,
      builder: (context, animatedValue, _) {
        final displayed = animatedValue.round();
        final formatted =
            useGrouping
                ? NumberFormat.decimalPattern().format(displayed)
                : displayed.toString();
        return Text('$formatted$suffix', style: style);
      },
    );
  }

  void showMealSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.neutralGrey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Which meal would you like to track?'.tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Meal options
              ...[
                'BreakFast',
                'Lunch',
                'snack(s)',
                'Dinner',
              ].asMap().entries.map((entry) {
                int index = entry.key;
                String meal = entry.value;
                final colors = List<Color>.filled(4, AppColor.primaryOrange);
                final icons = [
                  AppAssets.breakfast,
                  AppAssets.lunch,
                  AppAssets.snacks,
                  AppAssets.dinner,
                ];

                return ModernFadeSlideTransition(
                  beginOffset: Offset(0, 0.3 + (index * 0.1)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ModernCard(
                      onTap: () {
                        Navigator.pop(context);
                        Get.toNamed(
                          Routes.localFoodView,
                          arguments: {"value": meal},
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors[index].withValues(alpha: 0.1),
                                  colors[index].withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(icons[index]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              meal.tr,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors[index].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              color: colors[index],
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _InlineEditIcon extends StatefulWidget {
  final VoidCallback onTap;
  const _InlineEditIcon({required this.onTap});

  @override
  State<_InlineEditIcon> createState() => _InlineEditIconState();
}

class _InlineEditIconState extends State<_InlineEditIcon> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = AppColor.primaryOrange;
    final Color bgColor = AppColor.primaryOrange.withValues(
      alpha: _pressed ? 0.25 : (_hovered ? 0.18 : 0.12),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: AppColor.primaryOrange.withValues(alpha: 0.15),
            highlightColor: AppColor.primaryOrange.withValues(alpha: 0.08),
            child: IconTheme(
              data: IconThemeData(color: iconColor),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: _EditIcon(size: 24)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditIcon extends StatelessWidget {
  final double size;
  const _EditIcon({this.size = 18});
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.edit_outlined,
      size: size,
      color: IconTheme.of(context).color ?? AppColor.neutralGrey500,
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final bool isFilled;
  final Color filledColor;
  final Color emptyColor;

  _WaterGlassPainter({
    required this.isFilled,
    required this.filledColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = isFilled ? filledColor.withValues(alpha: 0.25) : emptyColor;

    // glass body – slightly tapered trapezoid
    final path =
        Path()
          ..moveTo(size.width * 0.15, 0) // top-left
          ..lineTo(size.width * 0.85, 0) // top-right
          ..lineTo(size.width * 0.78, size.height) // bottom-right
          ..lineTo(size.width * 0.22, size.height) // bottom-left
          ..close();

    canvas.drawPath(path, paint);

    // filled overlay with solid colour at the bottom portion
    if (isFilled) {
      final fillPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = filledColor.withValues(alpha: 0.35);

      final fillPath =
          Path()
            ..moveTo(size.width * 0.19, size.height * 0.30)
            ..lineTo(size.width * 0.81, size.height * 0.30)
            ..lineTo(size.width * 0.78, size.height)
            ..lineTo(size.width * 0.22, size.height)
            ..close();

      canvas.drawPath(fillPath, fillPaint);
    }

    // outline on top of fill
    final outlinePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeJoin = StrokeJoin.round
          ..color = isFilled ? filledColor : emptyColor;

    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) =>
      isFilled != oldDelegate.isFilled ||
      filledColor != oldDelegate.filledColor ||
      emptyColor != oldDelegate.emptyColor;
}
