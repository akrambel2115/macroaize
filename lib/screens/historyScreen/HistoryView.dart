import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/historyScreen/DeleteDailog.dart';
import 'package:foodcalorietracker/screens/historyScreen/HistoryController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ContinueButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:foodcalorietracker/widgets/NutritionBadge.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: GetBuilder<HistoryController>(
        builder: (controller) {
          if (controller.sqlHistory.isNotEmpty) {
            return _buildHistoryList(context, controller);
          } else {
            return _buildEmptyState(context);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color:
                context.theme.brightness == Brightness.light
                    ? AppColor.neutralGrey700
                    : Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Text(
        "History".tr,
        style: context.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              context.theme.brightness == Brightness.light
                  ? AppColor.neutralGrey900
                  : Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GetBuilder<HistoryController>(
            builder: (c) {
              return IconButton(
                icon: Transform.rotate(
                  angle: c.sortAsc ? math.pi : 0,
                  child: Icon(
                    Icons.sort,
                    color:
                        context.theme.brightness == Brightness.light
                            ? AppColor.neutralGrey700
                            : Colors.white,
                  ),
                ),
                onPressed: () {
                    controller.toggleSort();
                  },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context, HistoryController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        controller.getHistory();
      },
      color: AppColor.primaryGreen,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ModernFadeSlideTransition(
                  child: _buildHistoryCard(context, controller, index),
                );
              }, childCount: controller.sqlHistory.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryController controller,
    int index,
  ) {
    final historyItem = controller.sqlHistory[index];

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header with meal type and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMealTypeChip(context, historyItem.type.toString()),
              ModernScaleTransition(
                child: GestureDetector(
                  onTap: () {
                      showCustomDeleteDialog(
                        onDelete: () {
                          controller.dbHelper.deleteCalorieHistory(
                            historyItem.id!,
                          );
                          controller.getHistory();
                        },
                        context: context,
                      );
                    },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColor.error,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Show title instead of image for both local and scanned meals
          Center(child: _buildHistoryTitle(context, historyItem.title)),
          const SizedBox(height: 16),
          // Nutrition items rendered inline to avoid overflow.
          Row(
            children: [
              Expanded(
                child: NutritionBadge(
                  label: "Calorie".tr,
                  value: historyItem.calorie.toString(),
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
                  value: historyItem.protein.toString(),
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
                  value: historyItem.carbs.toString(),
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
                  value: historyItem.fats.toString(),
                  iconWidget: Image.asset(AppAssets.fat, width: 28, height: 28),
                  accentColor: AppColor.historyAccent,
                  iconSize: 28,
                  unit: 'fat_unit'.tr,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildTimestamp(context),
        ],
      ),
    );
  }

  Widget _buildMealTypeChip(BuildContext context, String mealType) {
    Color chipColor;
    String chipIconAsset = '';

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        chipColor = AppColor.warning;
        chipIconAsset = AppAssets.breakfast;
        break;
      case 'lunch':
        chipColor = AppColor.primaryGreen;
        chipIconAsset = AppAssets.lunch;
        break;
      case 'dinner':
        chipColor = AppColor.info;
        chipIconAsset = AppAssets.dinner;
        break;
      default:
        chipColor = AppColor.accent;
        chipIconAsset = AppAssets.moreIcon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chipIconAsset.isNotEmpty
              ? Image.asset(chipIconAsset, width: 16, height: 16)
              : Icon(Icons.cookie_outlined, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            mealType.tr,
            style: context.textTheme.labelMedium?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTitle(BuildContext context, String? title) {
    final String display =
        (title == null || title.trim().isEmpty)
            ? 'unknown_meal'.tr
            : title.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.neutralGrey300.withOpacity(0.5)),
      ),
      child: Text(
        display,
        textAlign: TextAlign.center,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // Nutrition logic extracted to `NutritionBadge` widget for reuse.

  Widget _buildTimestamp(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: AppColor.neutralGrey500,
        ),
        const SizedBox(width: 6),
        Text(
    DateTime.now().toString().split(' ')[0],
          style: context.textTheme.labelSmall?.copyWith(
            color: AppColor.neutralGrey500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: ModernFadeSlideTransition(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                "No History Yet".tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.neutralGrey800,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Start tracking your meals to see your nutrition history here"
                    .tr,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              ContinueButton(
                labelKey: 'Track Food',
                icon: null,
                onTap: () {
                  // TODO: Navigate to scan food screen
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}