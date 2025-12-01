import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/Model/Recipe.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({super.key, required this.recipe, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildImageSection()),

              Expanded(flex: 2, child: _buildInfoSection(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColor.neutralGrey200,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child:
                recipe.imageUrl.isNotEmpty
                    ? _buildNetworkImage()
                    : _buildPlaceholderImage(),
          ),
        ),

        Positioned(
          bottom: 8,
          left: 8,
          child: _buildBadge(
            icon: Icons.access_time_rounded,
            text: '${recipe.duration} ${'min'.tr}',
            backgroundColor: Colors.black.withOpacity(0.7),
            textColor: Colors.white,
          ),
        ),

        Positioned(
          bottom: 8,
          right: 8,
          child: _buildBadge(
            text: '${recipe.calories} ${'cal'.tr}',
            backgroundColor: AppColor.primaryOrange.withOpacity(0.9),
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final targetW = (constraints.maxWidth * dpr).clamp(64, 1024).round();
        final targetH = (constraints.maxHeight * dpr).clamp(64, 1024).round();
        return Image.network(
          recipe.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: targetW,
          cacheHeight: targetH,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,

          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox.expand();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 48,
        color: AppColor.neutralGrey500,
      ),
    );
  }

  Widget _buildBadge({
    IconData? icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            recipe.localizedTitle(Get.locale?.languageCode ?? 'en'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          _buildTags(context),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    final color = _difficultyColor(recipe.difficulty);
    return Text(
      recipe.localizedDifficulty(Get.locale?.languageCode ?? 'en'),
      style: context.theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    final d = difficulty.toLowerCase().trim();
    if (d.contains('easy')) return AppColor.success;
    if (d.contains('medium') || d.contains('med')) return AppColor.warning;
    if (d.contains('hard') || d.contains('difficult')) return AppColor.error;
    // fallback: neutral text color
    return AppColor.neutralGrey600;
  }
}
