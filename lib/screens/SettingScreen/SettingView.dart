import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodcalorietracker/MainController.dart';
import 'package:foodcalorietracker/SharePrefHelper/ConstantUserMaster.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/constant/DatabaseHelper.dart';
import 'package:foodcalorietracker/routes/app_pages.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingController.dart';
import 'package:foodcalorietracker/widgets/ModernAnimations.dart';
import 'package:foodcalorietracker/widgets/ModernButton.dart';
import 'package:foodcalorietracker/widgets/ModernCard.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:foodcalorietracker/shared/services/subscription_service.dart';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'package:foodcalorietracker/shared/models/user_usage.dart';
import 'package:foodcalorietracker/shared/services/influencer_service.dart';
import 'package:foodcalorietracker/shared/models/influencer.dart';
import 'subscription_status_card.dart';
import '../../ThemeService/ThemeController.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import 'package:intl/intl.dart';

// Configuration class for easy maintenance and updates
class SettingConfig {
  // App version - update this when releasing new versions
  static const String appVersion = "1.0.0";

  // Customization menu items - easily add/remove/modify settings
  static const List<Map<String, dynamic>> customizationItems = [
    {
      'title': 'Personal details',
      'icon': Icons.person_outline,
      'color': AppColor.primaryOrange,
      'route': Routes.personalDetailsView,
    },
    {
      'title': 'Adjust goals',
      'subtitleKey': 'adjust_goals_subtitle',
      'icon': Icons.track_changes_outlined,
      'color': AppColor.accent,
      'route': Routes.adjustGoalsView,
    },
    {
      'title': 'Chat history',
      'icon': Icons.chat_bubble_outline,
      'color': AppColor.secondary,
      'route': Routes.chatHistoryView,
    },
  ];

  // Legal menu items - centralized for easy maintenance
  static const List<Map<String, dynamic>> legalItems = [
    {
      'title': 'Terms and Condition',
      'icon': Icons.description_outlined,
      'action': 'privacy',
    },
    {
      'title': 'Privacy Policy',
      'icon': Icons.privacy_tip_outlined,
      'action': 'terms',
    },
  ];
}

/// Modern Settings View with clean architecture and maintainable code structure
///
/// Features:
/// - Configuration-driven menu items for easy maintenance
/// - Modern UI with consistent design system
/// - Organized sections: Profile, Customization, Legal, App Info
/// - Responsive design with smooth animations
/// - Easy to extend and modify through SettingConfig class
class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  // Create a single instance to avoid recreating service on every build
  static final _subscriptionService = SubscriptionService();
  static final _influencerService = InfluencerService();

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SettingController());
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium card or status
            // Premium card / Subscription status
            _buildPremiumSection(context),

            const SizedBox(height: 16),

            // Daily usage section (conditionally rendered for non-premium users only)
            StreamBuilder<Subscription?>(
              stream: _subscriptionService.subscriptionStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final sub = snap.data;
                if (sub?.isActive == true) return const SizedBox.shrink();
                return Column(
                  children: [
                    _buildDailyUsageSection(context),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Influencer section (only show if user is an influencer)
            _buildInfluencerSection(context),

            // Profile section
            _buildProfileSection(context),

            const SizedBox(height: 24),

            // Customization section
            _buildCustomizationSection(context),

            const SizedBox(height: 24),

            // Legal section
            _buildLegalSection(context),

            const SizedBox(height: 24),

            // App info and reset
            _buildAppInfoSection(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyUsageSection(BuildContext context) {
    final subscriptionService = _subscriptionService;
    final usageService = UsageService();

    return StreamBuilder<Subscription?>(
      stream: subscriptionService.subscriptionStream,
      builder: (context, subscriptionSnapshot) {
        // Hide only while loading; once we have a value, show for non-premium
        if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final subscription = subscriptionSnapshot.data;
        if (subscription?.isActive == true) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Daily Usage'.tr, Icons.info_outline),
            const SizedBox(height: 12),
            ModernFadeSlideTransition(
              beginOffset: const Offset(0, 0.2),
              child: ModernCard(
                child: Column(
                  children: [
                    // Show login prompt when user is not authenticated
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, authSnap) {
                        final user = authSnap.data;
                        if (user == null) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await AuthModal.show();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColor.primaryOrange.withOpacity(
                                    0.04,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryOrange
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.login,
                                        color: AppColor.primaryOrange,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'login_to_view_usage'.tr,
                                        style: context.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: AppColor.primaryOrange,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppColor.primaryOrange,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Usage values
                    StreamBuilder<UserUsage?>(
                      stream: usageService.usageStream,
                      builder: (context, usageSnapshot) {
                        final usage =
                            usageSnapshot.data ??
                            const UserUsage(scanCount: 0, chatCount: 0);
                        final remainingScans = (usage.scanLimit -
                                usage.scanCount)
                            .clamp(0, usage.scanLimit);
                        final remainingChats = (usage.chatLimit -
                                usage.chatCount)
                            .clamp(0, usage.chatLimit);

                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildProfileInfoRow(
                              context,
                              'Scans'.tr,
                              '$remainingScans ${'left'.tr}',
                              Icons.photo_camera_outlined,
                              AppColor.primaryGreen,
                            ),
                            const SizedBox(height: 16),
                            _buildProfileInfoRow(
                              context,
                              'Chat'.tr,
                              '$remainingChats ${'left'.tr}',
                              Icons.chat_bubble_outline,
                              AppColor.accent,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPremiumSection(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // If not authenticated, show Go Premium card
        if (authSnapshot.data == null) {
          return _buildPremiumCard(context);
        }

        // If authenticated, listen to subscription
        return StreamBuilder<Subscription?>(
          stream: _subscriptionService.subscriptionStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final sub = snapshot.data;

            if (sub != null && sub.isActive) {
              return ModernFadeSlideTransition(
                child: SubscriptionStatusCard(subscription: sub),
              );
            }
            // Fallback to Go Premium card
            return _buildPremiumCard(context);
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      title: Text(
        "Setting".tr,
        style: context.theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [],
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    return ModernFadeSlideTransition(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor.accentOrange, AppColor.accentOrangeLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColor.accentOrange.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.toNamed(Routes.premiumView),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      AppAssets.crownIcon,
                      height: 32,
                      width: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'go_premium_title'.tr,
                          style: context.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'go_premium_subtitle'.tr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Profile".tr, Icons.person_outline),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.2),
          child: ModernCard(
            // Make the entire profile card tappable and navigate to Personal Details
            onTap: () => Get.toNamed(Routes.personalDetailsView),
            child: Column(
              children: [
                _buildProfileInfoRow(
                  context,
                  "Age".tr,
                  "${ConstantUserMaster.age}",
                  Icons.cake_outlined,
                  AppColor.primaryOrange,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  "Height".tr,
                  "${ConstantUserMaster.height} ${'cm'.tr}",
                  Icons.height,
                  AppColor.secondary,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  "Current Weight".tr,
                  "${ConstantUserMaster.weight} ${'kg'.tr}",
                  Icons.monitor_weight_outlined,
                  AppColor.accent,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        _buildSectionHeader(
          context,
          'Account'.tr,
          Icons.manage_accounts_outlined,
        ),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.25),
          child: ModernCard(
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isLoggedIn = user != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoggedIn)
                      _buildSettingRow(
                        context,
                        user.displayName?.trim().isNotEmpty == true
                            ? user.displayName!.trim()
                            : (user.email ?? 'Account'),
                        'Tap to view details',
                        Icons.person_outline,
                        AppColor.primaryOrange,
                        onTap: () => Get.toNamed(Routes.accountDetailsView),
                      )
                    else
                      _buildSettingRow(
                        context,
                        'Register / Login',
                        'Access your account and sync data',
                        Icons.login,
                        AppColor.secondary,
                        onTap: () async {
                          final ok = await AuthModal.show();
                          if (ok) {
                            // no-op; StreamBuilder will update
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Customization".tr, Icons.tune),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.3),
          child: ModernCard(
            child: Column(
              children: [
                _buildSettingRow(
                  context,
                  "Dark Mode".tr,
                  null,
                  Icons.dark_mode_outlined,
                  AppColor.neutralGrey700,
                  trailing: CupertinoSwitch(
                    value: Get.find<ThemeController>().isDarkMode,
                    activeTrackColor: AppColor.primaryOrange,
                    onChanged: (value) async {
                      await Get.find<ThemeController>().toggleTheme(value);
                    },
                  ),
                ),
                Divider(
                  height: 24,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutralGrey700
                          : AppColor.neutralGrey200,
                ),
                _buildSettingRow(
                  context,
                  "Language".tr,
                  Get.find<MainController>().languageKey.tr,
                  Icons.language_outlined,
                  AppColor.tertiary,
                  onTap: () => Get.toNamed(Routes.languageView),
                ),
                Divider(
                  height: 24,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutralGrey700
                          : AppColor.neutralGrey200,
                ),
                // Dynamic customization items from config
                ...SettingConfig.customizationItems.asMap().entries.map((
                  entry,
                ) {
                  final item = entry.value;
                  final isLast =
                      entry.key == SettingConfig.customizationItems.length - 1;

                  return Column(
                    children: [
                      _buildSettingRow(
                        context,
                        item['title'].toString().tr,
                        item.containsKey('subtitleKey')
                            ? item['subtitleKey'].toString().tr
                            : null,
                        item['icon'] as IconData,
                        item['color'] as Color,
                        onTap: () => Get.toNamed(item['route'] as String),
                      ),
                      if (!isLast)
                        Divider(
                          height: 24,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColor.neutralGrey700
                                  : AppColor.neutralGrey200,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Legal".tr, Icons.gavel_outlined),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.4),
          child: ModernCard(
            child: Column(
              children:
                  SettingConfig.legalItems.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast =
                        entry.key == SettingConfig.legalItems.length - 1;

                    return Column(
                      children: [
                        _buildSettingRow(
                          context,
                          item['title'].toString().tr,
                          null,
                          item['icon'] as IconData,
                          AppColor.neutralGrey600,
                          onTap:
                              () =>
                                  _handleLegalAction(item['action'] as String),
                        ),
                        if (!isLast)
                          Divider(
                            height: 24,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColor.neutralGrey700
                                    : AppColor.neutralGrey200,
                          ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "App Info".tr, Icons.info_outline),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.5),
          child: ModernCard(
            child: Column(
              children: [
                _buildSettingRow(
                  context,
                  "Version".tr,
                  SettingConfig.appVersion,
                  Icons.code_outlined,
                  AppColor.neutralGrey600,
                ),
                Divider(
                  height: 24,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutralGrey700
                          : AppColor.neutralGrey200,
                ),
                _buildSettingRow(
                  context,
                  "Reset Data".tr,
                  "Clear all app data",
                  Icons.delete_outline,
                  AppColor.error,
                  onTap: () => showDeleteDialog(context),
                  textColor: AppColor.error,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColor.primaryOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String title,
    String? subtitle,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        // Use a light gray overlay on press in light mode to avoid black highlight
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          if (isLight) return AppColor.neutralGrey100.withOpacity(0.5);
          return AppColor.neutralGrey800.withOpacity(0.12);
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColor.neutralGrey600,
                          fontSize:
                              12.0, // reduced size for subtitle/description
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColor.neutralGrey400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLegalAction(String action) {
    switch (action) {
      case 'privacy':
        controller.openPrivacy();
        break;
      case 'terms':
        controller.openTerms();
        break;
    }
  }

  void showDeleteDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColor.mediumShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  color: AppColor.error,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                "Confirm Reset".tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Content
              Text(
                "Are you sure you want to Reset Data?".tr,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: AppColor.neutralGrey600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: "Cancel".tr,
                      style: ModernButtonStyle.outline,
                      size: ModernButtonSize.medium,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(
                      text: "Reset".tr,
                      style: ModernButtonStyle.primary,
                      size: ModernButtonSize.medium,
                      onPressed: () async {
                        Get.back();
                        await logoutUser();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfluencerSection(BuildContext context) {
    bool promoCopied = false;
    return StreamBuilder<Influencer?>(
      stream: _influencerService.influencerStream,
      builder: (context, snapshot) {
        // Only show section if user is an influencer
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final influencer = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'influencer_program'.tr,
              Icons.campaign,
            ),
            const SizedBox(height: 12),
            ModernFadeSlideTransition(
              beginOffset: const Offset(0, 0.2),
              child: ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Promo code row
                    // Promo code block
                    StatefulBuilder(
                      builder: (context, setState) {
                        // Width is handled via IntrinsicWidth with an invisible baseline text
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSettingRow(
                              context,
                              'your_promo_code'.tr,
                              null,
                              Icons.local_offer,
                              AppColor.primaryOrange,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      _copyPromoCode(influencer.promoCode);
                                      setState(() => promoCopied = true);
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        () =>
                                            setState(() => promoCopied = false),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryOrange
                                            .withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColor.primaryOrange
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: IntrinsicWidth(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Opacity(
                                              opacity: 0,
                                              child: Text(
                                                influencer.promoCode,
                                                style: context
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color:
                                                          AppColor
                                                              .primaryOrange,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 1.2,
                                                    ),
                                              ),
                                            ),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              transitionBuilder:
                                                  (child, anim) =>
                                                      FadeTransition(
                                                        opacity: anim,
                                                        child: ScaleTransition(
                                                          scale: anim,
                                                          child: child,
                                                        ),
                                                      ),
                                              child:
                                                  promoCopied
                                                      ? Text(
                                                        'copied'.tr,
                                                        key: const ValueKey(
                                                          'copied',
                                                        ),
                                                        style: context
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              color:
                                                                  AppColor
                                                                      .primaryOrange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                      )
                                                      : Text(
                                                        influencer.promoCode,
                                                        key: const ValueKey(
                                                          'code',
                                                        ),
                                                        style: context
                                                            .textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                              color:
                                                                  AppColor
                                                                      .primaryOrange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(
                      height: 24,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColor.neutralGrey700
                              : AppColor.neutralGrey200,
                    ),

                    // Current balance
                    _buildProfileInfoRow(
                      context,
                      'current_balance'.tr,
                      '${influencer.earningsDzd.toStringAsFixed(0)} DZD',
                      Icons.account_balance_wallet,
                      AppColor.success,
                    ),
                    Divider(
                      height: 24,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColor.neutralGrey700
                              : AppColor.neutralGrey200,
                    ),

                    // Total earned
                    _buildProfileInfoRow(
                      context,
                      'total_earned'.tr,
                      '${influencer.totalEarningsDzd.toStringAsFixed(0)} DZD',
                      Icons.trending_up,
                      AppColor.info,
                    ),
                    Divider(
                      height: 24,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColor.neutralGrey700
                              : AppColor.neutralGrey200,
                    ),

                    // Referrals count
                    _buildProfileInfoRow(
                      context,
                      'referrals_count'.tr,
                      influencer.usersCount.toString(),
                      Icons.people,
                      AppColor.warning,
                    ),
                    Divider(
                      height: 24,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColor.neutralGrey700
                              : AppColor.neutralGrey200,
                    ),

                    // Withdrawal action row
                    _buildSettingRow(
                      context,
                      'request_withdrawal'.tr,
                      influencer.canWithdraw
                          ? null
                          : 'minimum_withdrawal_amount'.trParams({
                            'amount': influencer.minWithdrawal.toStringAsFixed(
                              0,
                            ),
                          }),
                      Icons.account_balance,
                      influencer.canWithdraw
                          ? AppColor.primaryOrange
                          : AppColor.neutralGrey600,
                      onTap:
                          influencer.canWithdraw
                              ? () => _showWithdrawalDialog(context, influencer)
                              : null,
                    ),

                    // Expiration info if applicable
                    if (influencer.expirationDate != null) ...[
                      const SizedBox(height: 16),
                      _buildExpirationInfo(context, influencer),
                    ],

                    // Withdrawal history (last 3)
                    if (influencer.withdrawHistory.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'withdrawal_history'.tr,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...influencer.withdrawHistory
                          .take(3)
                          .map((w) => _buildWithdrawalHistoryItem(context, w)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // Removed old Influencer-specific section builders in favor of unified Setting rows

  Widget _buildWithdrawalHistoryItem(
    BuildContext context,
    WithdrawalRecord withdrawal,
  ) {
    Color statusColor;
    switch (withdrawal.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColor.success;
        break;
      case 'processing':
        statusColor = AppColor.warning;
        break;
      case 'failed':
        statusColor = AppColor.error;
        break;
      default:
        statusColor = AppColor.neutralGrey600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.neutralGrey200, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${withdrawal.amount.toStringAsFixed(0)} DZD',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  withdrawal.requestedAt != null
                      ? 'requested_on'.trParams({
                        'date': _formatDate(withdrawal.requestedAt!),
                      })
                      : 'unknown_date'.tr,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColor.neutralGrey600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              withdrawal.statusDisplay,
              style: context.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationInfo(BuildContext context, Influencer influencer) {
    if (influencer.isExpired) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.error.withOpacity(0.3), width: 1),
        ),
        child: Text(
          'promo_code_expired'.tr,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColor.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final timeLeft = influencer.timeUntilExpiry;
    if (timeLeft != null && timeLeft.inDays <= 30) {
      final DateTime? expiryLocal = influencer.expirationDate?.toLocal();
      final String locale = Get.locale?.languageCode ?? 'en';
      final String formattedDate =
          expiryLocal != null
              ? DateFormat.yMMMMd(locale).format(expiryLocal)
              : 'unknown_date'.tr;
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'promo_expires_on'.trParams({'date': formattedDate}),
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColor.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Removed unused _buildStatCard in favor of standard setting rows

  void _copyPromoCode(String promoCode) {
    // For now, just show a success message - clipboard implementation would require additional imports
    NotificationService.showSuccess('promo_code_copied'.tr);
    // TODO: Add clipboard import and implement: Clipboard.setData(ClipboardData(text: promoCode));
  }

  void _showWithdrawalDialog(BuildContext context, Influencer influencer) {
    final amountController = TextEditingController();
    final ripController = TextEditingController();
    bool isProcessing = false;
    String? errorMessage;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            scrollable: true,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'request_withdrawal'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColor.neutralGrey600,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: BoxConstraints.tightFor(width: 32, height: 32),
                  onPressed: isProcessing ? null : () => Get.back(),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current balance info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColor.success.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: AppColor.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'available_balance'.tr,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: AppColor.neutralGrey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${influencer.earningsDzd.toStringAsFixed(0)} DZD',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: AppColor.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount input
                  Text(
                    'withdrawal_amount'.tr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'enter_amount'.tr,
                      suffixText: 'DZD',
                      errorStyle: context.textTheme.labelMedium?.copyWith(
                        color: AppColor.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText:
                          errorMessage?.contains('amount') == true
                              ? errorMessage
                              : null,
                    ),
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // RIP input
                  Text(
                    'bank_account_rip'.tr,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: ripController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'enter_rip_number'.tr,
                      errorStyle: context.textTheme.labelMedium?.copyWith(
                        color: AppColor.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText:
                          errorMessage?.contains('RIP') == true
                              ? errorMessage
                              : null,
                    ),
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Processing time info removed as requested

                  // Removed red box error display; errors will be shown as notifications
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ModernButton(
                text: isProcessing ? 'processing'.tr : 'request_withdrawal'.tr,
                style:
                    isProcessing
                        ? ModernButtonStyle.outline
                        : ModernButtonStyle.primary,
                size: ModernButtonSize.medium,
                onPressed:
                    isProcessing
                        ? null
                        : () async {
                          final amountText = amountController.text.trim();
                          final ripText = ripController.text.trim();

                          // Validation
                          if (amountText.isEmpty) {
                            setState(
                              () =>
                                  errorMessage =
                                      'Please enter withdrawal amount',
                            );
                            return;
                          }

                          final amount = double.tryParse(amountText);
                          if (amount == null || amount <= 0) {
                            setState(
                              () =>
                                  errorMessage = 'Please enter a valid amount',
                            );
                            return;
                          }

                          if (amount > influencer.earningsDzd) {
                            NotificationService.showError(
                              'Amount exceeds available balance',
                            );
                            return;
                          }

                          if (amount < influencer.minWithdrawal) {
                            NotificationService.showError(
                              'minimum_withdrawal_amount'.trParams({
                                'amount': influencer.minWithdrawal
                                    .toStringAsFixed(0),
                              }),
                            );
                            return;
                          }

                          if (ripText.isEmpty) {
                            setState(
                              () =>
                                  errorMessage = 'Please enter your RIP number',
                            );
                            return;
                          }

                          if (ripText.length < 20 || ripText.length > 24) {
                            setState(
                              () =>
                                  errorMessage =
                                      'RIP number must be 20-24 digits',
                            );
                            return;
                          }

                          // Process withdrawal
                          setState(() {
                            isProcessing = true;
                            errorMessage = null;
                          });

                          try {
                            final result = await _influencerService
                                .processWithdrawal(amount, ripText);

                            Get.back(); // Close dialog

                            if (result.success) {
                              NotificationService.showSuccess(result.message);
                            } else {
                              NotificationService.showError(result.message);
                            }
                          } catch (e) {
                            setState(() {
                              isProcessing = false;
                            });
                            NotificationService.showError(
                              e.toString().replaceAll('Exception: ', ''),
                            );
                          }
                        },
              ),
            ],
          );
        },
      ),
      barrierDismissible: !isProcessing,
    );
  }

  String _formatDate(DateTime date) {
    // TODO: Implement proper date formatting based on locale
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> logoutUser() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.sqlClear();
    SharedPref.clear();
    await Get.find<ThemeController>().toggleTheme(true);
    NotificationService.showSuccess("You have been Reset Account");
    Get.offAllNamed(AppPages.initial);
  }
}
