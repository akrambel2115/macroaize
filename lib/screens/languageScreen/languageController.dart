import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../SharePrefHelper/SharePrefKey.dart';

class LanguageController extends GetxController {
  RxInt selectedIndex = 0.obs;
  
  // Language data
  List<String> languageList = ["English", "French", "Arabic"];
  List<String> languageCode = ["en", "fr", "ar"];
  List<String> countryCode = ["US", "FR", "SA"];
  List<Locale> local = [
    Locale('en', 'US'),
    Locale('fr', 'FR'),
    Locale('ar', 'SA'),
  ];

  @override
  void onInit() {
    super.onInit();
    getCurrentLanguage();
  }

  void getCurrentLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Prefer stored languageCode/countryCode to compute selected index
    String currentLanguage = prefs.getString(SharePrefKey.language) ?? "English";
    String code = prefs.getString(SharePrefKey.languageCode) ?? '';
    // If stored code exists, honor it; else fallback to display name
    final byCode = code.isNotEmpty ? languageCode.indexOf(code) : -1;
    if (byCode != -1) {
      selectedIndex.value = byCode;
    } else {
      int index = languageList.indexOf(currentLanguage);
      if (index != -1) {
        selectedIndex.value = index;
      }
    }
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
    await prefs.setString(SharePrefKey.language, languageList[index]);
  await prefs.setString(SharePrefKey.languageCode, languageCode[index]);
  await prefs.setString(SharePrefKey.countryCode, countryCode[index]);
  }
}
