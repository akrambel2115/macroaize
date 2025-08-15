import 'package:flutter/material.dart';
import 'package:foodcalorietracker/widgets/AnimatedCounter.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/Appkey.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomeView extends GetView<HomeController> {
  // Centralized spacing for meal cards in the history section.
  // Keep this configurable for easy future tweaks.
  // Spacing between meal history cards. Set to a small value to provide a 2px gap.
  // Centralized control makes future adjustments or responsiveness easy.
  static const double _kMealCardSpacing = 2.0;
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
          // Slightly reduce horizontal padding to give cards more room without affecting overall layout
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Consistent spacing using multiples of 8dp
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector
              _buildDateSelector(context),
              
              const SizedBox(height: 24), // Consistent spacing
              
              // Calorie tracking card
              _buildCalorieTrackingCard(context),
              
              const SizedBox(height: 24),
              
              // Nutrition progress
              _buildNutritionProgress(context),
              
              const SizedBox(height: 32), // Increased spacing for better hierarchy
              
              // History section
              _buildHistorySection(context),
              
              const SizedBox(height: 24),
              
              // Meal cards
              _buildMealCards(context),
              
              const SizedBox(height: 24), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(context),
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
            appName.tr,
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
          child: ModernButton(
            text: '',
            style: ModernButtonStyle.ghost,
            size: ModernButtonSize.small,
            onPressed: () {
              Get.toNamed(Routes.premiumView);
            },
            icon: Image.asset(
              AppAssets.crownIcon,
              height: 24,
              width: 24,
            ),
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
            final sidePadding = (totalWidth - (visibleCount * totalItemWidth) + itemSpacing) / 2;
            return GetBuilder<HomeController>(
              builder: (controller) {
                return ListView.builder(
                  controller: controller.scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: sidePadding > 0 ? sidePadding : 0),
                  itemCount: controller.dates.length,
                  itemBuilder: (context, index) {
                    bool isToday = controller.dates[index].day == controller.today.day;
                    return Padding(
                      padding: EdgeInsets.only(right: index == controller.dates.length - 1 ? 0 : itemSpacing),
                      child: ModernScaleTransition(
                        child: GestureDetector(
                          onTap: () => controller.dateFilter(index),
                          child: SizedBox(
                            width: itemWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isToday ? AppColor.primaryGradient : null,
                                color: isToday ? null : context.theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isToday
                                      ? Colors.transparent
                                      : AppColor.neutralGrey200,
                                  width: 1,
                                ),
                                boxShadow: [
                                  if (isToday)
                                    BoxShadow(
                                      color: AppColor.primaryOrange.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E')
                                        .format(controller.dates[index])
                                        .substring(0, 3)
                                        .toUpperCase(),
                                    style: context.textTheme.labelSmall?.copyWith(
                                      color: isToday
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
                                      color: isToday
                                          ? Colors.white
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        controller.dates[index].day.toString(),
                                        style: context.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isToday
                                              ? AppColor.primaryOrange
                                              : context.theme.primaryColor,
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
        double progress = controller.isLoading 
          ? 0.0 
          : (controller.consumedKcal / ConstantUserMaster.calorieGoal).clamp(0.0, 1.0);
        
        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.2),
          child: ModernCard(
            enableGradient: true,
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: AppColor.primaryOrange,
                        size: 20,
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
                    // Plus button moved below goal calories for better UX
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Calorie circle and stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Consumed
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedCounter(
                            value: controller.consumedKcal,
                            style: context.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'kcal_unit'.tr,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: AppColor.neutralGrey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Consumed progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: controller.consumedKcal / ConstantUserMaster.calorieGoal,
                                minHeight: 7,
                                backgroundColor: AppColor.neutralGrey200,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                          ),
                          Text(
                            "Consumed".tr,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Circular progress
                    Container(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          // Background circle with thin border
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.neutralGrey200,
                                width: 3,
                              ),
                              color: Colors.transparent, // No background
                            ),
                          ),
                          // Progress circle
                          Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColor.primaryOrange,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                          ),
                          // Goal text (removed pulse animation for static display)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedCounter(
                                  value: ConstantUserMaster.calorieGoal,
                                  style: context.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryOrange,
                                  ),
                                ),
                                Text(
                                  'goal_label'.tr.isNotEmpty 
                                    ? 'goal_label'.tr 
                                    : 'Goal',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: AppColor.neutralGrey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Remaining
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedCounter(
                            value: controller.remainingKcal,
                            style: context.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColor.secondary,
                            ),
                          ),
                          Text(
                            'kcal_unit'.tr,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: AppColor.neutralGrey600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Remaining progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: controller.remainingKcal / ConstantUserMaster.calorieGoal,
                                minHeight: 7,
                                backgroundColor: AppColor.neutralGrey200,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColor.secondary),
                              ),
                            ),
                          ),
                          Text(
                            "Remaining".tr,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Modern, compact add button below goal calories
                Center(
                  child: Material(
                    color: AppColor.neutralGrey800,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.25),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => showMealSelectionSheet(context),
                      splashColor: Colors.white.withOpacity(0.08),
                      highlightColor: Colors.white.withOpacity(0.12),
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
        );
      },
    );
  }

  Widget _buildNutritionProgress(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.3),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: ModernNutrientCard(
                  label: "Protein".tr,
                  value: controller.consumedProtein.toString(),
                  goal: ConstantUserMaster.proteinGoal.toString(),
                  unit: 'protein_unit'.tr,
                  color: AppColor.primaryOrange,
                  icon: null,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        AppAssets.protein,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: AppColor.primaryOrange,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  progress: (controller.consumedProtein / ConstantUserMaster.proteinGoal).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: ModernNutrientCard(
                  label: "Carbs".tr,
                  value: controller.consumedCarbs.toString(),
                  goal: ConstantUserMaster.carbGoal.toString(),
                  unit: 'carbs_unit'.tr,
                  color: AppColor.primaryOrange,
                  icon: null,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        AppAssets.carb,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: AppColor.primaryOrange,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  progress: (controller.consumedCarbs / ConstantUserMaster.carbGoal).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: ModernNutrientCard(
                  label: "Fats".tr,
                  value: controller.consumedFats.toString(),
                  goal: ConstantUserMaster.fatsGoal.toString(),
                  unit: 'fat_unit'.tr,
                  color: AppColor.primaryOrange,
                  icon: null,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        AppAssets.fat,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        color: AppColor.primaryOrange,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  progress: (controller.consumedFats / ConstantUserMaster.fatsGoal).clamp(0.0, 1.0),
                ),
              ),
            ],
          ),
        );
      },
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
              Get.toNamed(
                Routes.historyView,
                arguments: {"type": "All"},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealCards(BuildContext context) {
    final meals = [
      {
        'name': 'BreakFast',
        'icon': AppAssets.breakfast,
        'color': AppColor.tertiary,
      },
      {
        'name': 'Lunch',
        'icon': AppAssets.lunch,
        'color': AppColor.tertiary,
      },
      {
        'name': 'snack(s)',
        'icon': AppAssets.snacks,
        'color': AppColor.tertiary,
      },
      {
        'name': 'Dinner',
        'icon': AppAssets.dinner,
        'color': AppColor.tertiary,
      },
    ];

    return Column(
      children: meals.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> meal = entry.value;
        
        return ModernFadeSlideTransition(
          beginOffset: Offset(0, 0.5 + (index * 0.1)),
          child: ModernCard(
            // Keep horizontal gutters but remove vertical gap so cards touch.
            margin: const EdgeInsets.fromLTRB(12, 0, 12, _kMealCardSpacing),
            // Slightly reduce internal padding for denser layout while preserving touch targets.
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            // Reduce shadow intensity to avoid overlapping glow when cards touch.
            boxShadow: [
              BoxShadow(
                color: AppColor.primaryOrange.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            onTap: () {
              Get.toNamed(
                Routes.historyView,
                arguments: {"type": meal['name']},
              );
            },
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
                        AppColor.primaryOrange.withOpacity(0.1),
                        AppColor.primaryOrange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      meal['icon'],
                    ),
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColor.neutralGrey400,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showMealSelectionSheet(context),
      backgroundColor: AppColor.primaryOrange,
      shape: const CircleBorder(),
      elevation: 8,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColor.primaryGradient,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
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
              ...['BreakFast', 'Lunch', 'snack(s)', 'Dinner'].asMap().entries.map((entry) {
                int index = entry.key;
                String meal = entry.value;
                final colors = List<Color>.filled(4, AppColor.primaryOrange);
                final icons = [AppAssets.breakfast, AppAssets.lunch, AppAssets.snacks, AppAssets.dinner];
                
                return ModernFadeSlideTransition(
                  beginOffset: Offset(0, 0.3 + (index * 0.1)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ModernCard(
                      onTap: () {
                        Navigator.pop(context);
                        Get.toNamed(Routes.localFoodView, arguments: {"value": meal});
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors[index].withOpacity(0.1),
                                  colors[index].withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                icons[index],
                                // Keep original icon color for clarity and maintainability
                              ),
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
                              color: colors[index].withOpacity(0.1),
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
