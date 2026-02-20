import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/SharePrefHelper/share_pref.dart';
import 'package:macroaize/SharePrefHelper/share_pref_key.dart';

class AuthService {
  static bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  static Future<void> syncLoginFlag() async {
    final logged = isLoggedIn;
    await SharedPref.saveBool(SharePrefKey.isLogin, logged);
  }
}
