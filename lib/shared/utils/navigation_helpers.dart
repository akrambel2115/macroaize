import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// iOS-safe navigation helpers.
///
/// On iOS, [Get.back] can fail silently when the underlying route uses
/// `PopScope(canPop: false)` because the GetX overlay-context may refer to a
/// navigator whose pop is blocked.  By resolving through
/// [Get.overlayContext] first we talk to the *overlay* navigator (which
/// always allows pops for dialogs / bottom-sheets), falling back to
/// [Get.back] only when no overlay context is available.
///
/// See also:
/// * `possible_issues.md §3` – Popup Buttons / Dialogs Unresponsive on iOS.

/// Safely pops the topmost dialog, bottom-sheet or route.
///
/// Prefer this over [Get.back] inside any callback that dismisses a popup
/// opened via `Get.dialog` / `Get.bottomSheet`.
void safeBack<T>({T? result}) {
  final ctx = Get.overlayContext;
  if (ctx != null && Navigator.of(ctx).canPop()) {
    Navigator.of(ctx).pop(result);
  } else {
    Get.back(result: result);
  }
}

/// Safely pops a dialog then immediately navigates to [route].
///
/// Useful when a dialog action needs to dismiss itself and open a new
/// screen in the same gesture.
void safeBackAndNavigate(String route, {dynamic arguments}) {
  safeBack();
  Get.toNamed(route, arguments: arguments);
}
