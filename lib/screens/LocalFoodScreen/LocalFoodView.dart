import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class LocalFoodView extends GetView<LocalFoodController> {
  const LocalFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: GetBuilder<LocalFoodController>(
        builder: (controller) {
          return Column(
            children: [
              _buildSearchSection(context, controller),
              _buildResultsCount(context, controller),
              Expanded(
                child: _buildFoodList(context, controller),
              ),
            ],
          );
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
            color: AppColor.neutralGrey700,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Text(
        'Local Food'.tr,
        style: context.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColor.neutralGrey900,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: AppColor.neutralGrey700,
            ),
            onPressed: () {
              // open settings/config
              Get.toNamed(Routes.settingView);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context, LocalFoodController controller) {
    return ModernCard(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Food'.tr,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColor.neutralGrey900,
            ),
          ),
          const SizedBox(height: 16),
          _buildSearchField(context, controller),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, LocalFoodController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.neutralGrey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.neutralGrey200,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller.textController,
        onTapOutside: (event) => FocusScope.of(context).unfocus(),
        onChanged: (value) {
          controller.textController.text = value;
          controller.searchFilter(controller.textController.text);
          controller.update();
        },
        style: context.textTheme.bodyLarge?.copyWith(
          color: AppColor.neutralGrey900,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColor.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          hintText: 'Search by Food Name/Dish'.tr,
          hintStyle: context.textTheme.bodyLarge?.copyWith(
            color: AppColor.neutralGrey500,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: controller.textController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    controller.textController.clear();
                    controller.searchFilter('');
                    controller.update();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColor.neutralGrey500,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildResultsCount(BuildContext context, LocalFoodController controller) {
    if (controller.filteredItems.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 16,
            color: AppColor.neutralGrey600,
          ),
          const SizedBox(width: 8),
          Text(
            '${controller.filteredItems.length} food items found',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColor.neutralGrey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(BuildContext context, LocalFoodController controller) {
    if (controller.filteredItems.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.filteredItems.length,
      itemBuilder: (context, index) {
        return ModernFadeSlideTransition(
          child: _buildFoodItem(context, controller, index),
        );
      },
    );
  }

  Widget _buildFoodItem(BuildContext context, LocalFoodController controller, int index) {
    final food = controller.filteredItems[index];
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Food icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColor.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutralGrey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  food.quantity,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutralGrey600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCalorieChip(context, food.calories),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Add button
          ModernScaleTransition(
            child: GestureDetector(
              onTap: () {
                controller.onAddButton(context, food);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieChip(BuildContext context, int calories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.calorieColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.calorieColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: AppColor.calorieColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$calories Cal',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColor.calorieColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'No Food Found'.tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.neutralGrey800,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Try searching with different keywords or browse our local food database'.tr,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 32),
              
              ModernButton(
                text: 'Clear Search'.tr,
                style: ModernButtonStyle.outline,
                size: ModernButtonSize.medium,
                onPressed: () {
                  Get.find<LocalFoodController>().textController.clear();
                  Get.find<LocalFoodController>().searchFilter('');
                  Get.find<LocalFoodController>().update();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
