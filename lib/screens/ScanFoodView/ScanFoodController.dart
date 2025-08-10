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

import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';
import '../../main.dart';
import '../../routes/app_routes.dart';

class ScanFoodController extends GetxController {
  late CameraController cameraController;
  String isIdentify = "BreakFast";
  File? imagePath;
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();

    cameraController = CameraController(cameras[0], ResolutionPreset.max);

    try {
      await cameraController.initialize(); // Wait for initialization
      await cameraController.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      ); // Now it's safe
      update();
    } catch (e) {
      if (e is CameraException) {
        if (kDebugMode) {
          print("Camera error: ${e.description}");
          print("Error code: ${e.code}");
        }

        if (e.code == 'CameraAccessDenied') {
          // Handle permission denial
        } else {
          // Handle other errors
        }
      }
    }
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    cameraController.dispose();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
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
    XFile imageFile = await cameraController.takePicture();
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
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper'.tr,
            toolbarColor: context.theme.focusColor,
            toolbarWidgetColor: context.theme.hintColor,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Cropper'.tr),
        ],
      );
      if (croppedFile != null) {
        File image = File(croppedFile.path);
        if(devBypassPremium){
          // Development mode: ignore premium & limits
          Get.toNamed(
            Routes.scanCalorieView,
            arguments: {'image': image, 'type': isIdentify},
          );
        } else if(Get.find<PremiumController>().isPremium){
          Get.toNamed(
            Routes.scanCalorieView,
            arguments: {'image': image, 'type': isIdentify},
          );
        } else {
          if(scanLimit==0){
            Get.toNamed(Routes.premiumView);
          } else {
            scanLimit--;
            update();
            storeScanLimit();
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
