import 'package:flutter/material.dart';

class NutritionBadge extends StatelessWidget {
  final String label;
  final String value;
  final Widget iconWidget;
  final Color? accentColor;
  final double iconSize;
  final String? unit;

  const NutritionBadge({
    Key? key,
    required this.label,
    required this.value,
    required this.iconWidget,
    this.accentColor,
    this.iconSize = 28,
    this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon at the top
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white12 : Colors.white,
            ),
            child: SizedBox(width: iconSize, height: iconSize, child: iconWidget),
          ),
          const SizedBox(height: 8),

          // Value and optional unit
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value.trim().isEmpty ? '-' : value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? const Color(0xFFF0F6FC) : (accentColor ?? const Color(0xFFfb7414)),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(
                  unit!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? const Color(0xFF8B949E) : const Color(0xFF80868B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Label below the quantity
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF80868B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
