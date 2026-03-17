import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_assets.dart';
import 'package:macroaize/constant/app_color.dart';

import 'package:macroaize/SharePrefHelper/constant_user_master.dart';
import 'package:macroaize/screens/AnalyticsScreen/update_weight.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_view.dart';
import 'package:macroaize/screens/HomeScreen/home_view.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_view.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_view.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_controller.dart';
import 'package:macroaize/screens/SettingScreen/setting_view.dart';
import 'package:macroaize/screens/leadingScreen/exit_dailog.dart';
import 'package:macroaize/screens/leadingScreen/leading_controller.dart';
import 'package:macroaize/shared/services/weight_update_service.dart';
import 'package:get/get.dart';
import 'package:macroaize/routes/app_routes.dart';

class LeadingView extends StatefulWidget {
  // tutorial global keys
  static final GlobalKey scannerTabKey = GlobalKey();
  static final GlobalKey analyticsTabKey = GlobalKey();
  static final GlobalKey profileTabKey = GlobalKey();
  static final GlobalKey aiCoachButtonKey = GlobalKey();

  const LeadingView({super.key});

  @override
  State<LeadingView> createState() => _LeadingViewState();
}

class _LeadingViewState extends State<LeadingView>
    with SingleTickerProviderStateMixin {
  final LeadingController _controller = Get.find();
  int _localIndex = 0;

  // Menu Animation
  late AnimationController _menuController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  bool _isMenuOpen = false;

  // lazy tab pages
  final List<Widget?> _pages = [const HomeView(), null, null, null, null];

  @override
  void initState() {
    super.initState();
    _localIndex = _controller.currentIndex;
    _ensurePage(_localIndex);

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
    );
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees (1/8 turn)
    ).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeInOut),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _animateTo(int newIndex) {
    if (!mounted) return;
    final oldIndex = _localIndex;
    setState(() {
      _localIndex = newIndex;
    });
    _ensurePage(newIndex);
    _handleScannerLifecycle(oldIndex, newIndex);
  }

  void _handleScannerLifecycle(int oldIndex, int newIndex) {
    // release camera
    if (oldIndex == 2 && newIndex != 2) {
      try {
        final c =
            Get.isRegistered<ScanFoodController>()
                ? Get.find<ScanFoodController>()
                : null;
        c?.releaseCamera();
      } catch (_) {}
    }
    // activate camera
    if (newIndex == 2) {
      try {
        final c =
            Get.isRegistered<ScanFoodController>()
                ? Get.find<ScanFoodController>()
                : null;
        c?.ensureCameraActive();
      } catch (_) {}
    }
  }

  void _ensurePage(int index) {
    if (_pages[index] != null) return;
    switch (index) {
      case 0:
        _pages[0] = const HomeView();
        break;
      case 1:
        _pages[1] = const RecipesView();
        break;
      case 2:
        _pages[2] = const ScanFoodView();
        break;
      case 3:
        _pages[3] = const AnalyticsView();
        break;
      case 4:
        _pages[4] = const SettingView();
        break;
    }
    if (mounted) setState(() {});
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
        _menuController.reverse();
      });
    }
  }

  void _onMenuOptionSelected(int index) {
    _closeMenu();
    // Handle navigation based on option
    switch (index) {
      case 0: // Meal (Scanner)
        _getOrPutScanController().setBarcodeOnly(false);
        _controller.changeTabIndex(2);
        break;
      case 1: // Barcode
        _getOrPutScanController().setBarcodeOnly(true);
        _controller.changeTabIndex(2);
        break;
      case 2: // Weight
        showUpdateWeightDialog(context, ConstantUserMaster.weight.toString(), (
          value,
        ) async {
          await WeightUpdateService.updateWeightAndOpenOverview(
            int.parse(value),
          );
        }, title: 'Update Weight'.tr);
        break;
      case 3: // Workout
        Get.toNamed(Routes.workoutView);
        break;
    }
  }

  ScanFoodController _getOrPutScanController() {
    return Get.find<ScanFoodController>();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final barHeight = 76.0 + bottomPadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isMenuOpen) {
          _closeMenu();
          return;
        }

        if (_localIndex != 0) {
          // Verify controller exists before using
          if (Get.isRegistered<LeadingController>()) {
            _controller.changeTabIndex(0);
          } else {
            // Fallback if controller not found (unlikely in this structure)
            Get.offAllNamed(Routes.leadingView);
          }
          return;
        }

        showExitConfirmationDialog(context: context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Body Content
            Positioned.fill(
              bottom:
                  _localIndex == 2
                      ? 0
                      : barHeight - 20, // Full height for scanner
              child: GetBuilder<LeadingController>(
                builder: (controller) {
                  // Sync logic
                  if (_localIndex != controller.currentIndex) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _animateTo(controller.currentIndex);
                    });
                  }

                  final children = List<Widget>.generate(
                    5,
                    (i) => _pages[i] ?? const SizedBox.shrink(),
                  );
                  return IndexedStack(index: _localIndex, children: children);
                },
              ),
            ),

            // Dim Overlay
            if (_isMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder:
                        (ctx, child) => Container(
                          color: Colors.black.withValues(
                            alpha: 0.5 * _fadeAnimation.value,
                          ),
                        ),
                  ),
                ),
              ),

            // Menu Items (Semi-Circle)
            Positioned(
              left: 0,
              right: 0,
              bottom: barHeight - 20,
              height: 300, // Ensure strictly large enough for the menu radius
              child: _buildCircularMenu(),
            ),

            // Custom Bottom Bar
            if (_localIndex != 2)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(barHeight),
              ),

            // Floating Custom Plus Button
            if (_localIndex != 2)
              Positioned(
                bottom:
                    bottomPadding + 28, // Center vertically in the bar mostly
                child: _buildPlusButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularMenu() {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final radius = 110.0 * _expandAnimation.value;
        // Angles for 4 items: distributed from 180 (left) to 0 (right)?
        // Or centered upwards. Let's do 4 items in a 180 arc.
        // 180 degrees / 5 intervals = 36 deg per step?
        // Angles: 162, 126, 90, 54, 18 ? No, that's 5 items.
        // 4 items: 150, 110, 70, 30 ? roughly.

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            _buildMenuItem(
              2, // Index 2 is Weight
              radius,
              150, // Weight now at leftmost pos
              AppAssets.maintain,
              "Weight",
            ),
            _buildMenuItem(
              1, // Index 1 is Barcode
              radius,
              110,
              AppAssets.barcode,
              "Barcode",
            ),
            _buildMenuItem(
              0, // Index 0 is Meal
              radius,
              70, // Meal now at middle-right pos
              AppAssets.lunch,
              "Meal",
            ),
            _buildMenuItem(
              3, // Index 3 is Workout
              radius,
              30,
              AppAssets.workoutIcon,
              "Workout",
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
    int index,
    double radius,
    double angleDeg,
    String assetPath,
    String label,
  ) {
    final angleRad = angleDeg * (math.pi / 180);
    final x = radius * math.cos(angleRad);
    final y = -radius * math.sin(angleRad); // negative because going up
    // However, x is relative to center. Center is 0.
    // cos(150) is negative (left), cos(30) is positive (right). Perfect.

    final scale = _expandAnimation.value;
    if (scale == 0) return const SizedBox.shrink();

    return Transform.translate(
      offset: Offset(x, y),
      child: Opacity(
        opacity: scale.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _onMenuOptionSelected(index),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlusButton() {
    return GestureDetector(
      key: LeadingView.scannerTabKey,
      onTap: _toggleMenu,
      child: AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle:
                _rotateAnimation.value *
                2 *
                math.pi, // 0 to 0.125 * 2pi = 45 deg
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColor.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryOrange.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 36),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 24,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: AppColor.primaryOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 4 items (skip center slot)
              return Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      0,
                      Icons.home_filled,
                      Icons.home_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      1,
                      Icons.restaurant_menu_rounded,
                      Icons.restaurant_menu_outlined,
                    ),
                  ),
                  const SizedBox(width: 60), // Space for center FAB
                  Expanded(
                    child: Container(
                      key: LeadingView.analyticsTabKey,
                      child: _buildNavItem(
                        3,
                        Icons.bar_chart_rounded,
                        Icons.bar_chart_outlined,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      key: LeadingView.profileTabKey,
                      child: _buildNavItem(
                        4,
                        Icons.person_rounded,
                        Icons.person_outline_rounded,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _localIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isMenuOpen) _closeMenu();
        _controller.changeTabIndex(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              key: ValueKey(isSelected),
              color:
                  isSelected ? AppColor.primaryOrange : AppColor.neutralGrey400,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 4 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: AppColor.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
