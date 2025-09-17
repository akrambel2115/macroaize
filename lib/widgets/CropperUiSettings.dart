import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Platform-specific UI settings for the image cropper.
List<PlatformUiSettings> cropperUiSettings(BuildContext context) {
  final toolbarWidgetColor = Colors.white;

  return [
    AndroidUiSettings(
      toolbarTitle: '',
      toolbarColor: Colors.black,
      toolbarWidgetColor: toolbarWidgetColor,
      initAspectRatio: CropAspectRatioPreset.original,
      lockAspectRatio: false,
      hideBottomControls: false,
      statusBarColor: Colors.black,
    ),
    IOSUiSettings(
      title: '',
      doneButtonTitle: '✓',
      cancelButtonTitle: '✕',
    ) as PlatformUiSettings,
  ];
}
