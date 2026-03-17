import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/main_controller.dart';
import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'package:macroaize/constant/database_helper.dart';
import 'package:macroaize/routes/app_pages.dart';
import 'package:macroaize/routes/app_routes.dart';
import 'package:macroaize/screens/SettingScreen/setting_controller.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/modern_button.dart';
import 'package:macroaize/widgets/modern_card.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/features/auth/presentation/auth_modal.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:macroaize/shared/services/subscription_service.dart';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/shared/models/user_usage.dart';
import 'package:macroaize/shared/services/app_config_service.dart';
import 'package:macroaize/shared/services/influencer_service.dart';
import 'package:macroaize/shared/models/influencer.dart';
import 'package:macroaize/shared/utils/navigation_helpers.dart';
import 'subscription_status_card.dart';
import '../../ThemeService/theme_controller.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:macroaize/shared/services/widget_promotion_service.dart';
import 'package:macroaize/shared/services/wellness_sync_service.dart';
import 'package:macroaize/widgets/widget_preview_cards.dart';
import 'package:lottie/lottie.dart';

// settings menu config
class SettingConfig {
  // customization items
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
    {
      'title': 'notification_settings',
      'icon': Icons.notifications_outlined,
      'color': AppColor.tertiary,
      'route': Routes.notificationSettingsView,
    },
    {
      'title': 'Home Screen Widgets',
      'icon': Icons.widgets_outlined,
      'color': AppColor.primaryGreen,
      'action': 'widgets',
    },
  ];

  // legal items
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

// settings view
class SettingView extends GetView<SettingController> {
  const SettingView({super.key});

  // singleton services
  static final _subscriptionService = SubscriptionService();
  static final _influencerService = InfluencerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _buildModernAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // premium section
            _buildPremiumSection(context),

            const SizedBox(height: 16),

            // daily usage
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

            _buildInfluencerSection(context),

            _buildProfileSection(context),

            const SizedBox(height: 24),

            _buildWellnessSection(context),

            const SizedBox(height: 24),

            _buildCustomizationSection(context),

            const SizedBox(height: 24),

            _buildLegalSection(context),

            const SizedBox(height: 24),

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
        // hide while loading
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
                    // show login prompt
                    if (user == null) {
                      final cfg = Get.find<AppConfigService>();
                      return Obx(() {
                        cfg.isLoaded;
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
                                    color: AppColor.primaryOrange.withValues(
                                      alpha: 0.04,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColor.primaryOrange
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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

                    // show live usage
                    return StreamBuilder<UserUsage?>(
                      stream: usageService.usageStream,
                      builder: (context, usageSnapshot) {
                        if (usageSnapshot.connectionState ==
                                ConnectionState.waiting ||
                            !usageSnapshot.hasData) {
                          // loading placeholder
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
        // show premium card
        if (authSnapshot.data == null) {
          return _buildPremiumCard(context);
        }

        // listen subscription
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
                child: GestureDetector(
                  onTap: () => Get.toNamed(Routes.premiumView),
                  child: SubscriptionStatusCard(subscription: sub),
                ),
              );
            }
            // fallback premium card
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
              color: AppColor.accentOrange.withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                            color: Colors.white.withValues(alpha: 0.9),
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
            // navigate personal details
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
                // dynamic items
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
                        previewWidget:
                            item['action'] == 'widgets'
                                ? const WidgetPreviewCards()
                                : null,
                        onTap: () {
                          if (item.containsKey('route')) {
                            Get.toNamed(item['route'] as String);
                          } else if (item['action'] == 'widgets') {
                            WidgetPromotionService().showPromotion();
                          }
                        },
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

  Widget _buildWellnessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Wellness', Icons.favorite_outline),
        const SizedBox(height: 12),
        ModernFadeSlideTransition(
          beginOffset: const Offset(0, 0.25),
          child: ModernCard(
            child: Builder(
              builder: (_) {
                final service = controller.wellnessOrNull;
                if (service == null) {
                  return _buildSettingRow(
                    context,
                    'Wellness',
                    'Unavailable',
                    Icons.health_and_safety_outlined,
                    AppColor.neutralGrey600,
                  );
                }

                return Obx(() {
                  final isConnected = service.isConnected.value;
                  final isBusy = service.isBusy.value;
                  final isAvailable = service.isAvailable.value;

                  String subtitle;
                  if (!isAvailable) {
                    subtitle = service.statusMessage.value;
                  } else if (isConnected) {
                    subtitle = 'Syncing workouts and steps';
                  } else {
                    subtitle = 'Connect for better accuracy when app is closed';
                  }

                  return _buildSettingRow(
                    context,
                    service.providerDisplayName,
                    subtitle,
                    Icons.health_and_safety_outlined,
                    isConnected ? AppColor.success : AppColor.primaryOrange,
                    onTap:
                        isBusy
                            ? null
                            : () => _showWellnessConnectSheet(context, service),
                    trailing:
                        isBusy
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : null,
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showWellnessConnectSheet(
    BuildContext context,
    WellnessSyncService service,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.neutralGrey400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildWellnessIllustration(context),
                  const SizedBox(height: 28),
                  Text(
                    'Sync with ${service.providerDisplayName}',
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect ${service.providerDisplayName} to automatically sync workouts and steps. This is optional, but improves accuracy when the app is closed.',
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppColor.neutralGrey600,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final isConnected = service.isConnected.value;
                    final isBusy = service.isBusy.value;
                    if (!isConnected) {
                      return ModernButton(
                        text: 'Continue',
                        onPressed: () async {
                          await controller.connectWellness();
                          if (service.isConnected.value &&
                              sheetContext.mounted) {
                            safeBack();
                          }
                        },
                        loading: isBusy,
                        width: double.infinity,
                        height: 54,
                        style: ModernButtonStyle.primary,
                      );
                    }

                    return Column(
                      children: [
                        TextButton(
                          onPressed:
                              isBusy
                                  ? null
                                  : () async {
                                    await controller.disconnectWellness();
                                    if (sheetContext.mounted) {
                                      safeBack();
                                    }
                                  },
                          child: Text(
                            'Disconnect',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColor.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWellnessIllustration(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.neutralGrey100.withValues(alpha: 0.25),
            AppColor.neutralGrey100.withValues(alpha: 0.08),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Lottie.asset('assets/lottie/health.json', fit: BoxFit.contain),
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
                Obx(
                  () => _buildSettingRow(
                    context,
                    "version".tr,
                    controller.appVersion.value.isNotEmpty
                        ? controller.appVersion.value
                        : 'unknown',
                    Icons.code_outlined,
                    AppColor.neutralGrey600,
                  ),
                ),
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
            color: AppColor.primaryOrange.withValues(alpha: 0.1),
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
            color: color.withValues(alpha: 0.1),
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
    Widget? previewWidget,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        // light mode overlay
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          final isLight = Theme.of(context).brightness == Brightness.light;
          if (isLight) return AppColor.neutralGrey100.withValues(alpha: 0.5);
          return AppColor.neutralGrey800.withValues(alpha: 0.12);
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ), // Increased vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
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
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: context.theme.iconTheme.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
                ],
              ),
              if (previewWidget != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 0),
                  child: previewWidget,
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
              // warning icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  color: AppColor.error,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // title
              Text(
                "Confirm Reset".tr,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // content
              Text(
                "Are you sure you want to Reset Data?".tr,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: AppColor.neutralGrey600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // buttons
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
                      onPressed: () => safeBack(),
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
                        safeBack();
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
        // show if influencer
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
                    // promo code block
                    StatefulBuilder(
                      builder: (stateCtx, setState) {
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
                                      if (!stateCtx.mounted) return;
                                      setState(() => promoCopied = true);
                                      Future.delayed(
                                        const Duration(seconds: 2),
                                        () {
                                          if (!stateCtx.mounted) return;
                                          setState(() => promoCopied = false);
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryOrange
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColor.primaryOrange
                                              .withValues(alpha: 0.3),
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

                    // withdrawal history
                    _buildSettingRow(
                      context,
                      'view_withdrawal_history'.tr,
                      'withdrawal_history_subtitle'.tr,
                      Icons.history,
                      AppColor.info,
                      onTap: () => Get.toNamed(Routes.withdrawalHistoryView),
                    ),

                    // expiration info
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

  Widget _buildExpirationInfo(BuildContext context, Influencer influencer) {
    if (influencer.isExpired) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.error.withValues(alpha: 0.3),
            width: 1,
          ),
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
          color: AppColor.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColor.warning.withValues(alpha: 0.3),
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

  void _copyPromoCode(String promoCode) {
    try {
      Clipboard.setData(ClipboardData(text: promoCode));
      NotificationService.showSuccess('promo_code_copied'.tr);
    } catch (e) {
      // clipboard failed
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

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 24),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColor.neutralGrey300.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header text
                        Text(
                          'request_withdrawal'.tr,
                          style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'withdrawal_subtitle'.tr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColor.neutralGrey600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Hero Balance Display
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColor.neutralGrey300.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColor.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColor.success,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'available_balance'.tr.toUpperCase(),
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color: AppColor.neutralGrey600,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${influencer.earningsDzd.toStringAsFixed(0)} ${'currency_dzd'.tr}',
                                    style: context.textTheme.headlineSmall
                                        ?.copyWith(
                                          color:
                                              context
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Amount Input
                        Text(
                          'withdrawal_amount'.tr,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (_) {
                            if (errorMessage != null) {
                              setState(() => errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: context.theme.cardColor,
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              child: TextButton(
                                onPressed: () {
                                  amountController.text = influencer.earningsDzd
                                      .toStringAsFixed(0);
                                  if (errorMessage != null) {
                                    setState(() => errorMessage = null);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: AppColor.primaryOrange
                                      .withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'MAX',
                                  style: TextStyle(
                                    color: AppColor.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            suffixText: 'currency_dzd'.tr,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColor.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            errorText:
                                (errorMessage == 'enter_withdrawal_amount'.tr ||
                                        errorMessage ==
                                            'enter_valid_amount'.tr ||
                                        errorMessage ==
                                            'amount_exceeds_balance')
                                    ? errorMessage
                                    : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            'minimum_withdrawal_amount'.trParams({
                              'amount': influencer.minWithdrawal
                                  .toStringAsFixed(0),
                            }),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColor.neutralGrey600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // RIP Input
                        Text(
                          'bank_account_rip'.tr,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: ripController,
                          keyboardType: TextInputType.number,
                          style: context.textTheme.titleMedium?.copyWith(
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (_) {
                            if (errorMessage != null) {
                              setState(() => errorMessage = null);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '0000 0000 0000 0000 0000',
                            filled: true,
                            fillColor: context.theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColor.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            errorText:
                                (errorMessage == 'enter_rip_number_error'.tr ||
                                        errorMessage == 'rip_invalid_format'.tr)
                                    ? errorMessage
                                    : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            'rip_helper_text'.tr,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: AppColor.neutralGrey600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Action Button
                        ModernButton(
                          text:
                              isProcessing
                                  ? 'processing'.tr
                                  : 'confirm_withdrawal'.tr,
                          style: ModernButtonStyle.primary,
                          size: ModernButtonSize.medium,
                          loading: isProcessing,
                          width: double.infinity,
                          onPressed:
                              isProcessing
                                  ? null
                                  : () async {
                                    final amountText =
                                        amountController.text.trim();
                                    final ripText = ripController.text.trim();

                                    // validation checks
                                    if (amountText.isEmpty) {
                                      setState(
                                        () =>
                                            errorMessage =
                                                'enter_withdrawal_amount'.tr,
                                      );
                                      return;
                                    }

                                    final amount = double.tryParse(amountText);
                                    if (amount == null || amount <= 0) {
                                      setState(
                                        () =>
                                            errorMessage =
                                                'enter_valid_amount'.tr,
                                      );
                                      return;
                                    }

                                    if (amount > influencer.earningsDzd) {
                                      setState(
                                        () =>
                                            errorMessage =
                                                'amount_exceeds_balance',
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
                                            errorMessage =
                                                'enter_rip_number_error'.tr,
                                      );
                                      return;
                                    }

                                    final cleanRip = ripText.replaceAll(
                                      RegExp(r'\s+'),
                                      '',
                                    );
                                    if (!RegExp(
                                      r'^\d{20}$',
                                    ).hasMatch(cleanRip)) {
                                      setState(
                                        () =>
                                            errorMessage =
                                                'rip_invalid_format'.tr,
                                      );
                                      return;
                                    }

                                    // Process
                                    setState(() {
                                      isProcessing = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final result = await _influencerService
                                          .processWithdrawal(amount, cleanRip);
                                      safeBack();
                                      if (result.success) {
                                        if (!context.mounted) return;
                                        _showProcessingTimeAlert(
                                          context,
                                          result.withdrawalId ?? 'Unknown',
                                          3,
                                        );
                                        NotificationService.showSuccess(
                                          result.message,
                                        );
                                      } else {
                                        NotificationService.showError(
                                          result.message,
                                        );
                                      }
                                    } on WithdrawalException catch (e) {
                                      setState(() => isProcessing = false);
                                      // Show localized error message
                                      NotificationService.showError(
                                        e.localizationKey.tr,
                                      );
                                    } catch (e) {
                                      setState(() => isProcessing = false);
                                      // Generic fallback for unexpected errors
                                      NotificationService.showError(
                                        'withdrawal_request_failed'.tr,
                                      );
                                    }
                                  },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !isProcessing,
    );
  }

  // processing time alert
  void _showProcessingTimeAlert(
    BuildContext context,
    String withdrawalId,
    int processingDays,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with Glow Layering
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColor.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColor.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'withdrawal_submitted'.tr,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'withdrawal_email_confirmation'.tr,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColor.neutralGrey600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Receipt / Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Processing Time Row (Primary Info)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColor.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'processing_time'.trParams({
                                  'days': processingDays.toString(),
                                }),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: context.theme.dividerColor.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    // Reference ID Row (Secondary Info)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            size: 18,
                            color: AppColor.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ref ID: $withdrawalId',
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              ModernButton(
                text: 'got_it'.tr,
                style: ModernButtonStyle.primary,
                size: ModernButtonSize.medium,
                width: double.infinity,
                onPressed: () => safeBack(),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> logoutUser() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.sqlClear();
    SharedPref.clear();
    await Get.find<ThemeController>().toggleTheme(true);
    NotificationService.showSuccess("account_reset_success".tr);
    Get.offAllNamed(AppPages.initial);
  }
}
