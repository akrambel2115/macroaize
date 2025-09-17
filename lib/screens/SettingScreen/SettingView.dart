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
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';
import 'package:foodcalorietracker/shared/models/subscription.dart';
import 'package:foodcalorietracker/shared/services/subscription_service.dart';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'package:foodcalorietracker/shared/models/user_usage.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import 'package:foodcalorietracker/shared/services/influencer_service.dart';
import 'package:foodcalorietracker/shared/models/influencer.dart';
import 'subscription_status_card.dart';
import '../../ThemeService/ThemeController.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import 'package:intl/intl.dart';

// Configuration for settings menus
class SettingConfig {

  // Customization menu items
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

  // Legal menu items
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

/// Settings view with organized sections and config-driven menus
class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  // Create a single instance to avoid recreating service on every build
  static final _subscriptionService = SubscriptionService();
  static final _influencerService = InfluencerService();

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SettingController());
  // Refresh AppConfigService when settings open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.find<AppConfigService>().refresh();
      } catch (_) {
        // AppConfigService might not be ready yet
      }
    });
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium card / subscription status
            _buildPremiumSection(context),

            const SizedBox(height: 16),

            // Daily usage (non-premium only)
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

            // Influencer section
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
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnap) {
                    final user = authSnap.data;
                    // If user not authenticated: show login prompt AND free-tier limits from Remote Config
                    if (user == null) {
                      final cfg = Get.find<AppConfigService>();
                      return Obx(() {
                        // Listen to isLoaded to rebuild when config refreshes
                        cfg.isLoaded; // trigger rebuild
                        final remainingScans = cfg.freeScanLimit;
                        final remainingChats = cfg.freeChatLimit;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
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
                                    color: AppColor.primaryOrange.withOpacity(0.04),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColor.primaryOrange.withOpacity(0.12),
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
                                          style: context.textTheme.bodyMedium?.copyWith(
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
                            ),
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
                      });
                    }

                    // Authenticated: show live usage values
                    return StreamBuilder<UserUsage?>(
                      stream: usageService.usageStream,
                      builder: (context, usageSnapshot) {
                        if (usageSnapshot.connectionState == ConnectionState.waiting || !usageSnapshot.hasData) {
                          // Show a tiny placeholder while we hydrate from server to avoid misleading defaults
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                _buildProfileInfoRow(
                                  context,
                                  'Scans'.tr,
                                  '... ',
                                  Icons.photo_camera_outlined,
                                  AppColor.primaryGreen,
                                ),
                                const SizedBox(height: 16),
                                _buildProfileInfoRow(
                                  context,
                                  'Chat'.tr,
                                  '... ',
                                  Icons.chat_bubble_outline,
                                  AppColor.accent,
                                ),
                              ],
                            ),
                          );
                        }
                        final usage = usageSnapshot.data ??
                            const UserUsage(scanCount: 0, chatCount: 0);
                        final remainingScans =
                            (usage.scanLimit - usage.scanCount)
                                .clamp(0, usage.scanLimit);
                        final remainingChats =
                            (usage.chatLimit - usage.chatCount)
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
                    );
                  },
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
          'account'.tr,
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
                        'tap_to_view_details'.tr,
                        Icons.person_outline,
                        AppColor.primaryOrange,
                        onTap: () => Get.toNamed(Routes.accountDetailsView),
                      )
                    else
                      _buildSettingRow(
                        context,
                        'register_login'.tr,
                        'access_account_sync_data'.tr,
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
                const SizedBox(height: 12),
                _buildSettingRow(
                  context,
                  "Language".tr,
                  Get.find<MainController>().languageKey.tr,
                  Icons.language_outlined,
                  AppColor.tertiary,
                  onTap: () => Get.toNamed(Routes.languageView),
                ),
                const SizedBox(height: 12),
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
                      if (!isLast) const SizedBox(height: 12),
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
                        if (!isLast) const SizedBox(height: 12),
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
        _buildSectionHeader(context, "app_info".tr, Icons.info_outline),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.5),
          child: ModernCard(
            child: Column(
              children: [
                Obx(() => _buildSettingRow(
                      context,
                      "version".tr,
                      controller.appVersion.value.isNotEmpty
                          ? controller.appVersion.value
                          : 'unknown',
                      Icons.code_outlined,
                      AppColor.neutralGrey600,
                    )),
                const SizedBox(height: 12),
                _buildSettingRow(
                  context,
                  "reset_data".tr,
                  "clear_all_app_data".tr,
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
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.error,
                        side: BorderSide(color: AppColor.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        "Cancel".tr,
                        style: TextStyle(color: AppColor.error),
                      ),
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
                    const SizedBox(height: 12),

                    // Current balance
                    _buildProfileInfoRow(
                      context,
                      'current_balance'.tr,
                      '${influencer.earningsDzd.toStringAsFixed(0)} ${'currency_dzd'.tr}',
                      Icons.account_balance_wallet,
                      AppColor.success,
                    ),
                    const SizedBox(height: 12),

                    // Total earned
                    _buildProfileInfoRow(
                      context,
                      'total_earned'.tr,
                      '${influencer.totalEarningsDzd.toStringAsFixed(0)} ${'currency_dzd'.tr}',
                      Icons.trending_up,
                      AppColor.info,
                    ),
                    const SizedBox(height: 12),

                    // Referrals count
                    _buildProfileInfoRow(
                      context,
                      'referrals_count'.tr,
                      influencer.usersCount.toString(),
                      Icons.people,
                      AppColor.warning,
                    ),
                    const SizedBox(height: 12),

                    // Withdrawal action row
                    _buildSettingRow(
                      context,
                      'request_withdrawal'.tr,
                      'minimum_withdrawal_amount'.trParams({
                        'amount': influencer.minWithdrawal.toStringAsFixed(0),
                      }),
                      Icons.account_balance,
                      influencer.canWithdraw
                          ? AppColor.primaryOrange
                          : AppColor.neutralGrey600,
                      onTap: () => _showWithdrawalDialog(context, influencer),
                    ),
                    const SizedBox(height: 12),

                    // Withdrawal history action row
                    _buildSettingRow(
                      context,
                      'view_withdrawal_history'.tr,
                      'withdrawal_history_subtitle'.tr,
                      Icons.history,
                      AppColor.info,
                      onTap: () => Get.toNamed(Routes.withdrawalHistoryView),
                    ),

                    // Expiration info if applicable
                    if (influencer.expirationDate != null) ...[
                      const SizedBox(height: 16),
                      _buildExpirationInfo(context, influencer),
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

  // ignore: unused_element
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
    try {
      Clipboard.setData(ClipboardData(text: promoCode));
      NotificationService.showSuccess('promo_code_copied'.tr);
    } catch (e) {
      // If clipboard access fails, still inform the user
      NotificationService.showError(
        'copy_failed'.trParams({'error': e.toString()}),
      );
    }
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
                          '${influencer.earningsDzd.toStringAsFixed(0)} ${'currency_dzd'.tr}',
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
                      suffixText: 'currency_dzd'.tr,
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
                              _showProcessingTimeAlert(
                                context,
                                result.withdrawalId ?? 'Unknown',
                                3,
                              );
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

  /// Shows full withdrawal history in a modal dialog
  // ignore: unused_element
  void _showFullWithdrawalHistory(
    BuildContext context,
    List<WithdrawalRecord> withdrawalHistory,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
            maxWidth: Get.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.primaryOrange.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColor.primaryOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'withdrawal_history'.tr,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.primaryOrange,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColor.neutralGrey600,
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child:
                    withdrawalHistory.isEmpty
                        ? Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: AppColor.neutralGrey400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_withdrawal_history'.tr,
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: AppColor.neutralGrey600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20),
                          itemCount: withdrawalHistory.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final withdrawal = withdrawalHistory[index];
                            return _buildEnhancedWithdrawalHistoryItem(
                              context,
                              withdrawal,
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Enhanced withdrawal history item with more details
  Widget _buildEnhancedWithdrawalHistoryItem(
    BuildContext context,
    WithdrawalRecord withdrawal,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (withdrawal.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColor.success;
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        statusColor = AppColor.warning;
        statusIcon = Icons.schedule;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = AppColor.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColor.neutralGrey600;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with amount and status
          Row(
            children: [
              Expanded(
                child: Text(
                  '${withdrawal.amount.toStringAsFixed(0)} ${'currency_dzd'.tr}',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      withdrawal.statusDisplay,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  'request_id_short'.tr,
                  withdrawal.id,
                  Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  context,
                  'bank_account_short'.tr,
                  withdrawal.ripMasked,
                  Icons.account_balance,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  'requested_date'.tr,
                  withdrawal.requestedAt != null
                      ? _formatDate(withdrawal.requestedAt!)
                      : 'unknown_date'.tr,
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailItem(
                  context,
                  'processing_deadline'.tr,
                  withdrawal.estimatedProcessingDate ?? 'unknown_date'.tr,
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build detail items in withdrawal history
  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColor.neutralGrey500),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColor.neutralGrey600,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows a processing time alert after successful withdrawal request
  void _showProcessingTimeAlert(
    BuildContext context,
    String withdrawalId,
    int processingDays,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColor.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'withdrawal_submitted'.tr,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'request_id'.trParams({'id': withdrawalId}),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColor.primaryOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'processing_time'.trParams({
                        'days': processingDays.toString(),
                      }),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'withdrawal_email_confirmation'.tr,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColor.neutralGrey600,
              ),
            ),
          ],
        ),
        actions: [
          ModernButton(
            text: 'got_it'.tr,
            style: ModernButtonStyle.primary,
            size: ModernButtonSize.medium,
            onPressed: () => Get.back(),
          ),
        ],
      ),
      barrierDismissible: true,
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
    NotificationService.showSuccess("account_reset_success".tr);
    Get.offAllNamed(AppPages.initial);
  }

  // ignore: unused_element
  String _maskRip(String rip) {
    if (rip.isEmpty) return '';
    if (rip.length <= 4) return rip; // If it's already short, don't mask

    // Show only the last 4 digits for security, mask the rest
    final lastFour = rip.substring(rip.length - 4);
    final masked = '*' * (rip.length - 4);
    return '$masked$lastFour';
  }
}
