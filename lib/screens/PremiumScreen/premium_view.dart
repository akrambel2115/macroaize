import 'dart:async';
import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:macroaize/screens/PremiumScreen/premium_controller.dart';
import 'package:macroaize/widgets/continue_button.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/services/app_config_service.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:macroaize/shared/services/subscription_service.dart';
import 'package:macroaize/shared/models/subscription.dart' as sub_model;
import 'package:macroaize/shared/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  final PremiumController controller = Get.find();
  bool showCloseLocal = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map?;
    final delayClose = args != null && args['delayClose'] == true;
    controller.fromOnboarding = args != null && args['fromOnboarding'] == true;
    if (delayClose) {
      showCloseLocal = false;
      _timer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => showCloseLocal = true);
      });
    }
    controller.processArgs(args);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final headerHeight = media.size.height * 0.55;
    final overlap = headerHeight * 0.18;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColor.darkBackground,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: showCloseLocal,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && showCloseLocal) {
            controller.onClosePressed();
          }
        },
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
                            // features
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

                            // plans
                            GetBuilder<PremiumController>(
                              builder: (c) {
                                if (c.isLoading) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: CircularProgressIndicator(
                                        color: AppColor.primaryOrange,
                                      ),
                                    ),
                                  );
                                }

                                if (c.errorMessage != null) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            c.errorMessage!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: c.fetchOfferings,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColor.primaryOrange,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                final packages =
                                    c.offerings?.current?.availablePackages ??
                                    [];
                                final sortedPackages = List<Package>.from(
                                  packages,
                                )..sort((a, b) {
                                  if (a.packageType == PackageType.annual &&
                                      b.packageType != PackageType.annual) {
                                    return -1;
                                  }
                                  if (a.packageType != PackageType.annual &&
                                      b.packageType == PackageType.annual) {
                                    return 1;
                                  }
                                  return 0;
                                });
                                if (sortedPackages.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No offers available',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                double? getMonthlyPrice(List<Package> pkgs) {
                                  final monthly = pkgs.firstWhereOrNull(
                                    (p) => p.packageType == PackageType.monthly,
                                  );
                                  return monthly?.storeProduct.price;
                                }

                                final monthlyPrice = getMonthlyPrice(packages);

                                int getSortedSelectedIndex() {
                                  final selectedPkg =
                                      c.selected < packages.length
                                          ? packages[c.selected]
                                          : null;
                                  if (selectedPkg != null) {
                                    final idx = sortedPackages.indexOf(
                                      selectedPkg,
                                    );
                                    if (idx >= 0) return idx;
                                  }
                                  return sortedPackages.indexWhere(
                                    (p) => p.packageType == PackageType.annual,
                                  );
                                }

                                final sortedSelectedIndex =
                                    getSortedSelectedIndex();
                                if (sortedSelectedIndex >= 0 &&
                                    c.selected >= packages.length) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    final originalIdx = packages.indexOf(
                                      sortedPackages[sortedSelectedIndex],
                                    );
                                    if (originalIdx >= 0) {
                                      c.onChangeSelectedIndex(originalIdx);
                                    }
                                  });
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children:
                                      sortedPackages.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final package = entry.value;
                                        final product = package.storeProduct;
                                        final isAnnual =
                                            package.packageType ==
                                            PackageType.annual;
                                        final isMonthly =
                                            package.packageType ==
                                            PackageType.monthly;

                                        String? trialText;
                                        if ((product.introductoryPrice !=
                                                    null &&
                                                product
                                                        .introductoryPrice!
                                                        .price ==
                                                    0) ||
                                            product.price == 0) {
                                          if (product.introductoryPrice !=
                                              null) {
                                            final intro =
                                                product.introductoryPrice!;
                                            final count =
                                                intro.periodNumberOfUnits;
                                            final unit = intro.periodUnit;

                                            String unitText = '';
                                            switch (unit) {
                                              case PeriodUnit.day:
                                                unitText =
                                                    count == 1 ? 'Day' : 'Days';
                                                break;
                                              case PeriodUnit.week:
                                                unitText =
                                                    count == 1
                                                        ? 'Week'
                                                        : 'Weeks';
                                                break;
                                              case PeriodUnit.month:
                                                unitText =
                                                    count == 1
                                                        ? 'Month'
                                                        : 'Months';
                                                break;
                                              case PeriodUnit.year:
                                                unitText =
                                                    count == 1
                                                        ? 'Year'
                                                        : 'Years';
                                                break;
                                              case PeriodUnit.unknown:
                                                unitText = 'Days';
                                                break;
                                            }
                                            trialText = '$count $unitText Free';
                                          } else {
                                            trialText = 'Free';
                                          }
                                        }

                                        String? saveText;
                                        String? monthlyBreakdown;
                                        String? originalPriceFormatted;

                                        String getSymbol(String priceString) {
                                          return priceString.replaceAll(
                                            RegExp(r'[0-9.,\s]'),
                                            '',
                                          );
                                        }

                                        final symbol = getSymbol(
                                          product.priceString,
                                        );

                                        if (isAnnual && monthlyPrice != null) {
                                          final yearlyPrice = product.price;
                                          final yearlyMonthlyPrice =
                                              yearlyPrice / 12;
                                          final savings =
                                              (monthlyPrice * 12) - yearlyPrice;
                                          final savingsPercent =
                                              (savings / (monthlyPrice * 12)) *
                                              100;

                                          if (savingsPercent > 0) {
                                            saveText =
                                                'Save ${savingsPercent.round()}%';
                                            originalPriceFormatted =
                                                '$symbol${(monthlyPrice * 12).toStringAsFixed(2)}';
                                          }
                                          monthlyBreakdown =
                                              '$symbol${yearlyMonthlyPrice.toStringAsFixed(2)}';
                                        }

                                        // Compute bonus days badge text if eligible
                                        String? bonusDaysText;
                                        if (c.promoEligible) {
                                          if (isAnnual) {
                                            bonusDaysText = 'bonus_1_month'.tr;
                                          } else if (isMonthly) {
                                            bonusDaysText = 'bonus_3_days'.tr;
                                          }
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _PlanCard(
                                            title:
                                                isAnnual
                                                    ? 'months_12'.tr
                                                    : (isMonthly
                                                        ? 'month_1'.tr
                                                        : product.title),
                                            subtitle:
                                                isAnnual
                                                    ? 'billed_annually'.tr
                                                    : (isMonthly
                                                        ? 'billed_monthly'.tr
                                                        : product.description),
                                            priceText: product.priceString,
                                            perMonthText: 'per_month'.tr,
                                            isSelected:
                                                sortedSelectedIndex == index,
                                            highlighted: isAnnual,
                                            chipText:
                                                isAnnual
                                                    ? 'best_value'.tr
                                                    : null,
                                            saveText: saveText,
                                            originalPrice:
                                                originalPriceFormatted,
                                            discountedPrice: null,
                                            monthlyBreakdownText:
                                                monthlyBreakdown,
                                            freeTrialText: trialText,
                                            bonusDaysText: bonusDaysText,
                                            onTap: () {
                                              final originalIndex = packages
                                                  .indexOf(package);
                                              c.onChangeSelectedIndex(
                                                originalIndex,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // cta button
                            GetBuilder<PremiumController>(
                              builder: (c) {
                                if (c.isPremium) {
                                  final cfg = Get.find<AppConfigService>();
                                  final rcEnabled =
                                      cfg.subscriptionsEnabled &&
                                      (Platform.isAndroid || Platform.isIOS);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'already_premium'.tr,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                      const SizedBox(height: 12),
                                      if (rcEnabled)
                                        StreamBuilder<sub_model.Subscription?>(
                                          stream:
                                              SubscriptionService()
                                                  .subscriptionStream,
                                          builder: (context, snap) {
                                            final sub = snap.data;
                                            final provider =
                                                (sub?.provider ?? '')
                                                    .toLowerCase();
                                            if (provider != 'revenuecat') {
                                              return const SizedBox.shrink();
                                            }
                                            final storeName =
                                                Platform.isIOS
                                                    ? 'App Store'
                                                    : 'Google Play';
                                            final url =
                                                Platform.isIOS
                                                    ? 'https://apps.apple.com/account/subscriptions'
                                                    : 'https://play.google.com/store/account/subscriptions';
                                            return Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () async {
                                                    final uri = Uri.parse(url);
                                                    if (await canLaunchUrl(
                                                      uri,
                                                    )) {
                                                      await launchUrl(
                                                        uri,
                                                        mode:
                                                            LaunchMode
                                                                .externalApplication,
                                                      );
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.manage_accounts,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'manage_on_store'.trParams({
                                                      'store': storeName,
                                                    }),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        side: const BorderSide(
                                                          color: Colors.white24,
                                                        ),
                                                      ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () async {
                                                    await controller
                                                        .restorePurchases();
                                                  },
                                                  icon: Icon(
                                                    Icons.restore,
                                                    color:
                                                        AppColor.neutralGrey600,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    'restore_purchases'.tr,
                                                    style: TextStyle(
                                                      color:
                                                          AppColor
                                                              .neutralGrey600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        side: BorderSide(
                                                          color: AppColor
                                                              .neutralGrey600
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                        textStyle:
                                                            const TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'restore_purchases_info'
                                                              .tr,
                                                        ),
                                                        backgroundColor:
                                                            AppColor
                                                                .neutralGrey600,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        duration:
                                                            const Duration(
                                                              seconds: 3,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    child: Icon(
                                                      Icons.info_outline,
                                                      size: 18,
                                                      color:
                                                          AppColor
                                                              .neutralGrey600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                }
                                final cfg = Get.find<AppConfigService>();
                                final rcEnabled = cfg.subscriptionsEnabled;

                                final packages =
                                    c.offerings?.current?.availablePackages ??
                                    [];
                                bool hasTrial = false;
                                if (packages.isNotEmpty &&
                                    c.selected < packages.length) {
                                  final p = packages[c.selected];
                                  hasTrial =
                                      (p.storeProduct.introductoryPrice !=
                                              null &&
                                          p
                                                  .storeProduct
                                                  .introductoryPrice!
                                                  .price ==
                                              0) ||
                                      p.storeProduct.price == 0;
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ContinueButton(
                                      onTap: () => controller.buy(),
                                      text:
                                          hasTrial
                                              ? 'continue_for_free'.tr
                                              : 'continue'.tr,
                                      icon: null,
                                    ),
                                    if (rcEnabled &&
                                        (Platform.isAndroid ||
                                            Platform.isIOS)) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    controller
                                                        .restorePurchases(),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColor.neutralGrey600,
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            child: Text(
                                              'restore_purchases'.tr,
                                              style: TextStyle(
                                                color: AppColor.neutralGrey600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'restore_purchases_info'.tr,
                                                  ),
                                                  backgroundColor:
                                                      AppColor.neutralGrey600,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 4,
                                              ),
                                              child: Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: AppColor.neutralGrey600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (Platform.isIOS) ...[
                                        const SizedBox(height: 4),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  RevenueCatService()
                                                      .presentCodeRedemptionSheet(),
                                          child: Text('redeem_code'.tr),
                                        ),
                                      ],
                                    ],
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            // legal links
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
                                            decoration:
                                                TextDecoration.underline,
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
                                            decoration:
                                                TextDecoration.underline,
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
                if (showCloseLocal)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Semantics(
                      label: 'close',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: controller.onClosePressed,
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
      ),
    );
  }
}

// premium header
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative icons
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
          Positioned(
            bottom: 40,
            right: 20,
            child: Semantics(
              label: 'dahabia icon',
              image: true,
              child: _AnimatedDahabia(width: 180, height: 180, opacity: 0.55),
            ),
          ),

          // center content
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
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3)),
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
    this.freeTrialText,
    this.bonusDaysText,
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
  final String? freeTrialText;
  final String? bonusDaysText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient:
                highlighted
                    ? LinearGradient(
                      colors: [
                        const Color(0xFF2A2520),
                        const Color(0xFF1C1C1E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: highlighted ? null : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: AppColor.primaryOrange, width: 2)
                    : Border.all(color: const Color(0xFF2C2C2E), width: 1),
            boxShadow:
                (isSelected && highlighted)
                    ? [
                      BoxShadow(
                        color: AppColor.primaryOrange.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppColor.primaryOrange.withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title row
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
                  Row(
                    children: [
                      if (bonusDaysText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF9500,
                                ).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bonusDaysText!,
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (freeTrialText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            freeTrialText!.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
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
                ],
              ),

              const SizedBox(height: 16),

              // price section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // prices
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (highlighted &&
                            originalPrice != null &&
                            discountedPrice != null) ...[
                          Text(
                            originalPrice!,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            discountedPrice!,
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                            ),
                          ),
                        ] else ...[
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
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // per month info
                  if (highlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                            'per_month_label'.tr,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // save badge
              if ((originalPrice != null && discountedPrice != null) ||
                  saveText != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (_) {
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
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
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

// animated dahabia icon
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

    _translateY = Tween(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

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
