import 'package:flutter/material.dart';
import 'package:macroaize/SharePrefHelper/SharePref.dart';
import 'package:macroaize/SharePrefHelper/SharePrefKey.dart';
import 'package:macroaize/constant/AppColor.dart';
import 'package:get/get.dart';

// app tips service
class AppTipsService extends GetxService {
  static AppTipsService get to => Get.find();

  Future<AppTipsService> init() async {
    return this;
  }

  // check tips seen
  Future<bool> hasSeenAppTips() async {
    return await SharedPref.readBool(SharePrefKey.hasSeenAppTips) ?? false;
  }

  // mark tips seen
  Future<void> markTipsAsSeen() async {
    await SharedPref.saveBool(SharePrefKey.hasSeenAppTips, true);
  }

  // show if not seen
  Future<void> showTipsIfNeeded(BuildContext context) async {
    final hasSeen = await hasSeenAppTips();
    if (!hasSeen) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (context.mounted) {
        showAppTips(context);
      } else {}
    } else {}
  }

  // show tips overlay
  void showAppTips(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AppTipsOverlay(),
    );
  }

  Future<void> resetTips() async {
    await SharedPref.removeKey(SharePrefKey.hasSeenAppTips);
  }
}

class AppTipsOverlay extends StatefulWidget {
  const AppTipsOverlay({super.key});

  @override
  State<AppTipsOverlay> createState() => _AppTipsOverlayState();
}

class _AppTipsOverlayState extends State<AppTipsOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TipData> _tips = [
    TipData(
      titleKey: 'tip_welcome_title',
      descriptionKey: 'tip_welcome_description',
      icon: Icons.waving_hand_rounded,
      gradient: AppColor.primaryGradient,
    ),
    TipData(
      titleKey: 'tip_track_food_title',
      descriptionKey: 'tip_track_food_description',
      icon: Icons.restaurant_menu_rounded,
      gradient: AppColor.accentGradient,
    ),
    TipData(
      titleKey: 'tip_scan_food_title',
      descriptionKey: 'tip_scan_food_description',
      icon: Icons.camera_alt_rounded,
      gradient: AppColor.accentGradient,
    ),
    TipData(
      titleKey: 'tip_ai_coach_title',
      descriptionKey: 'tip_ai_coach_description',
      icon: Icons.psychology_rounded,
      gradient: AppColor.primaryGradient,
    ),
    TipData(
      titleKey: 'tip_analytics_title',
      descriptionKey: 'tip_analytics_description',
      icon: Icons.analytics_rounded,
      gradient: AppColor.accentGradient,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tips.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _finish();
  }

  Future<void> _finish() async {
    await AppTipsService().markTipsAsSeen();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'app_tips'.tr,
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'skip'.tr,
                      style: TextStyle(
                        color: AppColor.neutralGrey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            SizedBox(
              height: 380, // Slightly reduced height to fit indicators below
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _tips.map((tip) => _TipCard(tip: tip)).toList(),
              ),
            ),

            // Page Indicator (Moved out of PageView)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _tips.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient:
                          _currentPage == index
                              ? AppColor.primaryGradient
                              : null,
                      color:
                          _currentPage == index
                              ? null
                              : AppColor.neutralGrey400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // nav buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(
                            color: AppColor.primaryOrange,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'previous'.tr,
                          style: TextStyle(
                            color: AppColor.primaryOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColor.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primaryOrange.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentPage < _tips.length - 1
                              ? 'next'.tr
                              : 'get_started'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// tip card widget
class _TipCard extends StatelessWidget {
  final TipData tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: tip.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tip.gradient.colors.first.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(tip.icon, size: 60, color: Colors.white),
          ),

          const SizedBox(height: 32),

          // title
          Text(
            tip.titleKey.tr,
            textAlign: TextAlign.center,
            style: context.theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // description
          Text(
            tip.descriptionKey.tr,
            textAlign: TextAlign.center,
            style: context.theme.textTheme.bodyLarge?.copyWith(
              color: AppColor.neutralGrey600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// tip data model
class TipData {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Gradient gradient;

  TipData({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.gradient,
  });
}
