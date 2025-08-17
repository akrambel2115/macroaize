import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodController.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingView.dart';
import 'package:foodcalorietracker/screens/leadingScreen/ExitDailog.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingController.dart';
import 'package:get/get.dart';

class LeadingView extends StatefulWidget {
  const LeadingView({super.key});

  @override
  State<LeadingView> createState() => _LeadingViewState();
}

class _LeadingViewState extends State<LeadingView> {
  final LeadingController _controller = Get.find();
  int _localIndex = 0;
  int _prevIndex = 0;
  // indicator now only moves horizontally; no stretching state needed
  final GlobalKey _stackKey = GlobalKey();
  double _indicatorWidth = 48.0;
  // indicator position is computed from layout (slot-based) to avoid measuring and jank
  // Lazy pages: build tabs only when first visited to avoid early permission prompts
  final List<Widget?> _pages = [
    const HomeView(),
    null, // ScanFoodView (camera) — build on demand
    null, // AnalyticsView — build on demand
    null, // SettingView — build on demand
  ];
  // icons are passed inline to _buildNavItem; no persistent list needed

  @override
  void initState() {
    super.initState();
  _localIndex = _controller.currentIndex;
  // initialize index from controller
  _ensurePage(_localIndex);
  }

  void _animateTo(int newIndex) {
    if (!mounted) return;
    final oldIndex = _localIndex;
    // update index; indicator position is computed in the LayoutBuilder for smooth animation
    setState(() {
      _localIndex = newIndex;
    });
    // ensure destination page is created lazily
    _ensurePage(newIndex);
    // manage camera lifecycle when switching in/out of scanner tab
    _handleScannerLifecycle(oldIndex, newIndex);
    _prevIndex = newIndex;
  }

  void _handleScannerLifecycle(int oldIndex, int newIndex) {
    // If leaving scanner (1) -> release camera
    if (oldIndex == 1 && newIndex != 1) {
      try {
        final c = Get.isRegistered<ScanFoodController>() ? Get.find<ScanFoodController>() : null;
        c?.releaseCamera();
      } catch (_) {}
    }
    // If entering scanner -> ensure camera active
    if (newIndex == 1) {
      try {
        final c = Get.isRegistered<ScanFoodController>() ? Get.find<ScanFoodController>() : null;
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
        _pages[1] = const ScanFoodView();
        break;
      case 2:
        _pages[2] = const AnalyticsView();
        break;
      case 3:
        _pages[3] = const SettingView();
        break;
    }
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showExitConfirmationDialog(context: context);
        return Future(() => true,);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: GetBuilder<LeadingController>(
          builder: (controller) {
            // Hide chat button when scanner is active for distraction-free experience
            if (controller.currentIndex == 1) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton(
              onPressed: () {
                Get.toNamed(Routes.chatView);
              },
              backgroundColor: context.theme.focusColor,
              shape: const CircleBorder(),
              elevation: 6,
              child: Icon(
                Icons.chat_rounded,
                color: context.theme.scaffoldBackgroundColor,
                size: 28,
              ),
            );
          },
        ),
          bottomNavigationBar: GetBuilder<LeadingController>(
            builder: (controller) {
              // detect external index changes and trigger animation sequence
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_localIndex != controller.currentIndex) {
                  _animateTo(controller.currentIndex);
                }
              });
              return Container(
                // adjusted height to avoid bottom overflow (add small buffer)
                height: 76 + MediaQuery.of(context).padding.bottom,
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                    // slightly smaller vertical padding to fit icons comfortably
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: LayoutBuilder(builder: (context, constraints) {
                      // compute indicator position using layout slots to avoid measuring
                      final navCount = 4;
                      final slotWidth = constraints.maxWidth / navCount;
                      final centerX = slotWidth * _localIndex + slotWidth / 2;
                      final left = centerX - _indicatorWidth / 2;
                      final top = constraints.maxHeight / 2 - _indicatorWidth / 2;

                      return Stack(
                        key: _stackKey,
                        children: [
                          // animated positioned indicator (pixel-perfect)
                          AnimatedPositioned(
                            // shorter, smooth movement
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            left: left,
                            top: top,
                            width: _indicatorWidth,
                            height: _indicatorWidth,
                            child: AnimatedContainer(
                              // minimal decoration animation
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                color: AppColor.primaryOrange,
                                // fixed rounded circle so the indicator doesn't change shape
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primaryOrange.withOpacity(0.28),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                            ),
                          ),

                          // actual nav row (icons only)
                          Row(
                            children: [
                              Expanded(child: _buildNavItem(context, controller, 0, Icons.home_filled, Icons.home_outlined)),
                              Expanded(child: _buildNavItem(context, controller, 1, Icons.qr_code_scanner, Icons.qr_code)),
                              Expanded(child: _buildNavItem(context, controller, 2, Icons.bar_chart_rounded, Icons.bar_chart_outlined)),
                              Expanded(child: _buildNavItem(context, controller, 3, Icons.person_rounded, Icons.person_outline_rounded)),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),

          body: GetBuilder<LeadingController>(
            builder: (controller) {
              // Use IndexedStack with lazy pages to avoid early camera/mic initialization
              final children = List<Widget>.generate(
                4,
                (i) => _pages[i] ?? const SizedBox.shrink(),
              );
              return IndexedStack(
                index: controller.currentIndex,
                children: children,
              );
            },
          )),
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
    
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Bottom navigation item $index',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.changeTabIndex(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular icon container (icon-only layout)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedSwitcher(
                      // shorter icon switch for snappier feedback
                      duration: const Duration(milliseconds: 120),
                      child: Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        color: isSelected ? Colors.white : AppColor.neutralGrey400,
                        size: 22,
                        key: ValueKey(isSelected),
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
