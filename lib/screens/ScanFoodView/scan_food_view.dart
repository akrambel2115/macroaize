import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:macroaize/constant/app_color.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_controller.dart';
import 'package:macroaize/widgets/modern_animations.dart';
import 'package:macroaize/widgets/continue_button.dart';
import 'package:macroaize/widgets/scanner_overlay.dart';
import 'package:macroaize/widgets/bottom_mode_picker.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constant/app_assets.dart';

import 'package:macroaize/screens/leadingScreen/leading_controller.dart';

class ScanFoodView extends GetView<ScanFoodController> {
  const ScanFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GetBuilder<ScanFoodController>(
          builder: (controller) {
            final meals = ['BreakFast', 'Lunch', 'snack(s)', 'Dinner'];

            return Stack(
              children: [
                // camera preview
                if (controller.cameraController?.value.isInitialized == true)
                  Positioned.fill(
                    child: CameraPreview(controller.cameraController!),
                  ),

                // scanner overlay
                Positioned.fill(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // trigger camera permission
                        if (controller.cameraController?.value.isInitialized !=
                            true) {
                          controller.ensureCameraActive();
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ScannerOverlay(
                            width: 300,
                            height: 260,
                            borderRadius: 36,
                            hintText:
                                controller.isBarcodeOnly
                                    ? 'scan_barcode_hint'.tr
                                    : null,
                          ),
                          if (controller
                                  .cameraController
                                  ?.value
                                  .isInitialized !=
                              true)
                            Container(
                              width: 300,
                              height: 260,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_camera_outlined,
                                    color: Colors.white70,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'grant_camera_access_in_scanner'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // flash toggle
                // Back Button (Top Left)
                if (!controller.isLoading)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () {
                        try {
                          if (Get.isRegistered<LeadingController>()) {
                            Get.find<LeadingController>().changeTabIndex(0);
                          } else {
                            Get.back();
                          }
                        } catch (_) {
                          Get.back();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // barcode toggle
                // Flash Toggle (Top Right)
                if (!controller.isLoading)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: controller.toggleFlash,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              controller.isFlashOn
                                  ? AppColor.primaryOrange
                                  : Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                controller.isFlashOn
                                    ? AppColor.primaryOrange
                                    : Colors.white.withValues(alpha: 0.14),
                            width: controller.isFlashOn ? 2 : 1,
                          ),
                          boxShadow:
                              controller.isFlashOn
                                  ? [
                                    BoxShadow(
                                      color: AppColor.primaryOrange.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Icon(
                          controller.isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                // bottom controls
                if (!controller.isLoading && !controller.isBarcodeOnly)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // control buttons
                        _buildControlButtons(context, controller),
                        const SizedBox(height: 6),
                        // meal picker
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: BottomModePicker(
                            items: meals,
                            currentIndex: meals.indexOf(controller.isIdentify),
                            onChanged:
                                (idx) =>
                                    controller.onChangeIdentify(meals[idx]),
                            height: 42,
                          ),
                        ),
                      ],
                    ),
                  ),

                // loading overlay
                if (controller.isLoading) _buildLoadingOverlay(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    ScanFoodController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // gallery button
        _buildIconControlButton(
          context,
          icon: Icons.photo_library_outlined,
          onTap: () => controller.takeImage(ImageSource.gallery, context),
        ),

        // capture button
        GestureDetector(
          onTap: () => controller.onTackImageCamera(context),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColor.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColor.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // tips button
        _buildIconControlButton(
          context,
          icon: Icons.lightbulb_outline,
          onTap: () => showInfo(context),
        ),
      ],
    );
  }

  Widget _buildIconControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: iconSize)),
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernLoadingIndicator(size: 48, color: AppColor.primaryOrange),
              const SizedBox(height: 16),
              Text(
                'Analyzing food...',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.grey[900]!],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // title
                  Text(
                    'Snap Tips'.tr,
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // good example
                  _buildTipExample(
                    context,
                    AppAssets.scanComplete,
                    'Perfect Shot'.tr,
                    'Well-lit, centered food'.tr,
                    AppColor.success,
                    Icons.check_circle,
                  ),

                  const SizedBox(height: 24),

                  // bad examples
                  Row(
                    children: [
                      Expanded(
                        child: _buildTipExample(
                          context,
                          AppAssets.soClose,
                          'Too close'.tr,
                          'Move camera back'.tr,
                          AppColor.error,
                          Icons.cancel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTipExample(
                          context,
                          AppAssets.soFar,
                          'Too far'.tr,
                          'Move camera closer'.tr,
                          AppColor.error,
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // continue button
                  ContinueButton(onTap: () => Get.back()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipExample(
    BuildContext context,
    String imagePath,
    String title,
    String subtitle,
    Color color,
    IconData statusIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
