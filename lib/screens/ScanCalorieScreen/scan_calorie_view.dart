import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/screens/ScanCalorieScreen/scan_calorie_controller.dart';
import 'package:macroaize/widgets/app_widgets.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:macroaize/widgets/primary_cta.dart';
import 'package:macroaize/widgets/modern_card.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/capsule_macro_grid.dart';
import 'package:macroaize/widgets/usda_badge.dart';

class ScanCalorieView extends GetView<ScanCalorieController> {
  const ScanCalorieView({super.key});

  // quantity selector padding
  static const double _kQuantityInnerGutter = 12.0;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ScanCalorieController>(
      builder: (controller) {
        final showAppBar = !controller.isLoading && controller.calorie != 0;
        return Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          appBar: showAppBar ? _buildModernAppBar(context) : null,
          bottomNavigationBar: _buildBottomCTA(context),
          body:
              controller.isLoading
                  ? _buildLoadingState(context)
                  : _buildResultContent(context, controller),
        );
      },
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
      actions: [
        GetBuilder<ScanCalorieController>(
          builder: (controller) {
            if (controller.calorie != 0 && !controller.isLoading) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Builder(
                  builder:
                      (ctx) => IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () {
                          final box = ctx.findRenderObject() as RenderBox?;
                          final rect =
                              box != null
                                  ? box.localToGlobal(Offset.zero) & box.size
                                  : null;
                          controller.shareMealResult(sharePositionOrigin: rect);
                        },
                        tooltip: 'Share Meal'.tr,
                      ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
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
              child: PrimaryCTA(
                label: "Add Calorie".tr,
                icon: Icons.add_circle_outline,
                onTap: () {
                  controller.onAddButton(context);
                },
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
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Get.back(),
                  color: context.theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. The original Lottie Box Scanner
                SizedBox(
                  height: 250,
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Opacity(
                                    opacity: 0.7,
                                    child:
                                        controller.image != null
                                            ? Image.file(
                                              controller.image!,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              color: Colors.grey[900],
                                              child: const Icon(
                                                Icons.fastfood,
                                                color: Colors.white24,
                                                size: 64,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      AppColor.primaryOrange.withValues(
                                        alpha: 0.9,
                                      ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        AppAssets.macroaizeIcon,
                        width: 28,
                        height: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Macroaize".tr,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 2. The new circular percentage progress underneath
                SizedBox(
                  width: 120,
                  height: 120,
                  child: _SmoothCircularScanProgress(
                    progress: controller.scanProgress,
                    textStyle: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.scanPhaseLabel,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.8,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildHeroImageSection(context, controller),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (controller.calorie != 0)
                      _buildMealInfoCard(context, controller),
                    const SizedBox(height: 16),
                    if (controller.hasBreakdown)
                      _buildMealBreakdown(context, controller),
                    if (controller.calorie != 0)
                      _buildQuantitySelector(context, controller),
                    const SizedBox(height: 20),
                    if (controller.calorie != 0)
                      CapsuleMacroGrid(
                        calories: controller.calorieQuantity,
                        protein: controller.proteinQuantity,
                        carbs: controller.carbsQuantity,
                        fats: controller.fatsQuantity,
                      ),
                    const SizedBox(height: 20),
                    if (controller.calorie != 0)
                      _buildAIChatButton(context, controller),
                    if (controller.calorie == 0) _buildNoDataState(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        // show a back button when app bar is hidden (no data)
        if (controller.calorie == 0)
          Positioned(
            top: 8,
            left: 8,
            child: AppWidgets.backButton(context, () => Get.back()),
          ),
      ],
    );
  }

  Widget _buildHeroImageSection(
    BuildContext context,
    ScanCalorieController controller,
  ) {
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
            if (controller.image != null)
              Image.file(controller.image!, fit: BoxFit.cover)
            else
              Container(
                color: AppColor.neutralGrey800,
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 64,
                    color: AppColor.neutralGrey400,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            if (controller.calorie != 0)
              Positioned(
                top: 16,
                left: 16,
                child: ModernFadeSlideTransition(
                  beginOffset: const Offset(-0.3, 0),
                  child: UsdaBadge(
                    verified: controller.usdaVerified || controller.isBarcode,
                    filled: true,
                  ),
                ),
              ),
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
                      Text(
                        controller.displayMealName,
                        style: context.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMacroBadge(
                              context,
                              icon: AppAssets.calorie,
                              label:
                                  '${controller.calorieQuantity} ${'kcal_unit'.tr}',
                              color: AppColor.primaryOrange,
                            ),
                            _buildMacroBadge(
                              context,
                              icon: AppAssets.protein,
                              label:
                                  '${controller.proteinQuantity.round()}${'g'.tr}',
                              color: AppColor.primaryOrange,
                            ),
                            _buildMacroBadge(
                              context,
                              icon: AppAssets.carb,
                              label:
                                  '${controller.carbsQuantity.round()}${'g'.tr}',
                              color: AppColor.primaryOrange,
                            ),
                            _buildMacroBadge(
                              context,
                              icon: AppAssets.fat,
                              label:
                                  '${controller.fatsQuantity.round()}${'g'.tr}',
                              color: AppColor.primaryOrange,
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

  Widget _buildMealInfoCard(
    BuildContext context,
    ScanCalorieController controller,
  ) {
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
                    color: AppColor.primaryGreen.withValues(alpha: 0.1),
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
                color:
                    context.theme.brightness == Brightness.dark
                        ? AppColor.darkCard.withValues(alpha: 0.9)
                        : AppColor.neutralGrey100.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.buildMealDescription(),
                style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
                textAlign:
                    Get.locale?.languageCode.toLowerCase() == 'ar'
                        ? TextAlign.right
                        : TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    if (controller.isBarcode) {
      return _buildDynamicUnitSelector(context, controller);
    }
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

  Widget _buildQuantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onTap,
  ) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: disabled ? Colors.white.withValues(alpha: 0.6) : Colors.white,
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

  Widget _buildDynamicUnitSelector(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Serving Size".tr,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildUnitTab(context, controller, ScanUnit.unit, 'Unit'.tr),
                const SizedBox(width: 8),
                _buildUnitTab(
                  context,
                  controller,
                  ScanUnit.gram,
                  controller.netWeightUnit == 'ml' ? 'ml'.tr : 'g'.tr,
                ),
                if (controller.netWeightUnit == 'ml') ...[
                  const SizedBox(width: 8),
                  _buildUnitTab(context, controller, ScanUnit.cup, 'Cup'.tr),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildInputForUnit(context, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitTab(
    BuildContext context,
    ScanCalorieController controller,
    ScanUnit unit,
    String label,
  ) {
    final isSelected = controller.selectedUnit == unit;
    return GestureDetector(
      onTap: () => controller.setUnit(unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryOrange : context.theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColor.primaryOrange : AppColor.neutralGrey200,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(
            color:
                isSelected
                    ? Colors.white
                    : context.theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputForUnit(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    switch (controller.selectedUnit) {
      case ScanUnit.unit:
        return Column(
          children: [
            const SizedBox(height: 8),
            Text(
              "(${controller.totalNetWeight} ${controller.netWeightUnit} per unit)",
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColor.neutralGrey400,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepperButton(
                  context,
                  Icons.remove,
                  controller.customAmount > 0.25
                      ? () => controller.decrementCustomAmount()
                      : null,
                ),
                Container(
                  width: 140,
                  alignment: Alignment.center,
                  child: Text(
                    "${controller.customAmount.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} ${'Unit(s)'.tr}",
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryOrange,
                    ),
                  ),
                ),
                _buildStepperButton(
                  context,
                  Icons.add,
                  controller.customAmount < 20.0
                      ? () => controller.incrementCustomAmount()
                      : null,
                ),
              ],
            ),
          ],
        );
      case ScanUnit.gram:
      case ScanUnit.ml:
        return Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryOrange,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "0",
                      hintStyle: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColor.neutralGrey400,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    controller: TextEditingController(
                        text: controller.customAmount
                            .toStringAsFixed(1)
                            .replaceAll(RegExp(r"([.]*0)(?!.*\d)"), ""),
                      )
                      ..selection = TextSelection.fromPosition(
                        TextPosition(
                          offset:
                              controller.customAmount
                                  .toStringAsFixed(1)
                                  .replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")
                                  .length,
                        ),
                      ),
                    onChanged:
                        (val) => controller.updateCustomAmountFromText(val),
                  ),
                ),
                Text(
                  controller.netWeightUnit,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutralGrey600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Enter precise amount",
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColor.neutralGrey400,
                fontSize: 10,
              ),
            ),
          ],
        );
      case ScanUnit.cup:
        return Column(
          children: [
            const SizedBox(height: 8),
            Text(
              "(~240ml per cup)",
              style: context.textTheme.labelSmall?.copyWith(
                color: AppColor.neutralGrey400,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepperButton(
                  context,
                  Icons.remove,
                  controller.customAmount > 0.25
                      ? () => controller.decrementCustomAmount()
                      : null,
                ),
                Container(
                  width: 140,
                  alignment: Alignment.center,
                  child: Text(
                    "${controller.customAmount.toStringAsFixed(2).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} ${'Cup(s)'.tr}",
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.primaryOrange,
                    ),
                  ),
                ),
                _buildStepperButton(
                  context,
                  Icons.add,
                  controller.customAmount < 20.0
                      ? () => controller.incrementCustomAmount()
                      : null,
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildMacroBadge(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onTap,
  ) {
    final bool disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: disabled ? context.theme.cardColor : AppColor.primaryOrange,
          shape: BoxShape.circle,
          boxShadow:
              disabled
                  ? null
                  : [
                    BoxShadow(
                      color: AppColor.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          border: disabled ? Border.all(color: AppColor.neutralGrey200) : null,
        ),
        child: Icon(
          icon,
          color: disabled ? AppColor.neutralGrey400 : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildAIChatButton(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primaryOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ModernButton(
          text: "Ask The Coach".tr,
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
            color: AppColor.primaryOrange,
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
                color: AppColor.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, size: 48, color: AppColor.warning),
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
              icon: const Icon(Icons.psychology, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealBreakdown(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.2),
      child: ModernCard(
        enableGradient: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: AppColor.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'meal_breakdown'.tr,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'tap_to_edit_portions'.tr,
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.theme.textTheme.titleSmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.items.length} ${'items'.tr}',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: AppColor.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: context.theme.cardColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: math.min(itemsHeight(controller.items.length), 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: controller.items.length,
                  separatorBuilder:
                      (ctx, idx) => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColor.neutralGrey200.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                  itemBuilder: (ctx, idx) {
                    final it = controller.items[idx];
                    // Liquids (ml) get [ml, g]; solids get [piece, g].
                    // ml + piece is never offered together.
                    final bool isLiquid = it.unit == 'ml';
                    final units = isLiquid
                        ? const ['ml', 'g']
                        : const ['piece', 'g'];
                    String currentUnit = it.unit;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldBackgroundColor.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.lightShadow.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color:
                                      it.usdaVerified
                                          ? AppColor.success
                                          : AppColor.warning,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  it.name,
                                  style: context.textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      it.usdaVerified
                                          ? AppColor.success.withValues(
                                            alpha: 0.1,
                                          )
                                          : AppColor.warning.withValues(
                                            alpha: 0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        it.usdaVerified
                                            ? AppColor.success.withValues(
                                              alpha: 0.3,
                                            )
                                            : AppColor.warning.withValues(
                                              alpha: 0.3,
                                            ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      it.usdaVerified
                                          ? Icons.verified
                                          : Icons.info_outline,
                                      size: 14,
                                      color:
                                          it.usdaVerified
                                              ? AppColor.success
                                              : AppColor.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      it.usdaVerified
                                          ? 'verified'.tr
                                          : 'estimated'.tr,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color:
                                                it.usdaVerified
                                                    ? AppColor.success
                                                    : AppColor.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColor.neutralGrey300.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: TextFormField(
                                  initialValue: it.amount.toStringAsFixed(
                                    it.amount == it.amount.truncateToDouble()
                                        ? 0
                                        : 1,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    isDense: true,
                                  ),
                                  onFieldSubmitted: (v) {
                                    final val = double.tryParse(v) ?? it.amount;
                                    controller.updateItemAmount(
                                      idx,
                                      val,
                                      currentUnit,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              StatefulBuilder(
                                builder: (ctx2, setState) {
                                  if (!units.contains(currentUnit)) {
                                    currentUnit = units.first;
                                  }
                                  return Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.theme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColor.neutralGrey300
                                            .withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      value: currentUnit,
                                      isDense: true,
                                      underline: const SizedBox.shrink(),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColor.neutralGrey500,
                                        size: 18,
                                      ),
                                      items:
                                          units.map((u) {
                                            final String label;
                                            if (u == 'ml') {
                                              label = 'ml'.tr;
                                            } else if (u == 'g') {
                                              label = 'gram_unit'.tr;
                                            } else {
                                              label = 'unit_piece'.tr;
                                            }
                                            return DropdownMenuItem(
                                              value: u,
                                              child: Text(
                                                label,
                                                style: context
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (u) {
                                        if (u == null) return;
                                        setState(() => currentUnit = u);
                                        controller.updateItemAmount(
                                          idx,
                                          it.amount,
                                          currentUnit,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColor.primaryGreen.withValues(alpha: 0.05),
                                  AppColor.primaryGreen.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColor.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.fitness_center,
                                              size: 14,
                                              color: AppColor.primaryOrange,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${'nut_prt'.tr}: ${it.protein.toStringAsFixed(1)}${'gram_unit'.tr}',
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColor.primaryOrange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.opacity,
                                              size: 14,
                                              color: AppColor.primaryOrange,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${'nut_fat'.tr}: ${it.fat.toStringAsFixed(1)}${'gram_unit'.tr}',
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColor.primaryOrange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${'nut_cal'.tr}: ${it.kcal.round()}',
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColor.primaryOrange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.local_fire_department,
                                              size: 14,
                                              color: AppColor.primaryOrange,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '${'nut_carb'.tr}: ${it.carbs.toStringAsFixed(1)}${'gram_unit'.tr}',
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColor.primaryOrange,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.grain,
                                              size: 14,
                                              color: AppColor.primaryOrange,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // items list height
  double itemsHeight(int count) {
    final per = 100.0;
    return count * per + 20.0;
  }
}

class _SmoothCircularScanProgress extends StatefulWidget {
  final double progress;
  final TextStyle? textStyle;

  const _SmoothCircularScanProgress({
    required this.progress,
    required this.textStyle,
  });

  @override
  State<_SmoothCircularScanProgress> createState() =>
      _SmoothCircularScanProgressState();
}

class _SmoothCircularScanProgressState
    extends State<_SmoothCircularScanProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _currentProgress = widget.progress.clamp(0.0, 1.0);
    _animation = AlwaysStoppedAnimation<double>(_currentProgress);
  }

  @override
  void didUpdateWidget(covariant _SmoothCircularScanProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);
    if ((next - _currentProgress).abs() < 0.0001) return;

    _animation = Tween<double>(
      begin: _currentProgress,
      end: next,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentProgress = next;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = _animation.value.clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: AppColor.neutralGrey200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColor.primaryOrange,
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primaryOrange.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  "${(value * 100).toInt()}%",
                  style: widget.textStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
