import 'dart:io';
import 'package:foodcalorietracker/shared/services/usage_service.dart';
import 'package:foodcalorietracker/shared/services/notification_service.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/CropperUiSettings.dart';
import '../../routes/app_routes.dart';

class ScanFoodController extends GetxController with WidgetsBindingObserver {
  CameraController? cameraController;
  String isIdentify = "snack(s)";
  File? imagePath;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _permissionDialogShown = false;

  // Add usage service and app user service
  final _usageService = UsageService();
  final _appUserService = AppUserService();

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    await _ensureCameraReady();
  }

  Future<void> _ensureCameraReady() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (kDebugMode) print('No cameras available');
        update();
        return;
      }

      cameraController = CameraController(cams[0], ResolutionPreset.max);
      await cameraController!.initialize();
      await cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
      update();
    } catch (e) {
      if (e is CameraException) {
        if (kDebugMode) {
          print("Camera error: ${e.description}");
          print("Error code: ${e.code}");
        }
        if (e.code == 'CameraAccessDenied' && !_permissionDialogShown) {
          _permissionDialogShown = true;
          try {
            Get.dialog(
              AlertDialog(
                backgroundColor: Colors.black,
                title: Text(
                  'camera_permission_denied_title'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
                content: Text(
                  'camera_permission_denied_message'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _permissionDialogShown = false;
                      Get.back();
                    },
                    child: Text('ok'.tr),
                  ),
                ],
              ),
              barrierDismissible: true,
            );
          } catch (_) {
            // Ignore any dialog errors
          }
        }
      }
      // Swallow errors to avoid forcing permission at startup
      update();
    }
  }

  // Public: ensure camera is initialized when scanner becomes visible again
  Future<void> ensureCameraActive() async {
    if (cameraController == null ||
        cameraController!.value.isInitialized == false) {
      await _ensureCameraReady();
    }
  }

  // Public: release camera resources when scanner is not visible
  void releaseCamera() {
    try {
      cameraController?.dispose();
    } catch (_) {}
    cameraController = null;
    update();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Release camera when app goes to background or becomes inactive
      releaseCamera();
    }
    // On resume: we keep it lazy; it will be ensured when scanner becomes visible again
  }

  takeImage(ImageSource source, BuildContext context) async {
    if (!_appUserService.checkAccountActivation('scanner')) return;

    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      imagePath = File(image.path);
      update();
      await cropImage(imagePath, context);
    }
  }

  onTackImageCamera(BuildContext context) async {
    // ACCOUNT ACTIVATION GATING: Check if account is activated before allowing scan
    if (!_appUserService.checkAccountActivation('scanner')) {
      return;
    }

    isLoading = true;
    update();
    if (cameraController == null || cameraController!.value.isInitialized == false) {
      await _ensureCameraReady();
      if (cameraController == null || cameraController!.value.isInitialized == false) {
        isLoading = false;
        update();
        return;
      }
    }
    if (cameraController == null ||
        cameraController!.value.isInitialized == false) {
      await _ensureCameraReady();
      if (cameraController == null ||
          cameraController!.value.isInitialized == false) {
        isLoading = false;
        update();
        return;
      }
    }
    XFile imageFile = await cameraController!.takePicture();
    File originalFile = File(imageFile.path);
    cropImage(originalFile, context);
  }

  Future<void> cropImage(final image, BuildContext context) async {
    isLoading = false;
    update();

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: cropperUiSettings(context),
      );

      if (croppedFile != null) {
        File image = File(croppedFile.path);

      isLoading = true;
      update();
        isLoading = true;
        update();

        try {
          // Call backend to check and increment usage
          final result = await _usageService.incrementUsage('scan');

          if (result.success) {
            // Usage allowed - proceed with scan
            releaseCamera();
            Get.toNamed(
              Routes.scanCalorieView,
              arguments: {'image': image, 'type': isIdentify},
            );
          } else {
            // Usage limit reached - show premium dialog
            releaseCamera();
            NotificationService.showError(
              result.message.isNotEmpty
                  ? result.message
                  : 'daily_scan_limit_reached',
            );
          }
        } catch (e) {
          isLoading = false;
          update();

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            // User not authenticated - prompt to login
            releaseCamera();
            await _handleAuthenticationRequired();
            return;
          }

          final el = e.toString().toLowerCase();
          if (el.contains('limit') ||
              el.contains('permission-denied') ||
              (el.contains('daily') && el.contains('limit'))) {
            // Limit-related error -> centralized friendly notification
            releaseCamera();
            NotificationService.showError('daily_limit_reached_try_again');
            return;
          }

          // Other error
          releaseCamera();
          NotificationService.showError('unable_to_process_scan_try_again');
        }

        isLoading = false;
        update();
      }
    }
  }

  // usage limit dialog replaced by NotificationService.showError

  Future<void> _handleAuthenticationRequired() async {
    final success = await AuthModal.show();

    if (success) {
      Get.snackbar(
        'Welcome!',
        'You can now use the scanner. Please try scanning again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Authentication Required',
        'Please login to use the scanner feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // scanLimit persistence removed; limits are enforced on backend via UsageService

  onChangeIdentify(String value) {
    isIdentify = value;
    update();
  }
}
