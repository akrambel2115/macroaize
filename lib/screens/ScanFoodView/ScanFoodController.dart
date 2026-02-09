import 'dart:io';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:macroaize/shared/services/barcode_scanning_service.dart';
import 'package:macroaize/shared/services/openfoodfacts_service.dart';
import 'package:macroaize/features/auth/presentation/auth_modal.dart';
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
  bool isBarcodeMode = false;
  bool isFlashOn = false;
  final ImagePicker _picker = ImagePicker();
  bool _permissionDialogShown = false;

  // services
  final _usageService = UsageService();
  final _appUserService = AppUserService();

  // barcode scanning
  BarcodeScanningService? _barcodeScanner;
  final _openFoodFactsService = OpenFoodFactsService();
  bool _isProcessingBarcode = false;

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
          } catch (_) {}
        }
      }
      // silent fail startup
      update();
    }
  }

  // init camera visible
  Future<void> ensureCameraActive() async {
    if (cameraController == null ||
        cameraController!.value.isInitialized == false) {
      await _ensureCameraReady();
    }

    // resume barcode scan
    if (isBarcodeMode && !_isProcessingBarcode) {
      await _startBarcodeScanning();
    }
  }

  // release camera resources
  void releaseCamera() {
    try {
      cameraController?.dispose();
    } catch (_) {}
    cameraController = null;
    update();
  }

  void toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized)
      return;

    isFlashOn = !isFlashOn;
    try {
      await cameraController!.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling flash: $e');
      }
      // revert on fail
      isFlashOn = !isFlashOn;
    }
    update();
  }

  bool isBarcodeOnly = false;

  void setBarcodeOnly(bool enabled) {
    isBarcodeOnly = enabled;
    if (enabled && !isBarcodeMode) {
      toggleBarcodeMode();
    } else if (!enabled && isBarcodeMode) {
      toggleBarcodeMode();
    }
    update();
  }

  void toggleBarcodeMode() async {
    isBarcodeMode = !isBarcodeMode;

    if (isBarcodeMode) {
      // init scanner
      _barcodeScanner = BarcodeScanningService();

      // start scanning
      await _startBarcodeScanning();

      // show notification
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            'barcode_activated'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.8),
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    } else {
      // stop scanning
      await _stopBarcodeScanning();

      // dispose scanner
      _barcodeScanner?.dispose();
      _barcodeScanner = null;

      // show notification
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            'barcode_deactivated'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.8),
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }

    update();
  }

  Future<void> _startBarcodeScanning() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      await cameraController!.startImageStream((CameraImage image) async {
        if (!isBarcodeMode || _isProcessingBarcode) return;

        final barcode = await _barcodeScanner?.scanBarcodeFromImage(image);

        if (barcode != null && barcode.isNotEmpty) {
          _isProcessingBarcode = true;
          await _handleBarcodeDetected(barcode);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error starting image stream: $e');
      }
    }
  }

  Future<void> _stopBarcodeScanning() async {
    if (cameraController != null && cameraController!.value.isStreamingImages) {
      try {
        await cameraController!.stopImageStream();
      } catch (e) {
        if (kDebugMode) {
          print('Error stopping image stream: $e');
        }
      }
    }
    _isProcessingBarcode = false;
  }

  Future<void> _handleBarcodeDetected(String barcode) async {
    try {
      // stop stream
      await _stopBarcodeScanning();

      // show loading
      isLoading = true;
      update();

      // fetch product
      final productData = await _openFoodFactsService.fetchProductByBarcode(
        barcode,
      );

      isLoading = false;
      update();

      if (productData != null) {
        // navigate results
        await _navigateToResults(productData);
      } else {
        // product not found
        NotificationService.showError('product_not_found');

        // restart scanning
        _isProcessingBarcode = false;
        if (isBarcodeMode) {
          await _startBarcodeScanning();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error handling barcode: $e');
      }
      isLoading = false;
      update();

      NotificationService.showError('error_fetching_product');

      // restart scanning
      _isProcessingBarcode = false;
      if (isBarcodeMode) {
        await _startBarcodeScanning();
      }
    }
  }

  Future<void> _navigateToResults(Map<String, dynamic> productData) async {
    // format food data
    final foodData = {
      'calorie': productData['calories']?.round() ?? 0,
      'protein': productData['protein'] ?? 0.0,
      'carbs': productData['carbs'] ?? 0.0,
      'fats': productData['fat'] ?? 0.0,
      'name': productData['name'] ?? 'Unknown Product',
      'quantity': productData['quantity'] ?? '100g',
    };

    // stop scanning
    await _stopBarcodeScanning();

    // release camera
    releaseCamera();

    update();

    // navigate results
    await Get.toNamed(
      Routes.scanCalorieView,
      arguments: {
        'name': foodData['name'],
        'calorie': foodData['calorie'],
        'protein': foodData['protein'],
        'carbs': foodData['carbs'],
        'fats': foodData['fats'],
        'quantity': foodData['quantity'],
        'isIdentify': isIdentify,
        'fromBarcode': true,
        'netWeight': productData['product_quantity'],
        'unit': productData['product_quantity_unit'],
      },
    );

    // reinit camera
    await ensureCameraActive();

    // reset flag
    _isProcessingBarcode = false;
  }

  @override
  void onClose() {
    _stopBarcodeScanning();
    _barcodeScanner?.dispose();
    cameraController?.dispose();
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // release on background
      releaseCamera();
    }
  }

  takeImage(ImageSource source, BuildContext context) async {
    if (!_appUserService.checkAccountActivation('scanner')) return;

    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      imagePath = File(image.path);
      update();
      if (!context.mounted) return;
      await cropImage(imagePath, context);
    }
  }

  onTackImageCamera(BuildContext context) async {
    // check activation
    if (!_appUserService.checkAccountActivation('scanner')) {
      return;
    }

    isLoading = true;
    update();
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
    if (!context.mounted) return;
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
          // check usage limit
          final result = await _usageService.incrementUsage('scan');

          if (result.success) {
            // proceed scan
            releaseCamera();
            Get.toNamed(
              Routes.scanCalorieView,
              arguments: {'image': image, 'type': isIdentify},
            );
          } else {
            // limit reached
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
            // prompt login
            releaseCamera();
            await _handleAuthenticationRequired();
            return;
          }

          final el = e.toString().toLowerCase();
          if (el.contains('limit') ||
              el.contains('permission-denied') ||
              (el.contains('daily') && el.contains('limit'))) {
            // limit error
            releaseCamera();
            NotificationService.showError('daily_limit_reached_try_again');
            return;
          }

          // other error
          releaseCamera();
          NotificationService.showError('unable_to_process_scan_try_again');
        }

        isLoading = false;
        update();
      }
    }
  }

  Future<void> _handleAuthenticationRequired() async {
    final success = await AuthModal.show();

    if (success) {
      Get.snackbar(
        'success'.tr,
        'auth_scan_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'auth_scan_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  onChangeIdentify(String value) {
    isIdentify = value;
    update();
  }
}
