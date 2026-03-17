import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/LocalFoodScreen/local_food_controller.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_card.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';

class LocalFoodView extends GetView<LocalFoodController> {
  const LocalFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, controller),
        backgroundColor: AppColor.primaryOrange,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GetBuilder<LocalFoodController>(
        builder: (controller) {
          return Column(
            children: [
              _buildSearchSection(context, controller),
              _buildResultsCount(context, controller),
              Expanded(child: _buildFoodList(context, controller)),
            ],
          );
        },
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    LocalFoodController controller, {
    int? editIndex,
  }) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatsCtrl = TextEditingController();

    if (editIndex != null &&
        editIndex >= 0 &&
        editIndex < controller.filteredItems.length) {
      final existing = controller.filteredItems[editIndex];
      nameCtrl.text = existing.name;
      qtyCtrl.text = existing.quantity;
      calCtrl.text = existing.calories.toString();
      proteinCtrl.text = existing.protein.toString();
      carbsCtrl.text = existing.carbs.toString();
      fatsCtrl.text = existing.fats.toString();
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final borderColor =
            ctx.theme.brightness == Brightness.dark
                ? AppColor.neutralGrey700
                : AppColor.neutralGrey300.withValues(alpha: 0.8);

        InputDecoration inputDecoration(String label) => InputDecoration(
          labelText: label,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
        );

        return AlertDialog(
          backgroundColor: ctx.theme.cardColor,
          title: Text(
            editIndex == null ? 'add_custom_food'.tr : 'edit_food'.tr,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: inputDecoration('name'.tr),
                ),
                TextField(
                  controller: qtyCtrl,
                  decoration: inputDecoration('quantity'.tr),
                ),
                TextField(
                  controller: calCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration('calories'.tr),
                ),
                TextField(
                  controller: proteinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration('proteins'.tr),
                ),
                TextField(
                  controller: carbsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration('carbs'.tr),
                ),
                TextField(
                  controller: fatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration('fats'.tr),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => safeBack(),
              child: Text(
                'cancel'.tr,
                style: TextStyle(
                  color: AppColor.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final qty = qtyCtrl.text.trim();
                final calories = int.tryParse(calCtrl.text.trim()) ?? 0;
                final protein = int.tryParse(proteinCtrl.text.trim()) ?? 0;
                final carbs = int.tryParse(carbsCtrl.text.trim()) ?? 0;
                final fats = int.tryParse(fatsCtrl.text.trim()) ?? 0;

                final item = FoodItem(
                  name: name.isEmpty ? 'Custom Food'.tr : name,
                  calories: calories,
                  carbs: carbs,
                  protein: protein,
                  quantity: qty.isEmpty ? '-'.tr : qty,
                  fats: fats,
                );

                if (editIndex == null) {
                  controller.addCustomFood(item);
                } else {
                  controller.editFoodAt(editIndex, item);
                }

                safeBack();
              },
              child: Text(
                editIndex == null ? 'add'.tr : 'save'.tr,
                style: TextStyle(
                  color: AppColor.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final systemOverlayStyle =
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: systemOverlayStyle.copyWith(
        statusBarColor: Colors.transparent,
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColor.darkText : AppColor.neutralGrey700,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      title: Text(
        'Local Food'.tr,
        style: context.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              context.theme.brightness == Brightness.dark
                  ? AppColor.darkText
                  : AppColor.neutralGrey900,
        ),
      ),
      actions: [],
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    LocalFoodController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Food'.tr,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  context.theme.brightness == Brightness.dark
                      ? AppColor.darkText
                      : AppColor.neutralGrey900,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColor.primaryOrange,
                ),
                backgroundColor: AppColor.neutralGrey200.withValues(alpha: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    LocalFoodController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              context.theme.brightness == Brightness.dark
                  ? AppColor.neutralGrey800
                  : AppColor.neutralGrey200.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.search_rounded,
              color: AppColor.neutralGrey500,
              size: 20,
            ),
          ),

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
                color:
                    context.theme.brightness == Brightness.dark
                        ? AppColor.darkText
                        : AppColor.neutralGrey900,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by Food Name/Dish'.tr,
                hintStyle: context.textTheme.bodyLarge?.copyWith(
                  color:
                      context.theme.brightness == Brightness.dark
                          ? AppColor.darkTextSecondary
                          : AppColor.neutralGrey500,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

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

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildResultsCount(
    BuildContext context,
    LocalFoodController controller,
  ) {
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
          Expanded(
            child: Text(
              controller.textController.text.trim().isEmpty
                  ? "100 ${"popular food items".tr}"
                  : "${controller.filteredItems.length} ${"food items found".tr}",
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColor.neutralGrey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  controller.isEditing
                      ? Icons.close_rounded
                      : Icons.tune_rounded,
                  color: AppColor.neutralGrey700,
                ),
                onPressed: () => controller.toggleEditMode(),
              ),
              if (controller.isEditing) ...[
                IconButton(
                  tooltip: 'add_custom_food'.tr,
                  icon: Icon(Icons.add_rounded, color: AppColor.neutralGrey700),
                  onPressed: () => _showAddEditDialog(context, controller),
                ),
                IconButton(
                  tooltip: 'delete_selected'.tr,
                  icon: Icon(
                    Icons.delete_rounded,
                    color:
                        controller.selectedIndices.isNotEmpty
                            ? Colors.red
                            : AppColor.neutralGrey500,
                  ),
                  onPressed:
                      controller.selectedIndices.isNotEmpty
                          ? () => controller.deleteSelected(context)
                          : null,
                ),
              ],
            ],
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

  Widget _buildFoodItem(
    BuildContext context,
    LocalFoodController controller,
    int index,
  ) {
    final food = controller.filteredItems[index];
    return GestureDetector(
      onTap: () {
        if (!controller.isEditing) {
          _showNutritionDetails(context, controller, food);
        }
      },
      onLongPress: () => controller.selectAndEnterEdit(index),
      child: ModernCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColor.primaryOrange.withValues(alpha: 0.12),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    food.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          context.theme.brightness == Brightness.dark
                              ? AppColor.darkText
                              : AppColor.neutralGrey900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
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
                      _buildCalorieChip(context, food.calories),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            GetBuilder<LocalFoodController>(
              builder: (controller) {
                if (!controller.isEditing) return SizedBox.shrink();
                final idx = index;
                final canEdit = food.isCustom;
                final selected = controller.selectedIndices.contains(idx);
                return Row(
                  children: [
                    Checkbox(
                      value: canEdit ? selected : false,
                      onChanged:
                          canEdit ? (_) => controller.toggleSelect(idx) : null,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color:
                            canEdit
                                ? AppColor.neutralGrey700
                                : AppColor.neutralGrey500,
                      ),
                      onPressed:
                          canEdit
                              ? () => _showAddEditDialog(
                                context,
                                controller,
                                editIndex: idx,
                              )
                              : null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNutritionDetails(
    BuildContext parentContext,
    LocalFoodController controller,
    FoodItem food,
  ) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        double quantity = 1.0;
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.55,
              minChildSize: 0.30,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColor.neutralGrey300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColor.primaryOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        color: AppColor.primaryOrange,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          food.name,
                                          style: context.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    context.theme.brightness ==
                                                            Brightness.dark
                                                        ? AppColor.darkText
                                                        : AppColor
                                                            .neutralGrey900,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          quantity == 1.0
                                              ? food.quantity
                                              : '${food.quantity} × ${quantity % 1 == 0 ? quantity.toInt() : quantity}',
                                          style: context.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    context.theme.brightness ==
                                                            Brightness.dark
                                                        ? AppColor
                                                            .darkTextSecondary
                                                        : AppColor
                                                            .neutralGrey600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              Text(
                                "Quantity".tr,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      context.theme.brightness ==
                                              Brightness.dark
                                          ? AppColor.darkText
                                          : AppColor.neutralGrey900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      context.theme.brightness ==
                                              Brightness.dark
                                          ? AppColor.neutralGrey800.withValues(
                                            alpha: 0.3,
                                          )
                                          : AppColor.neutralGrey50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity > 0.25) {
                                          setState(() => quantity -= 0.25);
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              quantity > 0.25
                                                  ? AppColor.primaryOrange
                                                  : AppColor.neutralGrey700,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.remove_rounded,
                                            color:
                                                quantity > 0.25
                                                    ? Colors.white
                                                    : AppColor.neutralGrey500,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Text(
                                      quantity % 1 == 0
                                          ? quantity.toInt().toString()
                                          : quantity.toString(),
                                      style: context.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                context.theme.brightness ==
                                                        Brightness.dark
                                                    ? AppColor.darkText
                                                    : AppColor.neutralGrey900,
                                          ),
                                    ),
                                    const SizedBox(width: 20),
                                    GestureDetector(
                                      onTap: () {
                                        if (quantity < 20) {
                                          setState(() => quantity += 0.25);
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              quantity < 20
                                                  ? AppColor.primaryOrange
                                                  : (context.theme.brightness ==
                                                          Brightness.dark
                                                      ? AppColor.neutralGrey700
                                                      : AppColor
                                                          .neutralGrey300),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add_rounded,
                                            color:
                                                quantity < 20
                                                    ? Colors.white
                                                    : AppColor.neutralGrey500,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              Text(
                                "nutrition_details".tr,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      context.theme.brightness ==
                                              Brightness.dark
                                          ? AppColor.darkText
                                          : AppColor.neutralGrey900,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _nutrientTile(
                                    context,
                                    Image.asset(
                                      'assets/icons/calorie.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    '',
                                    (food.calories * quantity)
                                        .round()
                                        .toString(),
                                  ),
                                  _nutrientTile(
                                    context,
                                    Image.asset(
                                      'assets/icons/protein.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    '',
                                    '${(food.protein * quantity).round().toStringAsFixed(1)} ${"protein_unit".tr}',
                                  ),
                                  _nutrientTile(
                                    context,
                                    Image.asset(
                                      'assets/icons/carb.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    '',
                                    '${(food.carbs * quantity).round().toStringAsFixed(1)} ${"carbs_unit".tr}',
                                  ),
                                  _nutrientTile(
                                    context,
                                    Image.asset(
                                      'assets/icons/fat.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    '',
                                    '${(food.fats * quantity).round().toStringAsFixed(1)} ${"fat_unit".tr}',
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        safeBack();
                                        final modifiedFood = FoodItem(
                                          name: food.name,
                                          calories:
                                              (food.calories * quantity)
                                                  .round(),
                                          protein:
                                              (food.protein * quantity).round(),
                                          carbs:
                                              (food.carbs * quantity).round(),
                                          fats: (food.fats * quantity).round(),
                                          quantity:
                                              '${food.quantity} × ${quantity % 1 == 0 ? quantity.toInt() : quantity}',
                                        );
                                        controller.onAddButton(
                                          parentContext,
                                          modifiedFood,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        "log".tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColor.primaryOrange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 1,
                                    child: OutlinedButton(
                                      onPressed: () => safeBack(),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color:
                                              context.theme.brightness ==
                                                      Brightness.dark
                                                  ? AppColor.neutralGrey700
                                                  : AppColor.neutralGrey300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'close'.tr,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              context.theme.brightness ==
                                                      Brightness.dark
                                                  ? AppColor.darkText
                                                  : AppColor.neutralGrey700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          },
        );
      },
    );
  }

  Widget _nutrientTile(
    BuildContext context,
    Widget iconWidget,
    String? label,
    String value,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  context.theme.brightness == Brightness.dark
                      ? AppColor.darkCard
                      : AppColor.neutralGrey50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 8),
          if (label != null && label.isNotEmpty) ...[
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color:
                    context.theme.brightness == Brightness.dark
                        ? AppColor.darkTextSecondary
                        : AppColor.neutralGrey600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  context.theme.brightness == Brightness.dark
                      ? AppColor.darkText
                      : AppColor.neutralGrey900,
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
        color: AppColor.calorieColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColor.calorieColor.withValues(alpha: 0.3),
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
    // scrollable empty state
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                        'Try searching with different keywords or browse our local food database'
                            .tr,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColor.neutralGrey600,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.primaryOrange.withValues(alpha: 0.12),
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
