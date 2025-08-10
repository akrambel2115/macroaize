import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == "null" ||
        prefs.getString(key) == "" ||
        prefs.getString(key) == "[]" ||
        prefs.getString(key) == null) {
      return "";
    }
    return json.decode(prefs.getString(key) ?? '');
  }

  static clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

  }

  static saveString(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, (value));
  }

  static readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(key) ?? '');
  }

  static saveInt(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(key, value);
  }

  static readInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(key));
  }

  static removeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  static save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, json.encode(value));
  }

  static saveList(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(key, (value));
  }

  static readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> value = prefs.getStringList(key) ?? [];
    if (value.isEmpty) {
      return value;
    }
    return value;
  }
  static readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static saveBool(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  static remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}
