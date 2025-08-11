import 'dart:ui';

import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';
import 'package:foodcalorietracker/constant/Appkey.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainController extends GetxController{
  String countryCode = "";
  String languageCode = "";
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
    languageCode = prefs.getString(SharePrefKey.languageCode) ?? "en";
    language = prefs.getString(SharePrefKey.language) ?? "English";
    countryCode = prefs.getString('countryCode') ?? "US";
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