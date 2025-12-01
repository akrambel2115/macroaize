import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/constant/AppAssets.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeView.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodController.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingView.dart';
import 'package:foodcalorietracker/screens/leadingScreen/ExitDailog.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingController.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

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

class _LeadingViewState extends State<LeadingView> {
  final LeadingController _controller = Get.find();
  int _localIndex = 0;
  final GlobalKey _stackKey = GlobalKey();
  final double _indicatorWidth = 48.0;
  // lazy tab pages
  final List<Widget?> _pages = [
    const HomeView(),
    null,
    null,
    null,
    null,
  ];

  @override
  void initState() {
    super.initState();
    _localIndex = _controller.currentIndex;
    _ensurePage(_localIndex);
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showExitConfirmationDialog(context: context);
        return Future(() => true);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: GetBuilder<LeadingController>(
          builder: (controller) {
            // hide on scanner
            if (controller.currentIndex == 2) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton(
              key: LeadingView.aiCoachButtonKey,
              onPressed: () {
                Get.toNamed(Routes.chatView);
              },
              backgroundColor: context.theme.focusColor,
              shape: const CircleBorder(),
              elevation: 6,
              child: SizedBox(
                width: 44,
                height: 44,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Lottie.asset(
                    'assets/lottie/chat.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: GetBuilder<LeadingController>(
          builder: (controller) {
            // sync external changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_localIndex != controller.currentIndex) {
                _animateTo(controller.currentIndex);
              }
            });
            return Container(
              height: 76 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                color: context.theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final navCount = 5;
                      final slotWidth = constraints.maxWidth / navCount;
                      // rtl support
                      final isRtl =
                          Directionality.of(context) == TextDirection.rtl;
                      final visualIndex =
                          isRtl ? (navCount - 1 - _localIndex) : _localIndex;
                      final centerX = slotWidth * visualIndex + slotWidth / 2;
                      final left = centerX - _indicatorWidth / 2;
                      final top =
                          constraints.maxHeight / 2 - _indicatorWidth / 2;

                      return Stack(
                        key: _stackKey,
                        children: [
                          // tab indicator
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            left: left,
                            top: top,
                            width: _indicatorWidth,
                            height: _indicatorWidth,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primaryOrange.withOpacity(
                                      0.28,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // nav items
                          Row(
                            children: [
                              Expanded(
                                child: _buildNavItem(
                                  context,
                                  controller,
                                  0,
                                  Icons.home_filled,
                                  Icons.home_outlined,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  context,
                                  controller,
                                  1,
                                  Icons.restaurant_menu_rounded,
                                  Icons.restaurant_menu_outlined,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  key: LeadingView.scannerTabKey,
                                  child: _buildNavItem(
                                    context,
                                    controller,
                                    2,
                                    Icons.camera_alt_rounded,
                                    Icons.camera_alt_outlined,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  key: LeadingView.analyticsTabKey,
                                  child: _buildNavItem(
                                    context,
                                    controller,
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
                                    context,
                                    controller,
                                    4,
                                    Icons.person_rounded,
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        body: GetBuilder<LeadingController>(
          builder: (controller) {
            final children = List<Widget>.generate(
              5,
              (i) => _pages[i] ?? const SizedBox.shrink(),
            );
            return IndexedStack(
              index: controller.currentIndex,
              children: children,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    LeadingController controller,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
  ) {
    final isSelected = controller.currentIndex == index;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final navCount = 5;
    final visualIndex = isRtl ? (navCount - 1 - index) : index;

    return Expanded(
      child: Semantics(
        button: true,
        label: 'Bottom navigation item $visualIndex',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.changeTabIndex(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) {
                    final isCamera = index == 2;
                    if (isCamera) {
                      // scan icon
                      return SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                            child: Image.asset(
                              AppAssets.scanHomeIcon,
                              width: 22,
                              height: 22,
                              key: ValueKey(isSelected),
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      width: 48,
                      height: 48,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                          child: Icon(
                            isSelected ? activeIcon : inactiveIcon,
                            color:
                                isSelected
                                    ? Colors.white
                                    : AppColor.neutralGrey400,
                            size: 22,
                            key: ValueKey(isSelected),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
