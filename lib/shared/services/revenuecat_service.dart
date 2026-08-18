import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _initialized = false;
  String? _iosKey;
  String? _androidKey;

  String get offeringKey => dotenv.env['OFFERING_KEY'] ?? 'default';
  String get iosPublicKey => _iosKey ?? dotenv.env['IOS_PUBLIC_SDK_KEY'] ?? '';
  String get androidPublicKey =>
      _androidKey ?? dotenv.env['ANDROID_PUBLIC_SDK_KEY'] ?? '';

  Future<void> init({String? iosApiKey, String? androidApiKey}) async {
    if (_initialized) return;

    // Store keys if provided
    if (iosApiKey != null) _iosKey = iosApiKey;
    if (androidApiKey != null) _androidKey = androidApiKey;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? iosPublicKey
        : androidPublicKey;

    if (apiKey.isEmpty) {
      if (kDebugMode) {
        print('RevenueCat: API key is empty, skipping initialization');
      }
      _initialized = true;
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      // configure without userid first
      await Purchases.configure(PurchasesConfiguration(apiKey));

      if (kDebugMode) {
        print('RevenueCat: SDK configured successfully');
      }

      // identify user if firebase ready
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await Purchases.logIn(user.uid);
          if (kDebugMode) {
            print('RevenueCat: User identified with Firebase UID');
          }
        } catch (e) {
          if (kDebugMode) {
            print('RevenueCat: Could not identify user: $e');
          }
        }
      }

      // verify connection
      if (kDebugMode) {
        try {
          final offerings = await Purchases.getOfferings();
          print(
            'RevenueCat: Connected! Found ${offerings.all.length} offerings',
          );
          if (offerings.current != null) {
            print(
              'Current offering has ${offerings.current!.availablePackages.length} packages',
            );
          }
        } catch (e) {
          print('RevenueCat: Error fetching offerings: $e');
        }
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Configuration failed: $e');
      }
      rethrow;
    }
  }

  Future<void> identifyWithFirebaseUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (kDebugMode) {
        print('RevenueCat: Identifying with user ${user.uid}');
      }
      await Purchases.logIn(user.uid);
      if (kDebugMode) {
        print('RevenueCat: Successfully identified user ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error identifying user: $e');
      }
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      if (kDebugMode) {
        print('RevenueCat: Logged out app user');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error logging out app user: $e');
      }
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> presentCodeRedemptionSheet() async {
    if (!Platform.isIOS) return;
    try {
      await Purchases.presentCodeRedemptionSheet();
      if (kDebugMode) {
        print('RevenueCat: Presented code redemption sheet');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error presenting code redemption sheet: $e');
      }
    }
  }

  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error fetching offerings: $e');
      }
      return null;
    }
  }

  Future<void> refreshSubscription() async {
    try {
      if (kDebugMode) {
        print('RevenueCat: Forcing subscription refresh via Cloud Function...');
      }
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('refreshSubscription');
      await callable.call();
      if (kDebugMode) {
        print('RevenueCat: Subscription refresh triggered successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat: Error refreshing subscription: $e');
      }
    }
  }
}
