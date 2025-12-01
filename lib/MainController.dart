import 'dart:ui';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController extends GetxController {
  String countryCode = "";
  String languageCode = "";
  // translation key for the language
  String languageKey = "";
  // localized display for UI
  String language = "";
  bool isLogin = false;
  bool needsEmailVerification = false;
  @override
  void onInit() {
    super.onInit();
    getData();
    getLanguageCode();
  }

  getLanguageCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    languageCode = prefs.getString(SharePrefKey.languageCode) ?? "en";
    final storedLangKey =
        prefs.getString(SharePrefKey.language) ?? 'language_english';
    languageKey = storedLangKey;
    language = storedLangKey.tr;
    countryCode = prefs.getString('countryCode') ?? "US";
    Get.updateLocale(Locale(languageCode, countryCode));
    update();
  }

  getData() async {
    isLogin = await SharedPref.readBool(SharePrefKey.isLogin) ?? false;
    final storedGender = await SharedPref.readString(SharePrefKey.gender);
    if (storedGender != null && storedGender.isNotEmpty) {
      final lower = storedGender.toLowerCase();
      if (lower != 'male' && lower != 'female') {
        await SharedPref.saveString(SharePrefKey.gender, '');
      }
    }
    update();
  }
}
