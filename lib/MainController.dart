import 'dart:ui';

import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/Appkey.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController extends GetxController{
  String countryCode = "";
  String languageCode = "";
  // translation key for the language (e.g. language_arabic)
  String languageKey = "";
  // localized display for UI
  String language = "";
  bool isLogin = false;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getData();
    getLanguageCode();
  }

  getLanguageCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
  // Default to Arabic for first-time users
  languageCode = prefs.getString(SharePrefKey.languageCode) ?? "ar";
  // stored language is the translation key (e.g. language_arabic)
  final storedLangKey = prefs.getString(SharePrefKey.language) ?? 'language_arabic';
  languageKey = storedLangKey;
  language = storedLangKey.tr;
  countryCode = prefs.getString('countryCode') ?? "SA";
    Get.updateLocale(Locale(languageCode, countryCode));
    update();
  }

  getData()
  async {
    isLogin = await SharedPref.readBool(SharePrefKey.isLogin) ?? false;
    scanLimit = await SharedPref.readInt(SharePrefKey.scanLimit) ??
        scanLimit;
    // Gender migration: remove legacy third gender option
    final storedGender = await SharedPref.readString(SharePrefKey.gender);
    if(storedGender != null && storedGender.isNotEmpty){
      final lower = storedGender.toLowerCase();
      if(lower != 'male' && lower != 'female'){
        await SharedPref.saveString(SharePrefKey.gender, '');
      }
    }
    update();
  }
}