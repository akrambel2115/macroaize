import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ScanCalorieView extends GetView<ScanCalorieController> {
  const ScanCalorieView({super.key});

  // Inner horizontal gutter used by small row controls to keep symmetry with
  // page padding. Change here to tune spacing app-wide for quantity selector.
  static const double _kQuantityInnerGutter = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      bottomNavigationBar: _buildBottomCTA(context),
      body: GetBuilder<ScanCalorieController>(
        builder: (controller) {
          if (controller.isLoading) {
            return _buildLoadingState(context);
          } else {
            return _buildResultContent(context, controller);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      leading: AppWidgets.backButton(context, () => Get.back()),
      backgroundColor: context.theme.scaffoldBackgroundColor,
      title: Text(
        "Calorie Tracker".tr,
        style: context.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return GetBuilder<ScanCalorieController>(
      builder: (controller) {
        if (controller.calorie != 0) {
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppColor.lightShadow,
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ModernFadeSlideTransition(
              child: ModernButton(
                text: "Add Calorie".tr,
                style: ModernButtonStyle.gradient,
                size: ModernButtonSize.large,
                width: double.infinity,
                onPressed: () async {
                  await controller.onAddButton(context);
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 300,
        width: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Food image with glass morphism effect (Lottie overlay is embedded so it
            // always matches the image size responsively)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  // Stack image + animation so the animation always fills this box
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Opacity(
                          opacity: 0.7,
                          child: Image.file(
                            controller.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Lottie overlay (fills same area)
                      Positioned.fill(
                        child: ColorFiltered(
                          // Use srcIn to force the animation to take the tint color
                          // and increase opacity for stronger coloration. If this
                          // still doesn't fully override the original Lottie colors
                          // we can apply a color matrix next.
                          colorFilter: ColorFilter.mode(
                            AppColor.primaryOrange.withOpacity(0.9),
                            BlendMode.srcIn,
                          ),
                          child: Lottie.asset(
                            AppAssets.scanFood,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // removed standalone animation block — now embedded inside the image box
            // Loading text
            Positioned(
              bottom: 20,
              child: ModernFadeSlideTransition(
                beginOffset: const Offset(0, 0.5),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ModernLoadingIndicator(
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Analyzing nutrition...'.tr,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, ScanCalorieController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          // Hero image section
          _buildHeroImageSection(context, controller),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Meal info card
                if (controller.calorie != 0) _buildMealInfoCard(context, controller),
                
                const SizedBox(height: 16),
                
                // Quantity selector
                if (controller.calorie != 0) _buildQuantitySelector(context, controller),
                
                const SizedBox(height: 20),
                
                // Nutrition cards
                if (controller.calorie != 0) _buildNutritionCards(context, controller),
                
                const SizedBox(height: 20),
                
                // AI Chat button
                if (controller.calorie != 0) _buildAIChatButton(context, controller),
                
                // No data state
                if (controller.calorie == 0) _buildNoDataState(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImageSection(BuildContext context, ScanCalorieController controller) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.mediumShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image
            Image.file(
              controller.image,
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Content overlay
            if (controller.calorie != 0)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ModernFadeSlideTransition(
                  beginOffset: const Offset(0, 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primaryGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${controller.calorieQuantity} ${'kcal_unit'.tr}',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.displayMealName,
                        style: context.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
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
  }

  Widget _buildMealInfoCard(BuildContext context, ScanCalorieController controller) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.2),
      child: ModernCard(
        enableGradient: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: AppColor.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'meal_label'.tr,
                        style: context.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.displayMealName,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.neutralGrey100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.buildMealDescription(),
                style: context.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
                textAlign: Get.locale?.languageCode.toLowerCase() == 'ar' 
                  ? TextAlign.right 
                  : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, ScanCalorieController controller) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: _kQuantityInnerGutter),
              child: Text(
                "Quantity".tr,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: _kQuantityInnerGutter),
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GetBuilder<ScanCalorieController>(
                    builder: (c) {
                      return _buildQuantityButton(
                        context,
                        Icons.remove,
                        c.quantity > ScanCalorieController.kMinQuantity
                            ? () => c.decrementQuantity()
                            : null,
                      );
                    },
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: GetBuilder<ScanCalorieController>(
                      builder: (controller) {
                        return Text(
                          controller.quantity.toString(),
                          style: context.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  GetBuilder<ScanCalorieController>(
                    builder: (c) {
                      return _buildQuantityButton(
                        context,
                        Icons.add,
                        c.quantity < ScanCalorieController.kMaxQuantity
                            ? () => c.incrementQuantity()
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context, IconData icon, VoidCallback? onTap) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: disabled ? Colors.white.withOpacity(0.6) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: disabled ? AppColor.neutralGrey400 : AppColor.primaryGreen,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNutritionCards(BuildContext context, ScanCalorieController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ModernFadeSlideTransition(
                beginOffset: const Offset(-0.2, 0.2),
                child: GetBuilder<ScanCalorieController>(
                  builder: (controller) {
                    return ModernNutrientCard(
                      label: "Calorie".tr,
                      value: controller.calorieQuantity.toString(),
                      unit: 'kcal_unit'.tr,
                      color: AppColor.calorieColor,
                      icon: Icons.local_fire_department,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ModernFadeSlideTransition(
                beginOffset: const Offset(0.2, 0.2),
                  child: GetBuilder<ScanCalorieController>(
                  builder: (controller) {
                    return ModernNutrientCard(
                      label: "Protein".tr,
                      value: controller.proteinQuantity.toString(),
                      unit: 'protein_unit'.tr,
                      color: AppColor.proteinColor,
                      icon: null,
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.proteinColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            AppAssets.protein,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            color: AppColor.proteinColor,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ModernFadeSlideTransition(
                beginOffset: const Offset(-0.2, 0.3),
                  child: GetBuilder<ScanCalorieController>(
                  builder: (controller) {
                    return ModernNutrientCard(
                      label: "Carbs".tr,
                      value: controller.carbsQuantity.toString(),
                      unit: 'carbs_unit'.tr,
                      color: AppColor.carbsColor,
                      icon: null,
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.carbsColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            AppAssets.carb,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            color: AppColor.carbsColor,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ModernFadeSlideTransition(
                beginOffset: const Offset(0.2, 0.3),
                  child: GetBuilder<ScanCalorieController>(
                  builder: (controller) {
                    return ModernNutrientCard(
                      label: "Fats".tr,
                      value: controller.fatsQuantity.toString(),
                      unit: 'fat_unit'.tr,
                      color: AppColor.fatsColor,
                      icon: null,
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.fatsColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            AppAssets.fat,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            color: AppColor.fatsColor,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIChatButton(BuildContext context, ScanCalorieController controller) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primaryOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ModernButton(
          text: "Ask with AI".tr,
          style: ModernButtonStyle.ghost,
          size: ModernButtonSize.large,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(12),
          onPressed: () {
            Get.toNamed(
              Routes.chatView,
              arguments: {"image": controller.image},
            );
          },
          icon: Image.asset(
            AppAssets.ai,
            height: 24,
            width: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: ModernCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: AppColor.warning,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This picture not available Calorie,Protein,Carbs and Fats,".tr,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppColor.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ModernButton(
              text: "Ask Coach".tr,
              style: ModernButtonStyle.secondary,
              size: ModernButtonSize.medium,
              onPressed: () {
                Get.toNamed(
                  Routes.chatView,
                  arguments: {"image": controller.image},
                );
              },
              icon: const Icon(
                Icons.psychology,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
