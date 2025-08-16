import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Returns platform-specific UI settings for ImageCropper.
///
/// This helper centralizes cropper styling so we can keep the toolbar
/// minimal (no text title/background) and only surface the native icons.
List<PlatformUiSettings> cropperUiSettings(BuildContext context) {
  // We want the crop toolbar to have no background and white icons to match the
  // gallery icon style used in the scanner. Native cropper toolbars are
  // implemented by platform widgets, so we can only tint icons and remove the
  // toolbar background here. For fully custom icon shapes (circular backgrounds)
  // a custom overlay would be required.
  final toolbarWidgetColor = Colors.white;

  return [
    AndroidUiSettings(
      toolbarTitle: '', // no title text
      // Use a dark toolbar so the white icons are visible and the bar isn't white.
      // Fully transparent toolbars are not reliably supported by the native
      // crop UI on all Android versions/themes, so a dark bar provides a
      // consistent result matching the scanner UI.
      toolbarColor: Colors.black,
      toolbarWidgetColor: toolbarWidgetColor, // tint native toolbar icons (white)
      initAspectRatio: CropAspectRatioPreset.original,
      lockAspectRatio: false,
      hideBottomControls: false,
      statusBarColor: Colors.black,
    ),
    IOSUiSettings(
      title: '', // no title text on iOS
      // Use symbol characters so the toolbar shows compact icons instead of text.
      doneButtonTitle: '✓',
      cancelButtonTitle: '✕',
    ) as PlatformUiSettings,
  ];
}
