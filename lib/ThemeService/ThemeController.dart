import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../SharePrefHelper/SharePref.dart';
import '../SharePrefHelper/SharePrefKey.dart';
import 'AppTheme.dart';


/// Controller for app theme and system UI overlays
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
      final Brightness platformBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = platformBrightness == Brightness.dark;
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