import 'package:foodcalorietracker/widgets/PrimaryCTA.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/Model/Recipe.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/widgets/CalorieRing.dart';
// ...existing code...

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _servings = 1;


  List<Map<String, String>> get _ingredients {
    // convert recipe.ingredients (List<String>) into name/qty pairs when possible
    if (widget.recipe.ingredients.isEmpty) return [];
    return widget.recipe.ingredients.map((s) {
      // try splitting on two-column separator
      final parts = s.split(RegExp(r"\s{2,}|\t| - ")); // flexible split
      if (parts.length >= 2) return {"name": parts[0], "qty": parts[1]};
      return {"name": s, "qty": ""};
    }).toList();
  }

  List<String> get _steps => widget.recipe.instructions.isNotEmpty
      ? widget.recipe.instructions
      : ["Mix all ingredients in a blender until smooth.", "Taste and add honey if needed.", "Serve chilled and enjoy."];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context),
                  const SizedBox(height: 12),
                  _buildDescription(context, isDark),
                  const SizedBox(height: 4),
                  _buildMacros(context),
                  const SizedBox(height: 12),
                  _buildIngredients(context),
                  const SizedBox(height: 12),
                  _buildDirections(context),
                  const SizedBox(height: 96), // space for bottom button
                ],
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    // Mirror the ScanCalorie hero: rounded bottom, image with gradient overlay,
    // bottom calorie pill and centered title with shadow.
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: AppColor.mediumShadow, blurRadius: 20, offset: const Offset(0, 8)),
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
            // Image with cache sizing
            LayoutBuilder(builder: (context, constraints) {
              final dpr = MediaQuery.of(context).devicePixelRatio;
              final targetW = (constraints.maxWidth * dpr).clamp(64, 2048).round();
              final targetH = (constraints.maxHeight * dpr).clamp(64, 2048).round();
              final imageUrl = widget.recipe.imageUrl.isNotEmpty
                  ? widget.recipe.imageUrl
                  : 'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?w=1200';
              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: targetW,
                cacheHeight: targetH,
                filterQuality: FilterQuality.low,
              );
            }),

            // Gradient overlay (transparent -> darker at bottom)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.35), Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Top-left: white back icon only (no page title)
            Positioned(
              left: 12,
              top: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Get.back(),
              ),
            ),

            // Bottom-left: title and small labels aligned to left. Time label placed beside calories.
            Positioned(
              left: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe.title,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black.withOpacity(0.5), offset: const Offset(0, 2), blurRadius: 4),
                          ],
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Time pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text('${widget.recipe.duration} ${'min'.tr}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Calorie pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColor.primaryGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('${widget.recipe.calories} ${'kcal_unit'.tr}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
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
  }

  // _badge removed — ScanCalorie's pill styling is used inline in the hero instead.

  Widget _buildDescription(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('description'.tr, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          // Static description — removed expand/collapse toggle to avoid gaps
          Text(
            '${'description'.tr} ${'description'.tr}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMacros(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  Icons.pie_chart_outline,
                  color: AppColor.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text('macronutrients'.tr, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroRing(
                label: 'Carbs',
                value: '${widget.recipe.carbs}g',
                color: Colors.green,
                progress: (widget.recipe.carbs / 100).toDouble().clamp(0.0, 1.0),
              ),
              _macroRing(
                label: 'Protein',
                value: '${widget.recipe.protein}g',
                color: Colors.red,
                progress: (widget.recipe.protein / 100).toDouble().clamp(0.0, 1.0),
              ),
              _macroRing(
                label: 'Fat',
                value: '${widget.recipe.fat}g',
                color: Colors.orange,
                progress: (widget.recipe.fat / 100).toDouble().clamp(0.0, 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _macroCircle removed in favor of shared CalorieRing via _macroRing

  Widget _macroRing({required String label, required String value, required Color color, required double progress}) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Use CalorieRing but limit size via container; progress controls sweep
              CalorieRing(
                progress: progress,
                size: 80,
                strokeWidth: 10,
                progressColor: color,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildIngredients(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  Icons.list_alt_outlined,
                  color: AppColor.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text('ingredients'.tr, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _buildServingSelector(context),
          ),
          const SizedBox(height: 8),
          ..._ingredients.map((it) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(it['name']!, style: const TextStyle(fontSize: 14))),
                      Text(it['qty']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // dotted separator approximation
                  Container(height: 1, width: double.infinity, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                ],
              ))
        ],
      ),
    );
  }

  Widget _buildServingSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColor.primaryGradient,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() { if (_servings > 1) _servings--; }),
            child: _quantityButton(context, Icons.remove),
          ),
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              '$_servings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _servings++),
            child: _quantityButton(context, Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(BuildContext context, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: AppColor.primaryGreen),
    );
  }

  Widget _buildDirections(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(width: 8),
              Text('directions'.tr, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map((e) {
            final idx = e.key + 1;
            final text = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    alignment: Alignment.center,
                    child: Text('$idx', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
  return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
            child: PrimaryCTA(
              label: 'add_to_plan'.tr,
              onTap: () {
                // Keep existing behavior; replace later with controller logic
                Get.snackbar('success'.tr, 'food_added_success'.tr);
              },
            ),
    );
  }
}
