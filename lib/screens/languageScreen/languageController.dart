
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SharePrefHelper/SharePrefKey.dart';

class LanguageController extends GetxController{

  int selectedIndex = 0;
  String language = "";

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getIndex();
  }
  List<String> languageList = [
    'English',
    'Turkish',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Russian',
    'Hindi',
    'Arabic',
    'Portuguese',
    'Indonesian',
    'Dutch',
    'Italian',
    'Polish',
    'Japanese'
  ];
  List local = const  [
    Locale('en','US'),
    Locale('turk','TURK'),
    Locale('sp','SP'),
    Locale('fre','FRE'),
    Locale('gem','GEM'),
    Locale('ch','CH'),
    Locale('russ','RUSS'),
    Locale('hi','IN'),
    Locale('ar','AR'),
    Locale('por','PORTU'),
    Locale('indo','INDO'),
    Locale('dutch','DUTCH'),
    Locale('ity','ITY'),
    Locale('polish','POLISH'),
    Locale('japa','JAPA'),
  ];
  List<String> languageCode = [
    'en',
    'turk',
    'sp',
    'fre',
    'gem',
    'ch',
    'russ',
    'hi',
    'ar',
    'por',
    'indo',
    'dutch',
    'ity',
    'polish',
    'japa',
  ];

  List<String> countryCode = [
    'US',
    'TURK',
    'SP',
    'FRE',
    'GEM',
    'CH',
    'RUSS',
    'IN',
    'AR',
    'PORTU',
    'INDO',
    'DUTCH',
    'ITY',
    'POLISH',
    'JAPA'
  ];
  onChangeIndex (int index){
    selectedIndex = index;
    storeIndex(selectedIndex);
    update();
  }
  storeIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedIndex', index);
    update();
  }
  getIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    language = prefs.getString(SharePrefKey.language) ?? "English";
    selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    update();
  }
  storeLanguageCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SharePrefKey.languageCode, code);
    print("Language code -----> $code");
    update();
  }
  storeLanguage(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(SharePrefKey.language, languageList[index]);
    update();
  }
  storeCountryCode(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('countryCode', code);
    print("Country code -----> $code");
    update();
  }
  updateLanguage(Locale locale){
    Get.updateLocale(locale);
    update();
  }

}