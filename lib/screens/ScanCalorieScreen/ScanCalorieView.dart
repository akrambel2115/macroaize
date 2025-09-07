import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieController.dart';
import 'package:foodcalorietracker/widgets/AppWidgets.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/customButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/widgets/CapsuleMacroGrid.dart';
import 'package:foodcalorietracker/widgets/UsdaBadge.dart';

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
      actions: [],
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
              child: CustomButtom(
                backgroundcolor: context.theme.focusColor,
                btncolor: Colors.white,
                btntext: "Add Calorie".tr,
                ontap: () async {
                  await controller.onAddButton(context);
                },
                sufixicon: const Icon(
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

  Widget _buildResultContent(
    BuildContext context,
    ScanCalorieController controller,
  ) {
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
                if (controller.calorie != 0)
                  _buildMealInfoCard(context, controller),

                const SizedBox(height: 16),

                // Meal Breakdown (if available)
                if (controller.hasBreakdown)
                  _buildMealBreakdown(context, controller),

                // Quantity selector (fallback for single item mode)
                if (!controller.hasBreakdown && controller.calorie != 0)
                  _buildQuantitySelector(context, controller),

                const SizedBox(height: 20),

                // Capsule macro grid (animated) — uses totals either from items or single
                if (controller.calorie != 0)
                  CapsuleMacroGrid(
                    calories: controller.calorieQuantity,
                    protein: controller.proteinQuantity,
                    carbs: controller.carbsQuantity,
                    fats: controller.fatsQuantity,
                  ),

                const SizedBox(height: 20),

                // AI Chat button
                if (controller.calorie != 0)
                  _buildAIChatButton(context, controller),

                // No data state
                if (controller.calorie == 0) _buildNoDataState(context),
              ],
            ),
          ),
        ],
      ),
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
            // Main image
            Image.file(controller.image, fit: BoxFit.cover),
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
            // USDA Badge - Top Left
            if (controller.calorie != 0)
              Positioned(
                top: 16,
                left: 16,
                child: ModernFadeSlideTransition(
                  beginOffset: const Offset(-0.3, 0),
                  child: UsdaBadge(
                    verified: controller.usdaVerified,
                    filled:
                        true, // Use filled background for better visibility over image
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

  Widget _buildAIChatButton(
    BuildContext context,
    ScanCalorieController controller,
  ) {
    return ModernFadeSlideTransition(
      beginOffset: const Offset(0, 0.3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primaryOrange.withOpacity(0.12),
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
                color: AppColor.warning.withOpacity(0.1),
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
            // Enhanced header with better spacing and visual hierarchy
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons
                          .fastfood, // different icon from the meal info section
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
                          // match meal name title style
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'tap_to_edit_portions'.tr,
                          // match meal info small label style
                          style: context.textTheme.titleSmall?.copyWith(
                            // keep a slightly muted tone to mirror meal info label
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
                      color: AppColor.primaryGreen.withOpacity(0.1),
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
            // Enhanced scrollable item list with improved design
            Container(
              decoration: BoxDecoration(
                color: context.theme.cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColor.neutralGrey200.withOpacity(0.5),
                  width: 1,
                ),
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
                              AppColor.neutralGrey200.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                  itemBuilder: (ctx, idx) {
                    final it = controller.items[idx];
                    final units = const [
                      'piece',
                      'g',
                    ]; // Limited to only piece and g
                    String currentUnit = it.unit;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.scaffoldBackgroundColor
                            .withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.lightShadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item header with name and badge
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
                                          ? AppColor.success.withOpacity(0.1)
                                          : AppColor.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        it.usdaVerified
                                            ? AppColor.success.withOpacity(0.3)
                                            : AppColor.warning.withOpacity(0.3),
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

                          // Controls row (amount input and unit selector)
                          Row(
                            children: [
                              // Amount input with modern styling
                              Container(
                                width: 80,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColor.neutralGrey300.withOpacity(
                                      0.5,
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

                              // Unit selector with enhanced styling
                              StatefulBuilder(
                                builder: (ctx2, setState) {
                                  // Ensure currentUnit is valid, fallback to 'g' if invalid
                                  if (!['piece', 'g'].contains(currentUnit)) {
                                    currentUnit = 'g';
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
                                            .withOpacity(0.5),
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
                                            final label =
                                                u == 'g'
                                                    ? 'gram_unit'.tr
                                                    : 'unit_piece'.tr;
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

                          // Nutrition info with full width display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColor.primaryGreen.withOpacity(0.05),
                                  AppColor.primaryGreen.withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColor.primaryGreen.withOpacity(0.1),
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
                                    // Left column: Protein (top) and Fat (bottom)
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
                                              '${'nut_prt'.tr}: ${it.protein.round()}${'gram_unit'.tr}',
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
                                              '${'nut_fat'.tr}: ${it.fat.round()}${'gram_unit'.tr}',
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

                                    // Right column: Calories (top) and Carbs (bottom)
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
                                              '${'nut_carb'.tr}: ${it.carbs.round()}${'gram_unit'.tr}',
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
            // totals are shown in the capsule macro grid above; removed duplicate totals box
          ],
        ),
      ),
    );
  }

  // Approximate height for N items (each row ~90 px + padding)
  double itemsHeight(int count) {
    final per = 100.0; // rough per-item height
    return count * per + 20.0; // extra padding
  }

  // _buildTotalMacro removed — totals are displayed by the capsule macro grid above.
}
