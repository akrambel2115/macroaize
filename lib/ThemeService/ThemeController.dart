import 'package:get/get.dart';
import '../SharePrefHelper/SharePref.dart';
import '../SharePrefHelper/SharePrefKey.dart';
import 'AppTheme.dart';


class ThemeController extends GetxController{

  bool isDarkMode = true;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getThemeMode();
  }
  getThemeMode()
  async {
    isDarkMode = await SharedPref.readBool(SharePrefKey.isDarkMode) ?? true;
    Get.changeTheme(isDarkMode ? AppTheme.dark : AppTheme.light);
    Get.forceAppUpdate();
    update();
  }

  Future<void> toggleTheme(bool value) async {
    await SharedPref.saveBool(SharePrefKey.isDarkMode, value);
    getThemeMode();
    update();
  }


}