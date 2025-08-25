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
import '../../ThemeService/ThemeController.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';

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
            // Premium card
            _buildPremiumCard(context),
            
            const SizedBox(height: 24),
            
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
            colors: [
              AppColor.accentOrange,
              AppColor.accentOrangeLight,
            ],
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
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
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
                Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? AppColor.neutralGrey700 : AppColor.neutralGrey200),
                _buildSettingRow(
                  context,
                  "Language".tr,
                  Get.find<MainController>().languageKey.tr,
                  Icons.language_outlined,
                  AppColor.tertiary,
                  onTap: () => Get.toNamed(Routes.languageView),
                ),
                Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? AppColor.neutralGrey700 : AppColor.neutralGrey200),
                // Dynamic customization items from config
                ...SettingConfig.customizationItems.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == SettingConfig.customizationItems.length - 1;
                  
                  return Column(
                    children: [
                      _buildSettingRow(
                        context,
                        item['title'].toString().tr,
                        item.containsKey('subtitleKey') ? item['subtitleKey'].toString().tr : null,
                        item['icon'] as IconData,
                        item['color'] as Color,
                        onTap: () => Get.toNamed(item['route'] as String),
                      ),
                      if (!isLast) Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? AppColor.neutralGrey700 : AppColor.neutralGrey200),
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
              children: SettingConfig.legalItems.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == SettingConfig.legalItems.length - 1;
                
                return Column(
                  children: [
                    _buildSettingRow(
                      context,
                      item['title'].toString().tr,
                      null,
                      item['icon'] as IconData,
                      AppColor.neutralGrey600,
                      onTap: () => _handleLegalAction(item['action'] as String),
                    ),
                    if (!isLast) Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? AppColor.neutralGrey700 : AppColor.neutralGrey200),
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
                Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? AppColor.neutralGrey700 : AppColor.neutralGrey200),
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColor.primaryOrange,
            size: 20,
          ),
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
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
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
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
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
                          fontSize: 12.0, // reduced size for subtitle/description
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

  Future<void> logoutUser() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.sqlClear();
    SharedPref.clear();
    await Get.find<ThemeController>().toggleTheme(true);
  NotificationService.showSuccess("You have been Reset Account");
    Get.offAllNamed(AppPages.initial);
  }
}
