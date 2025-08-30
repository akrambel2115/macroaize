import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePref.dart';
import 'package:foodcalorietracker/SharePrefHelper/SharePrefKey.dart';

class AuthService {
  static bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  static Future<void> syncLoginFlag() async {
    final logged = isLoggedIn;
    await SharedPref.saveBool(SharePrefKey.isLogin, logged);
  }
}
