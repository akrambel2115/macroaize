import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/shared/services/revenuecat_service.dart';
import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';

import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import '../../shared/services/influencer_service.dart';
import '../../routes/app_routes.dart';

class PremiumController extends GetxController {
  int selected = 0;
  bool isPremium = false;
  bool showClose = true;
  bool fromOnboarding = false;

  String promoCode = '';
  bool isValidatingPromo = false;
  bool isPromoValid = false;
  double discountRate = 0.0;
  String? promoError;

  Offerings? offerings;
  bool isLoading = true;
  String? errorMessage;

  final _influencerService = InfluencerService();
  final _appUserService = AppUserService();

  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    getPremium();
    fetchOfferings();
    _subscribeToFirestore();
  }

  Future<void> fetchOfferings() async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      offerings = await RevenueCatService().getOfferings();

      if (offerings == null ||
          offerings!.current == null ||
          offerings!.current!.availablePackages.isEmpty) {
        errorMessage = 'No offers available at the moment.';
      } else {
        int trialIndex = _findTrialPlanIndex();
        if (trialIndex >= 0) {
          selected = trialIndex;
        } else {
          int yearlyIndex = _findYearlyPlanIndex();
          if (yearlyIndex >= 0) {
            selected = yearlyIndex;
          }
        }
      }
    } catch (e) {
      errorMessage = 'Failed to load offers. Please try again.';
      if (kDebugMode) {
        print('Error fetching offerings: $e');
      }
    } finally {
      isLoading = false;
      update();
    }
  }

  int _findTrialPlanIndex() {
    if (offerings?.current == null) return -1;
    final packages = offerings!.current!.availablePackages;
    return packages.indexWhere(
      (p) =>
          p.storeProduct.introductoryPrice != null &&
          p.storeProduct.introductoryPrice!.price == 0,
    );
  }

  int _findYearlyPlanIndex() {
    if (offerings?.current == null) return -1;
    final packages = offerings!.current!.availablePackages;
    return packages.indexWhere((p) => p.packageType == PackageType.annual);
  }

  bool _argsProcessed = false;

  void processArgs(Map? args) {
    if (_argsProcessed) return;
    _argsProcessed = true;
    final delayClose = args is Map && args['delayClose'] == true;
    fromOnboarding = args is Map && args['fromOnboarding'] == true;

    if (args is Map && args['promoCode'] != null) {
      promoCode = args['promoCode'] as String;
      isPromoValid = true;
      if (kDebugMode) {
        print('Promo code from signup: $promoCode');
      }
    }

    if (delayClose) {
      showClose = false;
      update(['close_btn']);
      Future.delayed(const Duration(seconds: 3), () {
        showClose = true;
        update(['close_btn']);
      });
    }
  }

  void onClosePressed() {
    if (fromOnboarding) {
      try {
        Get.offAllNamed(Routes.leadingView);
      } catch (_) {}
      Future.delayed(const Duration(milliseconds: 200), () {
        if (Get.currentRoute != Routes.leadingView) {
          try {
            Get.toNamed(Routes.leadingView);
          } catch (_) {}
        }
      });
    } else {
      Get.back();
    }
  }

  void _subscribeToFirestore() {
    _firestoreSubscription?.cancel();

    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _firestoreSubscription?.cancel();

      if (user == null) {
        if (isPremium) {
          isPremium = false;
          update();
        }
        return;
      }

      _firestoreSubscription = FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            final data = doc.data();
            final now = DateTime.now().toUtc();
            final active =
                data != null &&
                data['isPremium'] == true &&
                DateTime.tryParse(
                      data['endDate']?.toString() ?? '',
                    )?.isAfter(now) ==
                    true;
            if (active != isPremium) {
              isPremium = active;
              update();
            }
          });
    });
  }

  Future<void> buy() async {
    if (isPremium) {
      Fluttertoast.showToast(msg: 'You are already Premium');
      return;
    }

    if (offerings?.current == null ||
        offerings!.current!.availablePackages.isEmpty) {
      Fluttertoast.showToast(msg: 'No offers available');
      return;
    }

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final ok = await AuthModal.show();
      if (!ok) {
        Fluttertoast.showToast(msg: 'Please login to continue');
        return;
      }
      user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(msg: 'Authentication failed');
        return;
      }
    }

    try {
      await user.reload();
      await user.getIdToken(true);
    } catch (_) {}
    if (!_appUserService.checkAccountActivation('premium')) {
      return;
    }

    try {
      Future<DocumentSnapshot<Map<String, dynamic>>> readSub() =>
          FirebaseFirestore.instance
              .collection('subscriptions')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      DocumentSnapshot<Map<String, dynamic>> subscriptionDoc;
      try {
        subscriptionDoc = await readSub();
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('permission') || msg.contains('permission-denied')) {
          try {
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
          } catch (_) {}
          subscriptionDoc = await readSub();
        } else {
          rethrow;
        }
      }

      if (subscriptionDoc.exists) {
        final data = subscriptionDoc.data();
        if (data != null) {
          final now = DateTime.now().toUtc();
          final isPremiumActive =
              data['isPremium'] == true &&
              DateTime.tryParse(
                    data['endDate']?.toString() ?? '',
                  )?.isAfter(now) ==
                  true;

          if (isPremiumActive) {
            isPremium = true;
            update();
            Fluttertoast.showToast(
              msg: 'You already have an active Premium subscription',
            );
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking subscription status: $e');
      Fluttertoast.showToast(
        msg: 'Unable to verify subscription status. Please try again.',
      );
      return;
    }

    if (isPremium) {
      Fluttertoast.showToast(msg: 'You are already Premium');
      return;
    }

    try {
      await RevenueCatService().identifyWithFirebaseUser();

      final package = offerings!.current!.availablePackages[selected];

      final result = await Purchases.purchasePackage(package);

      if (result.entitlements.active.isNotEmpty) {
        Fluttertoast.showToast(msg: 'Purchase successful');
        return;
      } else {
        Fluttertoast.showToast(msg: 'Purchase cancelled');
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat purchase error: $e');
        if (e is PlatformException) {
          print('Error Code: ${e.code}');
          print('Error Message: ${e.message}');
          print('Error Details: ${e.details}');
        }
      }
      // user cancelled
      if (e.toString().contains('User cancelled')) {
        return;
      }

      String errorMsg = 'Purchase failed. Please try again.';
      if (e is PlatformException) {
        errorMsg = 'Error: ${e.message ?? "Unknown error"}';
      }

      Fluttertoast.showToast(msg: errorMsg);
      return;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await RevenueCatService().restorePurchases();
    } catch (_) {}
  }

  // promo dialog removed
  /*
  Future<void> _showPromoCodeDialog() async {
    final promoController = TextEditingController();
    bool isValidating = false;
    String? errorMessage;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'promo_code_dialog_title'.tr,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'promo_code_dialog_subtitle'.tr,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: context.theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          errorMessage != null
                              ? Colors.red.withOpacity(0.5)
                              : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: promoController,
                    style: TextStyle(
                      color: context.theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'enter_promo_code'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[600], fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isValidating
                        ? null
                        : () {
                          Get.back();
                          _proceedToCheckout('chargily');
                        },
                child: Text(
                  'skip_promo_code'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    isValidating
                        ? null
                        : () async {
                          final code =
                              promoController.text.toUpperCase().trim();
                          if (code.isEmpty) {
                            setState(() {
                              errorMessage = 'Please enter a promo code';
                            });
                            return;
                          }

                          setState(() {
                            isValidating = true;
                            errorMessage = null;
                          });

                          try {
                            await _validatePromoCodeForDialog(code);
                            setState(() {
                              isValidating = false;
                            });
                            Get.back();
                            Fluttertoast.showToast(
                              msg: 'promo_code_applied'.tr,
                            );
                            _proceedToCheckout('chargily');
                          } catch (e) {
                            setState(() {
                              isValidating = false;
                              errorMessage = 'promo_code_invalid'.tr;
                            });
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    isValidating
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'apply_promo_code'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
  */

  // promo validation removed
  /*
  Future<void> _validatePromoCodeForDialog(String code) async {
    if (code.isEmpty) {
      throw Exception('Please enter a promo code');
    }

    try {
      final result = await _influencerService.validatePromoCode(code);

      if (result.valid) {
        promoCode = code;
        isPromoValid = true;
        discountRate = result.discountRate;
        promoError = null;
        update();
      } else {
        throw Exception('Invalid promo code');
      }
    } catch (e) {
      throw Exception('Invalid promo code');
    }
  }
  */

  // chargily checkout removed
  /*
  Future<void> _proceedToCheckout([String? methodOverride]) async {
    String planType = 'monthly';
    if (products.isNotEmpty) {
      final p = products[selected];
      final id = p.id.toLowerCase();
      final title = p.title.toLowerCase();
      if (id.contains('year') ||
          id.contains('annual') ||
          title.contains('year') ||
          title.contains('annual')) {
        planType = 'yearly';
      }
    }

    final cfg = Get.find<AppConfigService>();
    final rcEnabled = cfg.subscriptionsEnabled && (Platform.isAndroid || Platform.isIOS);

    if (rcEnabled) {
      final method = methodOverride ?? await _choosePaymentMethod();
      if (method == 'store') {
        try {
          await RevenueCatService().identifyWithFirebaseUser();
          final ok = await RevenueCatService().purchasePlan(planType);
          if (ok) {
            Fluttertoast.showToast(msg: 'Purchase successful');
            return;
          } else {
            Fluttertoast.showToast(msg: 'Purchase cancelled');
            return;
          }
        } catch (_) {
          Fluttertoast.showToast(msg: 'Purchase failed');
          return;
        }
      } else if (method == 'chargily') {
      } else {
        return;
      }
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('createChargilyPayment');
      final result = await callable.call({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'planType': planType,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (isPromoValid && promoCode.isNotEmpty) 'promoCode': promoCode,
      });

      final data = result.data as Map;
      final url = Uri.parse(data['checkoutUrl'] as String);

      if (isPremium) {
        Fluttertoast.showToast(
          msg: 'Subscription status changed. Payment cancelled.',
        );
        return;
      }

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        Fluttertoast.showToast(
          msg: 'Could not open browser for checkout',
        );
        return;
      }

      Fluttertoast.showToast(
        msg: 'Complete payment in your browser. Return to the app when done.',
      );
    } catch (e) {
      if (kDebugMode) print('createChargilyPayment error: $e');

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already-subscribed') ||
          errorMsg.contains('already') ||
          errorMsg.contains('premium') ||
          errorMsg.contains('active')) {
        Fluttertoast.showToast(msg: 'You already have an active subscription');
        isPremium = true;
        update();
        _subscribeToFirestore();
      } else if (errorMsg.contains('unauthenticated')) {
        Fluttertoast.showToast(msg: 'Please login and try again');
        isPremium = false;
        update();
      } else if (errorMsg.contains('permission-denied')) {
        Fluttertoast.showToast(msg: 'Permission denied. Please login again.');
        isPremium = false;
        update();
      } else {
        Fluttertoast.showToast(
          msg: 'Payment creation failed. Please try again.',
        );
      }
    }
  }
  */

  // payment chooser removed
  /*
  Future<String?> _choosePaymentMethod() async {
    final isIOS = Platform.isIOS;
    final storePaymentName = isIOS ? 'Apple Pay' : 'Google Pay subscription';
    final storeIcon = isIOS ? Icons.apple : Icons.android;
    
    return Get.dialog<String>(
      AlertDialog(
        backgroundColor: AppColor.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Choose Payment Method'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.back(result: 'store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(storeIcon, size: 24),
                label: Text(
                  storePaymentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.back(result: 'chargily'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54, width: 1),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.credit_card, size: 24),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Dahabia (External)'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'external browser checkout outside the app'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel'.tr,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
  */

  onChangeSelectedIndex(int index) {
    selected = index;
    update(['plan_selection']);
  }

  getPremium() async {
    update();
  }

  openPrivacy() async {
    final cfg = Get.find<AppConfigService>();
    final Uri url = Uri.parse(cfg.privacyLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  openTerms() async {
    final cfg = Get.find<AppConfigService>();
    final Uri url = Uri.parse(cfg.termsLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void updatePromoCode(String code) {
    promoCode = code.toUpperCase().trim();
    isPromoValid = false;
    discountRate = 0.0;
    promoError = null;
    update();
  }

  void clearPromoCode() {
    promoCode = '';
    isPromoValid = false;
    discountRate = 0.0;
    promoError = null;
    isValidatingPromo = false;
    update();
  }

  Future<void> validatePromoCode() async {
    if (promoCode.isEmpty) {
      promoError = 'Please enter a promo code';
      update();
      return;
    }

    isValidatingPromo = true;
    promoError = null;
    update();

    try {
      final result = await _influencerService.validatePromoCode(promoCode);

      if (result.valid) {
        isPromoValid = true;
        discountRate = result.discountRate;
        promoError = null;
        Fluttertoast.showToast(
          msg: 'Promo code applied! ${(discountRate * 100).round()}% discount',
        );
      } else {
        isPromoValid = false;
        discountRate = 0.0;
        promoError = 'Invalid promo code';
      }
    } catch (e) {
      isPromoValid = false;
      discountRate = 0.0;
      promoError = e.toString().replaceAll('Exception: ', '');
    } finally {
      isValidatingPromo = false;
      update();
    }
  }

  String getDiscountedPrice(String originalPrice) {
    if (!isPromoValid || discountRate == 0.0) return originalPrice;

    final match = RegExp(r'[\d.,]+').stringMatch(originalPrice);
    if (match == null) return originalPrice;

    final numericPrice = double.tryParse(match.replaceAll(',', ''));
    if (numericPrice == null) return originalPrice;

    final discountedPrice = (numericPrice * (1 - discountRate)).round();
    return originalPrice.replaceAll(match, discountedPrice.toString());
  }

  String getOriginalPrice(String currentPrice) {
    if (!isPromoValid || discountRate == 0.0) return '';

    final match = RegExp(r'[\d.,]+').stringMatch(currentPrice);
    if (match == null) return '';

    final numericPrice = double.tryParse(match.replaceAll(',', ''));
    if (numericPrice == null) return '';

    final originalPrice = (numericPrice / (1 - discountRate)).round();
    return currentPrice.replaceAll(match, originalPrice.toString());
  }

  @override
  void onClose() {
    _firestoreSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}
