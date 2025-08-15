import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';

class PremiumView extends GetView<PremiumController> {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.neutralGrey50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(context),
                    _buildFeaturesList(context),
                    _buildPricingCards(context),
                    _buildPurchaseButton(context),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColor.lightShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColor.neutralGrey700,
              ),
              onPressed: () => Get.back(),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColor.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.diamond_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => controller.inAppPurchase.restorePurchases(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColor.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "Restore".tr,
                style: context.textTheme.labelMedium?.copyWith(
                  color: AppColor.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return ModernFadeSlideTransition(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColor.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "PREMIUM",
                style: context.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              "Get Premium".tr,
              style: context.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.neutralGrey900,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              "Get All The New Exciting Features".tr,
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColor.neutralGrey600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Hero image with gradient overlay
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColor.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        AppAssets.oneBodyImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColor.primaryGreen.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Text(
                        "Unlock your health potential",
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {
        'title': 'Unlock Food Scanner'.tr,
        'icon': Icons.camera_alt_rounded,
        'color': AppColor.primaryOrange,
      },
      {
        'title': 'Unlock Food Calorie'.tr,
        'icon': Icons.local_fire_department_rounded,
        'color': AppColor.calorieColor,
      },
      {
        'title': 'Unlock Unlimited Chat with Ai'.tr,
        'icon': Icons.smart_toy_rounded,
        'color': AppColor.info,
      },
      {
        'title': 'Unlimited Food Scanner To Calorie'.tr,
        'icon': Icons.all_inclusive_rounded,
        'color': AppColor.accent,
      },
    ];

    return ModernCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Premium Features",
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColor.neutralGrey900,
            ),
          ),
          const SizedBox(height: 20),
          ...features.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> feature = entry.value;
            
            return ModernFadeSlideTransition(
              child: Container(
                margin: EdgeInsets.only(bottom: index < features.length - 1 ? 16 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: feature['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: feature['color'].withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        feature['icon'],
                        color: feature['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        feature['title'],
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColor.neutralGrey800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColor.success,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPricingCards(BuildContext context) {
    return GetBuilder<PremiumController>(
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Your Plan",
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.neutralGrey900,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    return ModernScaleTransition(
                      child: _buildPricingCard(context, controller, index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingCard(BuildContext context, PremiumController controller, int index) {
    final isSelected = controller.selected == index;
    final product = controller.products[index];
    
    final planTypes = ["Week".tr, "Month".tr, "Most Popular".tr];
    final planColors = [AppColor.warning, AppColor.primaryGreen, AppColor.accent];
    
    return GestureDetector(
      onTap: () => controller.onChangeSelectedIndex(index),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: EdgeInsets.only(right: 12, bottom: isSelected ? 0 : 8, top: isSelected ? 0 : 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, AppColor.neutralGrey50],
                )
              : AppColor.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? planColors[index] : AppColor.neutralGrey200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: planColors[index].withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ] : [
            BoxShadow(
              color: AppColor.lightShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Plan type header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [planColors[index], planColors[index].withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Text(
                planTypes[index],
                style: context.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColor.neutralGrey800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Subscription".tr,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutralGrey600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product.price,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: planColors[index],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColor.success,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ModernButton(
        text: "BUY NOW".tr,
        style: ModernButtonStyle.gradient,
        size: ModernButtonSize.large,
        width: double.infinity,
        onPressed: () => controller.buy(),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => controller.openPrivacy(),
              child: Text(
                "Privacy Policy".tr,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: AppColor.neutralGrey300,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => controller.openTerms(),
              child: Text(
                "Terms of Condition".tr,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
