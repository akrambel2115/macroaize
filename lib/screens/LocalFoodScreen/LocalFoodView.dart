import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          const SizedBox(height: 12),
          _buildSearchField(context, controller),
          const SizedBox(height: 16),
          if (controller.isFiltering) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primaryOrange),
                backgroundColor: AppColor.neutralGrey200.withOpacity(0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, LocalFoodController controller) {
    // Simple, flat search bar for clean UI
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.neutralGrey200.withOpacity(0.6), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // simple prefix icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.search_rounded,
              color: AppColor.neutralGrey500,
              size: 20,
            ),
          ),

          // input
          Expanded(
            child: TextField(
              controller: controller.textController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
                controller.searchFilter(value, immediate: true);
              },
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
              onChanged: (value) {
                controller.searchFilter(value);
              },
              style: context.textTheme.bodyLarge?.copyWith(
                color: AppColor.neutralGrey900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by Food Name/Dish'.tr,
                hintStyle: context.textTheme.bodyLarge?.copyWith(
                  color: AppColor.neutralGrey500,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // clear button (simple)
          if (controller.textController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.textController.clear();
                controller.searchFilter('', immediate: true);
              },
              icon: Icon(
                Icons.clear_rounded,
                color: AppColor.neutralGrey500,
                size: 20,
              ),
            ),

          // spacing reserved where action button used to be
          const SizedBox(width: 8),
        ],
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
            "${controller.filteredItems.length}${"food items found".tr}",
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Food icon (rounded square) - soft orange background, slightly smaller
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.primaryOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_rounded,
                color: AppColor.primaryOrange,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Food title + meta (quantity + calories)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  food.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColor.neutralGrey900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        food.quantity,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColor.neutralGrey700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // calories chip
                    _buildCalorieChip(context, food.calories),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 'Log' pill button (no plus icon)
          ModernScaleTransition(
            child: GestureDetector(
              onTap: () => controller.onAddButton(context, food),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColor.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primaryOrange.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
    // Make the empty state scrollable and constrained to available height
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                      
                      // Clear search: soft orange circular background (no outline)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primaryOrange.withOpacity(0.12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            final controller = Get.find<LocalFoodController>();
                            controller.textController.clear();
                            controller.searchFilter('', immediate: true);
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColor.primaryOrange,
                            size: 20,
                          ),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          tooltip: 'Clear'.tr,
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
  }
}
