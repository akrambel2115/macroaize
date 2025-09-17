import 'package:flutter/material.dart';
// Ring painter moved to a shared widget; unused imports removed.
// ...existing code...
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:foodcalorietracker/widgets/EnergyOrbs.dart';
import 'package:foodcalorietracker/widgets/CalorieRing.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/shared/widgets/PremiumRequiredDialog.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:foodcalorietracker/Model/Recipe.dart';
import '../../widgets/VerifyEmailButton.dart';

class HomeView extends GetView<HomeController> {
  // Spacing between meal history cards; keep configurable for tweaks.
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
          // Layout padding
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ), // Consistent spacing using multiples of 8dp
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

              const SizedBox(
                height: 32,
              ), // Increased spacing for better hierarchy
              // Recipes section
              _buildRecipesSection(context),

              const SizedBox(height: 32),

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
        Padding(
          padding: const EdgeInsets.all(8),
          child: ModernButton(
            text: '',
            style: ModernButtonStyle.ghost,
            size: ModernButtonSize.small,
            // Open the premium view when the crown button is tapped
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
                      // Use directional padding so horizontal gaps respect TextDirection (RTL/LTR)
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
                                      color: AppColor.primaryOrange.withOpacity(
                                        0.3,
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
                                    // Use translation keys for weekdays; keep English uppercase short names
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
                                      // keep English in uppercase as previous design used uppercase short day names
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ModernCard(
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
                        // Minimal inline edit icon aligned with title
                        _InlineEditIcon(
                          onTap: () => Get.toNamed(Routes.adjustGoalsView),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Calorie block: goal + nutrient rows and circular remaining calories
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left column: Calorie goal + small nutrient progress rows
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
                                      ConstantUserMaster.calorieGoal.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, animatedValue, _) {
                                  return Text(
                                    NumberFormat.decimalPattern().format(
                                      animatedValue.round(),
                                    ),
                                    style: context.textTheme.headlineLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Small nutrient rows
                              _buildMiniNutrientRow(
                                context,
                                // use existing translation keys (already present in language files)
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

                        // Right column: Circular remaining calories — use shared CalorieRing widget
                        // Right column: Circular remaining calories using shared `CalorieRing`
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
                    const SizedBox(height: 24),
                    // Add button below goal calories
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
            ],
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
              // Energy Orbs
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

  Widget _buildMealCards(BuildContext context) {
    final meals = [
      {
        'name': 'BreakFast',
        'icon': AppAssets.breakfast,
        'color': AppColor.tertiary,
      },
      {'name': 'Lunch', 'icon': AppAssets.lunch, 'color': AppColor.tertiary},
      {
        'name': 'snack(s)',
        'icon': AppAssets.snacks,
        'color': AppColor.tertiary,
      },
      {'name': 'Dinner', 'icon': AppAssets.dinner, 'color': AppColor.tertiary},
    ];

    return Column(
      children:
          meals.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> meal = entry.value;

            return ModernFadeSlideTransition(
              beginOffset: Offset(0, 0.5 + (index * 0.1)),
              child: ModernCard(
                // Keep horizontal gutters but remove vertical gap so cards touch.
                margin: const EdgeInsets.fromLTRB(12, 0, 12, _kMealCardSpacing),
                // Slightly reduce internal padding for denser layout while preserving touch targets.
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
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
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildRecipesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left column flexible so subtitle can wrap/ellipsis
                // Keep horizontal gutters; reduce vertical gap so cards touch visually.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'top_recipes'.tr,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'top_recipes_subtitle'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColor.neutralGrey600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _navigateToRecipes(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View All".tr,
                    style: TextStyle(
                      color: AppColor.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColor.primaryOrange,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children:
                _getMockRecipes().map((recipe) {
                  return GestureDetector(
                    onTap: () async {
                      try {
                        final appUserService = Get.find<AppUserService>();
                        final isPremium = await appUserService.isPremiumNow();
                        if (!isPremium) {
                          _showPremiumRequiredDialog();
                          return;
                        }
                        Get.toNamed(
                          Routes.recipeDetailView,
                          arguments: {
                            'recipe': Recipe(
                              id: recipe['title'] as String,
                              title: recipe['title'] as String,
                              imageUrl: (recipe['imageUrl'] as String?) ?? '',
                              duration: recipe['duration'] as int,
                              calories: recipe['calories'] as int,
                            ),
                          },
                        );
                      } catch (_) {
                        _showPremiumRequiredDialog();
                      }
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        // Keep card background consistent with theme so title area doesn't show a contrasting band
                        // Keep card background consistent with theme
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // Render image as background and overlay title on top so there's no separate info strip
                      // Render image as background and overlay title
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background image covers whole card
                            recipe['imageUrl'] != null
                                ? Image.network(
                                  recipe['imageUrl']!,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  color: context.theme.cardColor,
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      size: 32,
                                      color: AppColor.neutralGrey500,
                                    ),
                                  ),
                                ),
                            // Dim overlay (optional for readability) - keep fully transparent if you want no overlay
                            // Dim overlay (optional for readability)
                            Positioned.fill(
                              child: Container(
                                // Transparent overlay to remove any visible band — change to Colors.black.withOpacity(0.25) if you want subtle readabilty
                                color: Colors.transparent,
                              ),
                            ),
                            // Badges
                            // Badges
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${recipe['duration']} ${'min'.tr}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.primaryOrange.withOpacity(
                                    0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${recipe['calories']} ${'cal'.tr}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // Title overlay (no background)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 36,
                              child: Text(
                                recipe['title']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.theme.textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      height: 1.2,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.6),
                                          offset: const Offset(0, 1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getMockRecipes() {
    return [
      {
        'title': 'Blueberry Almond Smoothie',
        'imageUrl':
            'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=300&h=200&fit=crop',
        'duration': 10,
        'calories': 400,
      },
      {
        'title': 'Chicken & Quinoa Stuffed Peppers',
        'imageUrl':
            'https://images.unsplash.com/photo-1604909052743-94e838986d24?w=300&h=200&fit=crop',
        'duration': 40,
        'calories': 700,
      },
      {
        'title': 'Peanut Butter Banana Toast',
        'imageUrl':
            'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=300&h=200&fit=crop',
        'duration': 10,
        'calories': 350,
      },
      {
        'title': 'Veggie & Turkey Stir-Fry',
        'imageUrl':
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=300&h=200&fit=crop',
        'duration': 30,
        'calories': 750,
      },
    ];
  }
}

// Minimal inline edit icon used in the Track Food header.
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
    final Color bgColor = AppColor.primaryOrange.withOpacity(
      _pressed ? 0.25 : (_hovered ? 0.18 : 0.12),
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
            splashColor: AppColor.primaryOrange.withOpacity(0.15),
            highlightColor: AppColor.primaryOrange.withOpacity(0.08),
            child: IconTheme(
              data: IconThemeData(color: iconColor),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: _EditIcon()),
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
  const _EditIcon();
  @override
  Widget build(BuildContext context) {
    // Resolve color from parent IconTheme to allow smooth updates
    return Icon(
      Icons.edit_outlined,
      size: 18,
      color: IconTheme.of(context).color ?? AppColor.neutralGrey500,
    );
  }
}

void _navigateToRecipes() async {
  try {
    final appUserService = Get.find<AppUserService>();
    final isPremium = await appUserService.isPremiumNow();
    if (isPremium) {
      Get.toNamed(Routes.recipesView, arguments: {'showBack': true});
    } else {
      _showPremiumRequiredDialog();
    }
  } catch (_) {
    // Fail closed on any error
    _showPremiumRequiredDialog();
  }
}

void _showPremiumRequiredDialog() {
  final txtTheme = Get.textTheme; // use Get context-safe theme
  Get.dialog(
    PremiumRequiredDialog(
      title: 'premium_required'.tr,
      message: 'recipes_premium_message'.tr,
      badge: Text(
        'recipes_premium_badge'.tr,
        textAlign: TextAlign.center,
        style: txtTheme.bodyMedium?.copyWith(
          color: Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
      onUpgrade: () {
        Get.back();
        Get.toNamed(Routes.premiumView);
      },
      onCancel: () => Get.back(),
    ),
  );
}
