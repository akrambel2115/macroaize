import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constant/AppColor.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool enableGradient;
  final Color? splashColor;
  final Color? highlightColor;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.color,
    this.borderRadius,
    this.gradient,
    this.border,
    this.boxShadow,
    this.onTap,
    this.enableGradient = false,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    final defaultBorderRadius = BorderRadius.circular(18);
    final defaultPadding = const EdgeInsets.all(16);
    final defaultMargin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    Widget cardContent = Container(
      margin: margin ?? defaultMargin,
      decoration: BoxDecoration(
        color: color ?? (enableGradient
            ? null
            : (isDark ? AppColor.darkCard : AppColor.neutralWhite)),
        gradient: enableGradient
            ? (gradient ?? (isDark ? AppColor.darkCardGradient : AppColor.cardGradient))
            : gradient,
        borderRadius: borderRadius ?? defaultBorderRadius,
        border: border ?? Border.all(
          color: isDark ? AppColor.darkBorder : AppColor.neutralGrey100.withOpacity(0.9),
          width: 0.6,
        ),
        boxShadow: boxShadow ?? _getDefaultShadow(isDark),
      ),
      child: Padding(
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? defaultBorderRadius,
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  List<BoxShadow> _getDefaultShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return [
      BoxShadow(
        color: AppColor.primaryOrange.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }
}

class ModernGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double opacity;
  final double blur;
  final VoidCallback? onTap;

  const ModernGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.opacity = 0.1,
    this.blur = 10.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final defaultBorderRadius = BorderRadius.circular(18);
    Widget glassContent = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(opacity),
        borderRadius: borderRadius ?? defaultBorderRadius,
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? defaultBorderRadius,
          child: glassContent,
        ),
      );
    }

    return glassContent;
  }
}

class ModernNutrientCard extends StatelessWidget {
  final String label;
  final String value;
  final String? goal;
  final String unit;
  final Color color;
  final double? progress;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool useCard;

  const ModernNutrientCard({
    super.key,
    required this.label,
    required this.value,
    this.goal,
    required this.unit,
    required this.color,
    this.progress,
    this.icon,
    this.leading,
    this.onTap,
    this.useCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom leading widget (image/icon) above label
          if (leading != null) ...[
            Center(child: leading!),
            const SizedBox(height: 8),
          ]
          else if (icon != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Center(
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: isDark ? AppColor.darkTextSecondary : AppColor.neutralGrey600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Value display with better typography
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                  },
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: isDark ? AppColor.darkText : AppColor.neutralGrey900,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColor.darkTextSecondary : AppColor.neutralGrey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Goal display (if provided)
          if (goal != null) ...[
            const SizedBox(height: 4),
            Text(
              'of $goal $unit',
              style: context.textTheme.labelSmall?.copyWith(
                color: isDark ? AppColor.darkTextSecondary : AppColor.neutralGrey500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          
          // Progress bar (if provided)
          if (progress != null && progress! > 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (useCard) {
      return ModernCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: content,
      );
    }

    return content;
  }
}
