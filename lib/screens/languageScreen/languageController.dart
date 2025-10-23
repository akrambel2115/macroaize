import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

class LanguageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  
  // Language data (keys and locale mappings)
  List<String> languageList = ["language_english", "language_arabic", "language_french"];
  List<String> languageCode = ["en", "ar", "fr"];
  List<String> countryCode = ["US", "SA", "FR"];
  List<Locale> local = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
    Locale('fr', 'FR'),
  ];

  @override
  void onInit() {
    super.onInit();
    getCurrentLanguage();
  }

  void getCurrentLanguage() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Prefer stored languageCode, then app locale, then stored translation key, then default.
  String storedLangKey = prefs.getString(SharePrefKey.language) ?? '';
  String storedCode = prefs.getString(SharePrefKey.languageCode) ?? '';

    // 1) Use stored language code if present.
    if (storedCode.isNotEmpty) {
      final byCode = languageCode.indexOf(storedCode);
      if (byCode != -1) {
        selectedIndex.value = byCode;
        update();
        return;
      }
    }

    // 2) Else, prefer the app's active locale (Get.locale/device locale).
    final appLang = (Get.locale?.languageCode ?? Get.deviceLocale?.languageCode ?? '').toLowerCase();
    if (appLang.isNotEmpty) {
      final appIndex = languageCode.indexOf(appLang);
      if (appIndex != -1) {
        selectedIndex.value = appIndex;
        update();
        return;
      }
    }

    // 3) Else, fall back to stored translation-key value if present.
    if (storedLangKey.isNotEmpty) {
      final idx = languageList.indexOf(storedLangKey);
      if (idx != -1) {
        selectedIndex.value = idx;
        update();
        return;
      }
    }

    // 4) Final fallback: default to first entry.
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
    // Store the translation key and language/country codes.
    await prefs.setString(SharePrefKey.language, languageList[index]);
  await prefs.setString(SharePrefKey.languageCode, languageCode[index]);
  await prefs.setString(SharePrefKey.countryCode, countryCode[index]);
  }
}
