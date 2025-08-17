import 'dart:io';
import 'package:foodcalorietracker/constant/Appkey.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumController.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/CropperUiSettings.dart';

import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';
import '../../routes/app_routes.dart';

class ScanFoodController extends GetxController with WidgetsBindingObserver {
  CameraController? cameraController;
  // Default to snack(s) so the picker focuses on Snack by default
  String isIdentify = "snack(s)";
  File? imagePath;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _permissionDialogShown = false;

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
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
      await cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      update();
    } catch (e) {
      if (e is CameraException) {
        if (kDebugMode) {
          print("Camera error: ${e.description}");
          print("Error code: ${e.code}");
        }
        // If permission was denied, show a localized alert directing the
        // user to grant camera access from the device/app settings. Avoid
        // showing the same dialog repeatedly.
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
    if (cameraController == null || cameraController!.value.isInitialized == false) {
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
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Release camera when app goes to background or becomes inactive
      releaseCamera();
    }
    // On resume: we keep it lazy; it will be ensured when scanner becomes visible again
  }

  takeImage(ImageSource source, BuildContext context) async {
    XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      imagePath = File(image.path);
      update();
      await cropImage(imagePath, context);
    }
  }

  onTackImageCamera(BuildContext context) async {
    isLoading = true;
    update();
    // ensure camera is initialized before taking a picture
    if (cameraController == null || cameraController!.value.isInitialized == false) {
      await _ensureCameraReady();
      if (cameraController == null || cameraController!.value.isInitialized == false) {
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
        if(devBypassPremium){
          releaseCamera();
          // Development mode: ignore premium & limits
          Get.toNamed(
            Routes.scanCalorieView,
            arguments: {'image': image, 'type': isIdentify},
          );
        } else if(Get.find<PremiumController>().isPremium){
          releaseCamera();
          Get.toNamed(
            Routes.scanCalorieView,
            arguments: {'image': image, 'type': isIdentify},
          );
        } else {
          if(scanLimit==0){
            releaseCamera();
            Get.toNamed(Routes.premiumView);
          } else {
            scanLimit--;
            update();
            storeScanLimit();
            releaseCamera();
            Get.toNamed(
              Routes.scanCalorieView,
              arguments: {'image': image, 'type': isIdentify},
            );
          }
        }

      } else {
        isLoading = false;
        update();
      }
    }
  }
  storeScanLimit()
  async {
    SharedPref.saveInt(SharePrefKey.scanLimit, scanLimit);
    scanLimit = await SharedPref.readInt(SharePrefKey.scanLimit);
    update();
  }
  onChangeIdentify(String value) {
    isIdentify = value;
    update();
  }
}
