import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/services/app_config_service.dart';

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

    // debug: check dotenv
    if (kDebugMode) {
      print('RevenueCat: Checking dotenv...');
      print('dotenv.isInitialized: ${dotenv.isInitialized}');
      print('All keys in dotenv: ${dotenv.env.keys.toList()}');
      print(
        'IOS_PUBLIC_SDK_KEY value: "${dotenv.env['IOS_PUBLIC_SDK_KEY']}"',
      );
      print(
        'ANDROID_PUBLIC_SDK_KEY value: "${dotenv.env['ANDROID_PUBLIC_SDK_KEY']}"',
      );
      print('iosPublicKey getter: "$iosPublicKey"');
      print('androidPublicKey getter: "$androidPublicKey"');
    }

    final apiKey =
        defaultTargetPlatform == TargetPlatform.iOS
            ? iosPublicKey
            : androidPublicKey;

    if (kDebugMode) {
      print('Platform: ${defaultTargetPlatform.name}');
      print(
        'API Key: ${apiKey.isEmpty ? "EMPTY" : "${apiKey.length > 10 ? apiKey.substring(0, 10) : apiKey}..."}',
      );
    }

    if (apiKey.isEmpty) {
      if (kDebugMode) {
        print('RevenueCat: API key is empty, skipping initialization');
      }
      _initialized = true;
      return;
    }

    if (kDebugMode) {
      print(
        'RevenueCat: Initializing with API key: ${apiKey.substring(0, 10)}...',
      );
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
      await Purchases.logIn(user.uid);
    } catch (_) {}
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } catch (_) {
      return false;
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

  Future<bool> purchasePlan(String planType, {String? promoCode}) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        // fallback to direct product
        return _fallbackPurchaseByProductId(planType, promoCode: promoCode);
      }

      Package? target;
      final desired =
          planType.toLowerCase() == 'yearly'
              ? PackageType.annual
              : PackageType.monthly;

      for (final p in current.availablePackages) {
        if (p.packageType == desired) {
          target = p;
          break;
        }
      }
      if (target == null && current.availablePackages.isEmpty) {
        // no packages, try direct
        return _fallbackPurchaseByProductId(planType, promoCode: promoCode);
      }
      target ??= current.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier.toLowerCase().contains(
          planType.toLowerCase() == 'yearly' ? 'year' : 'month',
        ),
        orElse:
            () =>
                current.availablePackages.isNotEmpty
                    ? current.availablePackages.first
                    : (throw Exception('no-packages')),
      );

      // store promo for tracking
      if (promoCode != null && promoCode.isNotEmpty) {
        await Purchases.setAttributes({
          'promo_code': promoCode,
          'promo_applied_at': DateTime.now().toIso8601String(),
        });
      }

      final result = await Purchases.purchasePackage(target);
      return result.entitlements.active.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _fallbackPurchaseByProductId(
    String planType, {
    String? promoCode,
  }) async {
    try {
      final cfg =
          Get.isRegistered<AppConfigService>()
              ? Get.find<AppConfigService>()
              : null;
      String? productId;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ids = cfg?.iosIapIds;
        productId =
            (planType.toLowerCase() == 'yearly')
                ? (ids != null ? ids['yearly'] : null)
                : (ids != null ? ids['monthly'] : null);
        productId ??=
            (planType.toLowerCase() == 'yearly')
                ? dotenv.env['IOS_YEARLY_IAP_ID']
                : dotenv.env['IOS_MONTHLY_IAP_ID'];
      } else {
        final ids = cfg?.androidIapIds;
        productId =
            (planType.toLowerCase() == 'yearly')
                ? (ids != null ? ids['yearly'] : null)
                : (ids != null ? ids['monthly'] : null);
        productId ??=
            (planType.toLowerCase() == 'yearly')
                ? dotenv.env['ANDROID_YEARLY_IAP_ID']
                : dotenv.env['ANDROID_MONTHLY_IAP_ID'];
      }

      if (productId == null || productId.isEmpty) {
        if (kDebugMode) {
          print('RevenueCat fallback: Missing productId for $planType');
        }
        return false;
      }

      if (kDebugMode) {
        print(
          'RevenueCat fallback: purchasing by productId="$productId" for plan="$planType"',
        );
      }

      if (promoCode != null && promoCode.isNotEmpty) {
        await Purchases.setAttributes({
          'promo_code': promoCode,
          'promo_applied_at': DateTime.now().toIso8601String(),
        });
      }

      final products = await Purchases.getProducts([productId]);
      if (products.isEmpty) {
        if (kDebugMode) {
          print('RevenueCat fallback: Product not found for id=$productId');
        }
        return false;
      }

      final result = await Purchases.purchaseStoreProduct(products.first);
      return result.entitlements.active.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat fallback purchase error: $e');
      }
      return false;
    }
  }
}
