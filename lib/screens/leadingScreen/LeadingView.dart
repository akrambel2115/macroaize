import 'package:flutter/material.dart';
import 'package:foodcalorietracker/constant/AppColor.dart';
import 'package:foodcalorietracker/routes/app_routes.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodView.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingView.dart';
import 'package:foodcalorietracker/screens/leadingScreen/ExitDailog.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingController.dart';
import 'package:get/get.dart';

class LeadingView extends GetView<LeadingController> {
  const LeadingView({super.key});

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
              return Container(
                height: 80 + MediaQuery.of(context).padding.bottom,
                decoration: BoxDecoration(
                  color: context.theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.lightShadow,
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        context, 
                        controller, 
                        0, 
                        Icons.dashboard_rounded, 
                        Icons.dashboard_outlined, 
                        'Home'.tr
                      ),
                      _buildNavItem(
                        context, 
                        controller, 
                        1, 
                        Icons.document_scanner_rounded, 
                        Icons.document_scanner_outlined, 
                        'Scanner'.tr
                      ),
                      _buildNavItem(
                        context, 
                        controller, 
                        2, 
                        Icons.insights_rounded, 
                        Icons.insights_outlined, 
                        'Analytics'.tr
                      ),
                      _buildNavItem(
                        context, 
                        controller, 
                        3, 
                        Icons.person_rounded, 
                        Icons.person_outline_rounded, 
                        'Settings'.tr
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          body: GetBuilder<LeadingController>(
            builder: (controller) {
              if (controller.currentIndex == 0) {
                return HomeView();
              } else if (controller.currentIndex == 1) {
                return ScanFoodView();
              } else if (controller.currentIndex == 2) {
                return  AnalyticsView();
              } else {
                return SettingView();
              }
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
    String label,
  ) {
    final isSelected = controller.currentIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.changeTabIndex(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? context.theme.focusColor.withOpacity(0.1)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected
                        ? context.theme.focusColor
                        : AppColor.neutralGrey500,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? context.theme.focusColor
                        : AppColor.neutralGrey500,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
