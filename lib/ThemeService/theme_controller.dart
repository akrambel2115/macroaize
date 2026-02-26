import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../SharePrefHelper/share_pref.dart';
import '../SharePrefHelper/share_pref_key.dart';
import 'app_theme.dart';


class ThemeController extends GetxController {

  bool isDarkMode = true;

  @override
  void onInit() {
    super.onInit();
    getThemeMode();
  }

  /// Load or determine the theme, persist first-run choice, and apply UI overlays
  getThemeMode() async {
    final bool? stored = await SharedPref.readBool(SharePrefKey.isDarkMode);
    if (stored == null) {
      // First launch: default to light mode regardless of device preference.
      // The user can change this on the theme-choice onboarding screen.
      isDarkMode = false;
      await SharedPref.saveBool(SharePrefKey.isDarkMode, isDarkMode);
    } else {
      isDarkMode = stored;
    }

    Get.changeTheme(isDarkMode ? AppTheme.dark : AppTheme.light);
    final bg = isDarkMode ? AppTheme.dark.scaffoldBackgroundColor : AppTheme.light.scaffoldBackgroundColor;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: bg,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: bg,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    Get.forceAppUpdate();
    update();
  }

  Future<void> toggleTheme(bool value) async {
    await SharedPref.saveBool(SharePrefKey.isDarkMode, value);
    getThemeMode();
    update();
  }

}