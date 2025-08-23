import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

class LanguageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  
  // Language data
  // Use translation keys here so the UI can localize the language names
  // Order: Arabic, English, French (show Arabic first in settings)
  List<String> languageList = ["language_arabic", "language_english", "language_french"];
  List<String> languageCode = ["ar", "en", "fr"];
  List<String> countryCode = ["SA", "US", "FR"];
  List<Locale> local = [
    Locale('ar', 'SA'),
    Locale('en', 'US'),
    Locale('fr', 'FR'),
  ];

  @override
  void onInit() {
    super.onInit();
    getCurrentLanguage();
  }

  void getCurrentLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Prefer stored languageCode first. If not present, prefer the app's active locale
    // (Get.locale or device locale). Then fall back to stored translation key, then default.
    String storedLangKey = prefs.getString(SharePrefKey.language) ?? '';
    String storedCode = prefs.getString(SharePrefKey.languageCode) ?? '';

    // 1) If a stored language code exists, use it.
    if (storedCode.isNotEmpty) {
      final byCode = languageCode.indexOf(storedCode);
      if (byCode != -1) {
        selectedIndex.value = byCode;
        update();
        return;
      }
    }

    // 2) Else, prefer the app's currently active locale (Get.locale), which may be set
    // on first run even before prefs are written.
    final appLang = (Get.locale?.languageCode ?? Get.deviceLocale?.languageCode ?? '').toLowerCase();
    if (appLang.isNotEmpty) {
      final appIndex = languageCode.indexOf(appLang);
      if (appIndex != -1) {
        selectedIndex.value = appIndex;
        update();
        return;
      }
    }

    // 3) Else, fall back to stored translation-key value (if any).
    if (storedLangKey.isNotEmpty) {
      final idx = languageList.indexOf(storedLangKey);
      if (idx != -1) {
        selectedIndex.value = idx;
        update();
        return;
      }
    }

    // 4) Final fallback: default to first entry (Arabic in the new ordering).
    selectedIndex.value = 0;
    update();
  }

  void onChangeIndex(int index) {
    selectedIndex.value = index;
    update();
  }

  void storeCountryCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharePrefKey.countryCode, code);
  }

  void storeLanguageCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharePrefKey.languageCode, code);
  }

  void updateLanguage(Locale locale) {
    Get.updateLocale(locale);
  }

  void storeLanguage(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  // store the translation key (not the localized display string)
  await prefs.setString(SharePrefKey.language, languageList[index]);
  await prefs.setString(SharePrefKey.languageCode, languageCode[index]);
  await prefs.setString(SharePrefKey.countryCode, countryCode[index]);
  }
}
