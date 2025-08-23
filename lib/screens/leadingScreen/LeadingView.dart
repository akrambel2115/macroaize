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
  const LeadingView({super.key});

  @override
  State<LeadingView> createState() => _LeadingViewState();
}

class _LeadingViewState extends State<LeadingView> {
  final LeadingController _controller = Get.find();
  int _localIndex = 0;
  // indicator now only moves horizontally; no stretching state needed
  final GlobalKey _stackKey = GlobalKey();
  final double _indicatorWidth = 48.0;
  // indicator position is computed from layout (slot-based) to avoid measuring and jank
  // Lazy pages: build tabs only when first visited to avoid early permission prompts
  final List<Widget?> _pages = [
    const HomeView(),
  null, // RecipesView — build on demand
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
  }

  void _handleScannerLifecycle(int oldIndex, int newIndex) {
  // If leaving scanner (2) -> release camera
  if (oldIndex == 2 && newIndex != 2) {
      try {
        final c = Get.isRegistered<ScanFoodController>() ? Get.find<ScanFoodController>() : null;
        c?.releaseCamera();
      } catch (_) {}
    }
  // If entering scanner (2) -> ensure camera active
  if (newIndex == 2) {
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
        return Future(() => true,);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: GetBuilder<LeadingController>(
          builder: (controller) {
            // Hide chat button when scanner is active for distraction-free experience
            if (controller.currentIndex == 2) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton(
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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
              // detect external index changes and trigger animation sequence
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_localIndex != controller.currentIndex) {
                  _animateTo(controller.currentIndex);
                }
              });
              return Container(
                // standard bottom nav height (reverted) — camera will sit inline with other icons
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
                    // reverted vertical padding to original value
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: LayoutBuilder(builder: (context, constraints) {
                      // compute indicator position using layout slots to avoid measuring
                      final navCount = 5;
                      final slotWidth = constraints.maxWidth / navCount;
                      // On RTL layouts the Row paints children right-to-left, so
                      // map the logical index to the visual slot index. This keeps
                      // the floating indicator aligned with the painted nav item
                      // and ensures taps/select state remain consistent in RTL.
                      final isRtl = Directionality.of(context) == TextDirection.rtl;
                      final visualIndex = isRtl ? (navCount - 1 - _localIndex) : _localIndex;
                      final centerX = slotWidth * visualIndex + slotWidth / 2;
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
                              Expanded(child: _buildNavItem(context, controller, 1, Icons.restaurant_menu_rounded, Icons.restaurant_menu_outlined)),
                              Expanded(child: _buildNavItem(context, controller, 2, Icons.camera_alt_rounded, Icons.camera_alt_outlined)),
                              Expanded(child: _buildNavItem(context, controller, 3, Icons.bar_chart_rounded, Icons.bar_chart_outlined)),
                              Expanded(child: _buildNavItem(context, controller, 4, Icons.person_rounded, Icons.person_outline_rounded)),
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
                5,
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
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  final navCount = 5;
  final visualIndex = isRtl ? (navCount - 1 - index) : index;
    
    return Expanded(
      child: Semantics(
        button: true,
        // Use visualIndex for the spoken label so screen readers match
        // the visual ordering in RTL locales.
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
                // Circular icon container (icon-only layout)
                  Builder(builder: (context) {
                  final isCamera = index == 2;
                  if (isCamera) {
                    // Camera uses a custom asset (scan icon) and sits inline with other icons
                    return SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          child: Image.asset(
                            AppAssets.scanHomeIcon,
                            // preserve original asset colors (do not tint)
                            width: 22,
                            height: 22,
                            key: ValueKey(isSelected),
                          ),
                        ),
                      ),
                    );
                  }

                  // Default small icon for other nav items
                  return SizedBox(
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
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
