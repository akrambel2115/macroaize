import 'dart:io';
import 'dart:async';
import 'package:macroaize/shared/services/usage_service.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:macroaize/shared/services/openfoodfacts_service.dart';
import 'package:macroaize/features/auth/presentation/auth_modal.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/cropper_ui_settings.dart';
import '../../routes/app_routes.dart';
import '../../shared/utils/navigation_helpers.dart';

class ScanFoodController extends GetxController with WidgetsBindingObserver {
  // ── Photo-mode camera (camera package) ──────────────────────────
  CameraController? cameraController;

  // ── Barcode-mode camera (mobile_scanner) ────────────────────────
  MobileScannerController? mobileScannerController;

  String isIdentify = "snack(s)";
  File? imagePath;
  bool isLoading = false;
  bool isBarcodeMode = false;
  bool isBarcodeOnly = false;
  bool isFlashOn = false;
  final ImagePicker _picker = ImagePicker();
  bool _permissionDialogShown = false;

  // services
  final _usageService = UsageService();
  final _appUserService = AppUserService();

  // barcode
  final _openFoodFactsService = OpenFoodFactsService();
  bool _isProcessingBarcode = false;
  StreamSubscription? _usageSubscription;

  // usage getters
  int get remainingScans => (_usageService.scanLimit - _usageService.scanCount)
      .clamp(0, _usageService.scanLimit);
  int get totalScanLimit => _usageService.scanLimit;
  bool get isPremiumUser => _usageService.isPremium;

  void navigateToPremium() {
    Get.toNamed(Routes.premiumView);
  }

  // ─── Lifecycle ──────────────────────────────────────────────────

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    try {
      await _usageService.getUsage();
    } catch (_) {}
    update();

    _usageSubscription?.cancel();
    _usageSubscription = _usageService.usageStream.listen((_) {
      if (!isClosed) update();
    });

    // Don't init camera here — it will be started when the tab is shown
    // via ensureCameraActive().
  }

  @override
  void onClose() {
    _usageSubscription?.cancel();
    _disposeMobileScanner();
    cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      releaseCamera();
    }
  }

  // ─── Camera activation / release ────────────────────────────────

  Future<void> ensureCameraActive() async {
    if (isBarcodeMode) {
      // Barcode mode → use mobile_scanner
      _disposePhotoCamera();
      _ensureMobileScannerReady();
    } else {
      // Photo mode → use camera package
      _disposeMobileScanner();
      if (cameraController == null ||
          !cameraController!.value.isInitialized) {
        await _ensurePhotoCameraReady();
      }
    }
    update();
  }

  void releaseCamera() {
    _disposeMobileScanner();
    _disposePhotoCamera();
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    update();
  }

  // ─── Photo camera (camera package) ──────────────────────────────

  Future<void> _ensurePhotoCameraReady() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (kDebugMode) print('[PhotoCam] No cameras available');
        update();
        return;
      }
      cameraController = CameraController(cams[0], ResolutionPreset.high);
      await cameraController!.initialize();
      await cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );
      update();
    } catch (e) {
      if (e is CameraException) {
        if (kDebugMode) {
          print("[PhotoCam] error: ${e.description} (${e.code})");
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
                      safeBack();
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
      update();
    }
  }

  void _disposePhotoCamera() {
    try {
      cameraController?.dispose();
    } catch (_) {}
    cameraController = null;
  }

  // ─── Barcode scanner (mobile_scanner) ───────────────────────────

  void _ensureMobileScannerReady() {
    if (mobileScannerController != null) return;
    mobileScannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true,
      returnImage: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
        BarcodeFormat.aztec,
      ],
    );
    _isProcessingBarcode = false;
    update();
  }

  void _disposeMobileScanner() {
    try {
      mobileScannerController?.dispose();
    } catch (_) {}
    mobileScannerController = null;
    _isProcessingBarcode = false;
  }

  /// Called by the MobileScanner widget's onDetect callback.
  void onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessingBarcode || isLoading) return;

    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final value = codes.first.rawValue;
    if (value == null || value.isEmpty) return;

    if (kDebugMode) {
      print('[Barcode] Detected: $value (${codes.first.format.name})');
    }

    _isProcessingBarcode = true;
    _handleBarcodeDetected(value);
  }

  // ─── Mode switching ─────────────────────────────────────────────

  /// Called from [LeadingView] BEFORE the tab switches.
  void setBarcodeOnly(bool enabled) {
    isBarcodeOnly = enabled;
    isBarcodeMode = enabled;
    // Actual camera start is deferred to ensureCameraActive().
    update();
  }

  void toggleBarcodeMode() async {
    isBarcodeMode = !isBarcodeMode;

    if (isBarcodeMode) {
      _disposePhotoCamera();
      _ensureMobileScannerReady();
      NotificationService.showInfo('barcode_activated'.tr);
    } else {
      _disposeMobileScanner();
      await _ensurePhotoCameraReady();
      NotificationService.showInfo('barcode_deactivated'.tr);
    }
    update();
  }

  void toggleFlash() async {
    isFlashOn = !isFlashOn;
    try {
      if (isBarcodeMode && mobileScannerController != null) {
        await mobileScannerController!.toggleTorch();
      } else if (cameraController != null &&
          cameraController!.value.isInitialized) {
        await cameraController!.setFlashMode(
          isFlashOn ? FlashMode.torch : FlashMode.off,
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling flash: $e');
      isFlashOn = !isFlashOn;
    }
    update();
  }

  // ─── Barcode handling ───────────────────────────────────────────

  Future<void> _handleBarcodeDetected(String barcode) async {
    try {
      // Pause the scanner while we look up the product.
      try {
        await mobileScannerController?.stop();
      } catch (_) {}

      isLoading = true;
      update();

      final productData =
          await _openFoodFactsService.fetchProductByBarcode(barcode);

      isLoading = false;
      update();

      if (productData != null) {
        await _navigateToResults(productData);
      } else {
        NotificationService.showError('product_not_found');
        _isProcessingBarcode = false;
        // Resume scanning.
        try {
          await mobileScannerController?.start();
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) print('[Barcode] Error handling barcode: $e');
      isLoading = false;
      update();
      NotificationService.showError('error_fetching_product');
      _isProcessingBarcode = false;
      try {
        await mobileScannerController?.start();
      } catch (_) {}
    }
  }

  Future<void> _navigateToResults(Map<String, dynamic> productData) async {
    final foodData = {
      'calorie': productData['calories']?.round() ?? 0,
      'protein': productData['protein'] ?? 0.0,
      'carbs': productData['carbs'] ?? 0.0,
      'fats': productData['fat'] ?? 0.0,
      'name': productData['name'] ?? 'Unknown Product',
      'quantity': productData['quantity'] ?? '100g',
    };

    releaseCamera();
    update();

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

    if (isClosed) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;

    await ensureCameraActive();
    _isProcessingBarcode = false;
  }

  // ─── Photo capture (unchanged logic) ────────────────────────────

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
    if (!_appUserService.checkAccountActivation('scanner')) return;

    isLoading = true;
    update();

    if (cameraController == null ||
        !cameraController!.value.isInitialized) {
      await _ensurePhotoCameraReady();
      if (cameraController == null ||
          !cameraController!.value.isInitialized) {
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
        compressQuality: 70,
        maxWidth: 768,
        maxHeight: 768,
        uiSettings: cropperUiSettings(context),
      );

      if (croppedFile != null) {
        File image = File(croppedFile.path);

        isLoading = true;
        update();

        try {
          final result = await _usageService.incrementUsage('scan');

          if (result.success) {
            releaseCamera();
            await Get.toNamed(
              Routes.scanCalorieView,
              arguments: {'image': image, 'type': isIdentify},
            );

            if (isClosed) return;
            isLoading = false;
            update();

            await Future.delayed(const Duration(milliseconds: 500));
            if (isClosed) return;
            await ensureCameraActive();
          } else {
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
            releaseCamera();
            await _handleAuthenticationRequired();
            return;
          }

          final el = e.toString().toLowerCase();
          if (el.contains('limit') ||
              el.contains('permission-denied') ||
              (el.contains('daily') && el.contains('limit'))) {
            releaseCamera();
            NotificationService.showError('daily_limit_reached_try_again');
            return;
          }

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
      NotificationService.showSuccess('auth_scan_success');
      Get.offAllNamed(Routes.leadingView);
    } else {
      NotificationService.showError('auth_scan_required');
    }
  }

  onChangeIdentify(String value) {
    isIdentify = value;
    update();
  }
}
