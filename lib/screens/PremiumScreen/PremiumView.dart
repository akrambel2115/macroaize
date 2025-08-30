import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumController.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PremiumView extends GetView<PremiumController> {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Increased header height multiplier so the "Go Premium" wrapper is taller
    final headerHeight = media.size.height * 0.55;
    final overlap = headerHeight * 0.18;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColor.darkBackground,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColor.darkBackground,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              _PremiumHeader(height: headerHeight),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: headerHeight - overlap),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Features
                          _FeatureRow(
                            iconWidget: Lottie.asset(
                              'assets/lottie/scan.json',
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                            title: 'feature_ai_scan_title'.tr,
                            subtitle: 'feature_ai_scan_subtitle'.tr,
                            color: AppColor.info,
                          ),
                          const SizedBox(height: 16),
                          _FeatureRow(
                            iconWidget: Lottie.asset(
                              'assets/lottie/chatbot.json',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                            title: 'feature_chatbot_title'.tr,
                            subtitle: 'feature_chatbot_subtitle'.tr,
                            color: AppColor.warning,
                          ),
                          const SizedBox(height: 16),
                          _FeatureRow(
                            iconWidget: Lottie.asset(
                              'assets/lottie/recipes.json',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                            title: 'feature_recipes_title'.tr,
                            subtitle: 'feature_recipes_subtitle'.tr,
                            color: AppColor.accent,
                          ),

                          const SizedBox(height: 24),

                          // Plans
                          GetBuilder<PremiumController>(
                            id: 'plan_selection', // Add specific ID for this builder
                            builder: (c) {
                              final products = c.products;

                              int indexOfKeyword(List<String> kws) {
                                final lowerKws =
                                    kws.map((e) => e.toLowerCase()).toList();
                                int idx = products.indexWhere((p) {
                                  final id = p.id.toLowerCase();
                                  final title = p.title.toLowerCase();
                                  return lowerKws.any(
                                    (k) => id.contains(k) || title.contains(k),
                                  );
                                });
                                return idx;
                              }

                              int yearlyIndex = indexOfKeyword([
                                'year',
                                'annual',
                              ]);
                              int monthlyIndex = indexOfKeyword(['month']);

                              // Graceful fallbacks if not found
                              if (yearlyIndex < 0 && products.isNotEmpty) {
                                yearlyIndex = products.length - 1; // often last
                              }
                              if (monthlyIndex < 0 && products.length > 1) {
                                monthlyIndex = 0; // often first
                              }

                              final hasData =
                                  products.isNotEmpty &&
                                  (monthlyIndex >= 0 || yearlyIndex >= 0);

                              // Read prices from env with sensible defaults
                              final monthlyRaw =
                                  int.tryParse(
                                    dotenv.env['PREMIUM_MONTHLY_PRICE_DZD'] ??
                                        '',
                                  ) ??
                                  350;
                              final yearlyRaw =
                                  int.tryParse(
                                    dotenv.env['PREMIUM_YEARLY_PRICE_DZD'] ??
                                        '',
                                  ) ??
                                  3500;

                              final originalYearlyRaw = monthlyRaw * 12;
                              final savePercent =
                                  originalYearlyRaw > 0
                                      ? (((originalYearlyRaw - yearlyRaw) /
                                                  originalYearlyRaw) *
                                              100)
                                          .round()
                                      : 0;
                              final perMonthFromYearly = (yearlyRaw / 12)
                                  .toStringAsFixed(0);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (hasData) ...[
                                    GetBuilder<PremiumController>(
                                      builder: (controller) {
                                        final basePrice =
                                            '${yearlyRaw.toString()} DZD';
                                        final discountedPrice = controller
                                            .getDiscountedPrice(basePrice);

                                        return _PlanCard(
                                          title: 'months_12'.tr,
                                          subtitle: 'billed_annually'.tr,
                                          originalPrice:
                                              controller.isPromoValid
                                                  ? basePrice // Show original price when promo applied
                                                  : '${originalYearlyRaw.toString()} DZD',
                                          discountedPrice: discountedPrice,
                                          perMonthText: 'per_month'.tr,
                                          chipText: 'best_value'.tr,
                                          saveText: 'save_percent'.trParams({
                                            'percent': savePercent.toString(),
                                          }),
                                          monthlyBreakdownText:
                                              '≈ $perMonthFromYearly DZD',
                                          isSelected:
                                              yearlyIndex >= 0 &&
                                              c.selected == yearlyIndex,
                                          highlighted: true,
                                          onTap: () {
                                            if (yearlyIndex >= 0) {
                                              c.onChangeSelectedIndex(
                                                yearlyIndex,
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    GetBuilder<PremiumController>(
                                      builder: (controller) {
                                        final basePrice =
                                            '${monthlyRaw.toString()} DZD';
                                        final discountedPrice = controller
                                            .getDiscountedPrice(basePrice);

                                        return _PlanCard(
                                          title: 'month_1'.tr,
                                          subtitle: 'billed_monthly'.tr,
                                          priceText: discountedPrice,
                                          perMonthText: 'per_month'.tr,
                                          isSelected:
                                              monthlyIndex >= 0 &&
                                              c.selected == monthlyIndex,
                                          highlighted: false,
                                          onTap: () {
                                            if (monthlyIndex >= 0) {
                                              c.onChangeSelectedIndex(
                                                monthlyIndex,
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    // Loading/placeholder cards - show 12-month as selected by default
                                    _PlanCard(
                                      title: 'months_12'.tr,
                                      subtitle: 'billed_annually'.tr,
                                      originalPrice:
                                          '${originalYearlyRaw.toString()} DZD',
                                      discountedPrice:
                                          '${yearlyRaw.toString()} DZD',
                                      perMonthText: 'per_month'.tr,
                                      chipText: 'best_value'.tr,
                                      saveText: 'save_percent'.trParams({
                                        'percent': savePercent.toString(),
                                      }),
                                      monthlyBreakdownText:
                                          '≈ $perMonthFromYearly DZD',
                                      // Show as selected in placeholder state (c.selected defaults to 0)
                                      isSelected:
                                          c.selected ==
                                          0, // Assume yearly is at index 0 in placeholder
                                      highlighted: true,
                                      onTap: () {
                                        // Set to index 0 for yearly in placeholder
                                        c.onChangeSelectedIndex(0);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _PlanCard(
                                      title: 'month_1'.tr,
                                      subtitle: 'billed_monthly'.tr,
                                      priceText: '${monthlyRaw.toString()} DZD',
                                      perMonthText: 'per_month'.tr,
                                      isSelected:
                                          c.selected ==
                                          1, // Assume monthly is at index 1 in placeholder
                                      highlighted: false,
                                      onTap: () {
                                        // Set to index 1 for monthly in placeholder
                                        c.onChangeSelectedIndex(1);
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // Continue CTA or status if already premium
                          GetBuilder<PremiumController>(
                            builder: (c) {
                              if (c.isPremium) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'You are already Premium',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 12),
                                    // Removed Manage button
                                  ],
                                );
                              }
                              return ModernButton(
                                text: 'continue_cta'.tr,
                                style: ModernButtonStyle.gradient,
                                size: ModernButtonSize.large,
                                width: double.infinity,
                                onPressed: () => controller.buy(),
                              );
                            },
                          ),

                          const SizedBox(height: 16),
                          // Legal links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => controller.openPrivacy(),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                    'Privacy Policy'.tr,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColor.neutralGrey600,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12,
                                        ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 12,
                                color: AppColor.neutralGrey300,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              InkWell(
                                onTap: () => controller.openTerms(),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Text(
                                    'Terms of Condition'.tr,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColor.neutralGrey600,
                                          decoration: TextDecoration.underline,
                                          fontSize: 12,
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
              // Top-level close button positioned above the header/scroll content so taps are reliable
              Positioned(
                top: 12,
                right: 12,
                child: Semantics(
                  label: 'close',
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Get.back(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Header with dark background, decorative circles and close button
class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColor.darkBackground, AppColor.darkSurface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative images (replacing previous blur circles)
          Positioned(
            top: 40,
            left: 14,
            child: Semantics(
              label: 'cook icon',
              image: true,
              child: SizedBox(
                width: 96,
                height: 96,
                child: Opacity(
                  opacity: 0.55,
                  child: Lottie.asset(
                    'assets/lottie/recipes.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Semantics(
              label: 'scan icon',
              image: true,
              child: SizedBox(
                width: 100,
                height: 100,
                child: Opacity(
                  opacity: 0.55,
                  child: Lottie.asset(
                    'assets/lottie/scan.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 64,
            left: 40,
            child: Semantics(
              label: 'chatbot icon',
              image: true,
              child: SizedBox(
                width: 140,
                height: 140,
                child: Opacity(
                  opacity: 0.55,
                  child: Lottie.asset(
                    'assets/lottie/chatbot.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),
          // Symmetric decorative icon to the chatbot on the bottom-right
          Positioned(
            bottom: 40,
            right: 20,
            child: Semantics(
              label: 'dahabia icon',
              image: true,
              child: _AnimatedDahabia(width: 180, height: 180, opacity: 0.55),
            ),
          ),

          // Close button removed from header to keep it above scroll content in parent Stack.

          // Center content
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColor.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'premium_badge'.tr,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'go_premium_title'.tr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColor.darkText,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'go_premium_subtitle'.tr,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColor.darkTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... decorative blur helper removed; images are used instead
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : assert(
         icon != null || iconWidget != null,
         'Either icon or iconWidget must be provided',
       );

  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(child: iconWidget ?? Icon(icon, color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColor.neutralWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColor.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    this.priceText = '',
    required this.perMonthText,
    required this.isSelected,
    required this.onTap,
    this.chipText,
    this.saveText,
    this.highlighted = false,
    this.originalPrice,
    this.discountedPrice,
    this.monthlyBreakdownText,
  });

  final String title;
  final String subtitle;
  final String priceText;
  final String perMonthText;
  final bool isSelected;
  final bool highlighted;
  final VoidCallback onTap;
  final String? chipText;
  final String? saveText;
  final String? originalPrice;
  final String? discountedPrice;
  final String? monthlyBreakdownText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      // Announce selection state for accessibility
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(
              0xFF1C1C1E,
            ), // Dark card background to match reference
            borderRadius: BorderRadius.circular(12),
            // Orange outline only when the card is selected
            border:
                isSelected
                    ? Border.all(color: AppColor.primaryOrange, width: 2)
                    : Border.all(color: const Color(0xFF2C2C2E), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title and chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (chipText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chipText!,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Price section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side: prices
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // For annual plan, prefer explicit originalPrice/discountedPrice fields
                        if (highlighted &&
                            originalPrice != null &&
                            discountedPrice != null) ...[
                          Text(
                            originalPrice!, // Original price crossed out
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            discountedPrice!, // Discounted price
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ] else ...[
                          // For monthly plan, just show the priceText
                          Text(
                            priceText,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side: per month info (only show for highlighted annual plan)
                  if (highlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // For annual plan, show monthly breakdown; prefer provided text, fallback to derived
                          Text(
                            (() {
                              if (monthlyBreakdownText != null &&
                                  monthlyBreakdownText!.isNotEmpty) {
                                return monthlyBreakdownText!;
                              }
                              double? parseAmount(String s) {
                                final match = RegExp(r'[\d.,]+').stringMatch(s);
                                if (match == null) return null;
                                final cleaned = match.replaceAll(',', '');
                                return double.tryParse(cleaned);
                              }

                              if (discountedPrice != null) {
                                final d = parseAmount(discountedPrice!);
                                if (d != null && d > 0) {
                                  return '≈ ${(d / 12).round()} DZD';
                                }
                              }
                              return '';
                            })(),
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Per month',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Save strip for annual plan: show dynamic discount amount when original+discounted provided
              if ((originalPrice != null && discountedPrice != null) ||
                  saveText != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColor.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (_) {
                      // Helper to parse numeric value from strings like '4200 DZD' or '4,200.00 DZD'
                      double? parseAmount(String s) {
                        final match = RegExp(r'[\d.,]+').stringMatch(s);
                        if (match == null) return null;
                        final cleaned = match.replaceAll(',', '');
                        return double.tryParse(cleaned);
                      }

                      String display;
                      final o =
                          originalPrice != null
                              ? parseAmount(originalPrice!)
                              : null;
                      final d =
                          discountedPrice != null
                              ? parseAmount(discountedPrice!)
                              : null;
                      if (o != null && d != null && o > 0) {
                        final percent = ((o - d) / o * 100);
                        final rounded = percent.round();
                        display = 'Save $rounded%';
                      } else {
                        display = saveText ?? '';
                      }

                      return Text(
                        display,
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// A small, subtle floating + scale animation for the dahabia decorative icon so it matches the liveliness of Lottie assets.
class _AnimatedDahabia extends StatefulWidget {
  const _AnimatedDahabia({
    this.width = 140,
    this.height = 140,
    this.opacity = 1.0,
  });
  final double width;
  final double height;
  final double opacity;

  @override
  State<_AnimatedDahabia> createState() => _AnimatedDahabiaState();
}

class _AnimatedDahabiaState extends State<_AnimatedDahabia>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Gentle vertical float: -6 -> +6 px
    _translateY = Tween(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // Slight scale pulse: 0.985 -> 1.02
    _scale = Tween(
      begin: 0.985,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(widget.opacity),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Image.asset('assets/icons/dahabia.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
