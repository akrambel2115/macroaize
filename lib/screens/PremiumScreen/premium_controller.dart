import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:macroaize/shared/services/app_user_service.dart';
import 'package:macroaize/shared/services/subscription_service.dart';
import 'package:macroaize/shared/models/subscription.dart';
import 'package:macroaize/shared/services/revenuecat_service.dart';
import 'package:macroaize/features/auth/presentation/auth_modal.dart';
import 'package:macroaize/constant/app_color.dart';

import 'package:macroaize/shared/services/app_config_service.dart';
import 'package:macroaize/shared/services/usage_service.dart';
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

  StreamSubscription<Subscription?>? _firestoreSubscription;
  StreamSubscription<DocumentSnapshot>? _promoUsesSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Promo eligibility state
  bool promoLinked = false;
  bool _promoExtensionFromSubscription = false;
  bool _promoExtensionFromPromoUses = false;
  bool get promoExtensionApplied =>
      _promoExtensionFromSubscription || _promoExtensionFromPromoUses;
  bool get promoEligible =>
      (promoLinked || promoCode.isNotEmpty) && !promoExtensionApplied;

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
        errorMessage = 'no_offers_moment'.tr;
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
      errorMessage = 'failed_load_offers'.tr;
      if (kDebugMode) {
        print('Error fetching offerings: $e');
      }
    } finally {
      if (offerings?.current != null) {
        if (kDebugMode) {
          print(
            'RevenueCat: Current Offering ID: ${offerings!.current!.identifier}',
          );
        }
        for (var p in offerings!.current!.availablePackages) {
          if (kDebugMode) {
            print('RevenueCat Package: ${p.identifier}');
            print('Type: ${p.packageType}');
            print('Price: ${p.storeProduct.price}');
            print('PriceString: ${p.storeProduct.priceString}');
            print('IntroPrice: ${p.storeProduct.introductoryPrice?.price}');
            print('IntroPeriod: ${p.storeProduct.introductoryPrice?.period}');
          }

          if (kDebugMode) {
            print('IntroCycles: ${p.storeProduct.introductoryPrice?.cycles}');
          }
        }
      }
      isLoading = false;
      update();
    }
  }

  int _findTrialPlanIndex() {
    if (offerings?.current == null) return -1;
    final packages = offerings!.current!.availablePackages;
    return packages.indexWhere(
      (p) =>
          (p.storeProduct.introductoryPrice != null &&
              p.storeProduct.introductoryPrice!.price == 0) ||
          p.storeProduct.price == 0,
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
      Future.delayed(const Duration(seconds: 5), () {
        showClose = true;
        update(['close_btn']);
      });
    }
  }

  void onClosePressed() {
    if (fromOnboarding) {
      Get.offAllNamed(Routes.leadingView);
    } else {
      Get.back();
    }
  }

  void _subscribeToFirestore() {
    _firestoreSubscription?.cancel();
    _promoUsesSubscription?.cancel();

    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _firestoreSubscription?.cancel();
      _promoUsesSubscription?.cancel();

      if (user == null) {
        if (isPremium) {
          isPremium = false;
          update();
        }
        promoLinked = false;
        _promoExtensionFromSubscription = false;
        _promoExtensionFromPromoUses = false;
        update();
        return;
      }

      // Subscribe to subscription stream instead of Firestore direct
      _firestoreSubscription = SubscriptionService().subscriptionStream.listen((
        sub,
      ) {
        final active = sub?.isActive == true;
        isPremium = active;
        _promoExtensionFromSubscription = sub?.promoExtensionApplied == true;
        update();
      });

      // Subscribe to promoUses doc to track promo eligibility (real-time)
      _promoUsesSubscription = FirebaseFirestore.instance
          .collection('promoUses')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
            final data = doc.data();
            promoLinked =
                (data != null &&
                    (data['promoCode'] ?? '').toString().isNotEmpty);
            _promoExtensionFromPromoUses = (data?['extensionApplied'] == true);
            update();
          });
    });
  }

  /// Check if user has a linked promo code. If not, show dialog to enter one.
  /// Returns true if user has promo (or entered one), false if skipped, null if cancelled.
  Future<bool?> _checkAndPromptPromoCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      // Check if user already has a linked promo code
      final promoDoc =
          await FirebaseFirestore.instance
              .collection('promoUses')
              .doc(uid)
              .get();

      if (promoDoc.exists) {
        // User already has a promo code linked
        promoCode = promoDoc.data()?['promoCode'] ?? '';
        if (kDebugMode) {
          print('User already has promo code linked: $promoCode');
        }
        return true;
      }

      // No promo code linked - show dialog to enter one
      return await _showPromoCodeDialog();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking promo code: $e');
      }
      // On error, allow purchase to proceed without promo
      return false;
    }
  }

  /// Shows a dialog prompting user to enter a promo code for extra days.
  /// Returns true if promo entered successfully, false if skipped, null if cancelled.
  /// Shows a dialog prompting user to enter a promo code for extra days.
  /// Returns true if promo entered successfully, false if skipped, null if cancelled.
  Future<bool?> _showPromoCodeDialog() async {
    final TextEditingController promoController = TextEditingController();
    String? errorMessage;
    bool isValidating = false;
    bool isLinked = false;

    // Get the selected package type for showing correct benefit
    final package = offerings?.current?.availablePackages[selected];
    final isYearly = package?.packageType == PackageType.annual;
    final bonusDaysText =
        isYearly ? 'Get 1 Month Extra Free!' : 'Get 3 Days Extra Free!';

    return await Get.bottomSheet<bool?>(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: AppColor.darkBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'redeem_code'.tr,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Promo Offer Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColor.primaryOrange,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            bonusDaysText,
                            style: const TextStyle(
                              color: AppColor.primaryOrange,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Field
                    TextField(
                      controller: promoController,
                      enabled: !isLinked,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            'Enter promo code', // or 'enter_promo_code'.tr
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColor.primaryOrange,
                          ),
                        ),
                        suffixIcon:
                            isLinked
                                ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                                : null,
                        errorText: errorMessage,
                      ),
                    ),

                    if (isLinked) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'promo_code_linked_success'.tr,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Buttons
                    if (!isLinked) ...[
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              isValidating
                                  ? null
                                  : () async {
                                    final code =
                                        promoController.text
                                            .toUpperCase()
                                            .trim();
                                    if (code.isEmpty) {
                                      setState(
                                        () =>
                                            errorMessage =
                                                'enter_promo_code'.tr,
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isValidating = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      // Validate promo code
                                      final result = await _influencerService
                                          .validatePromoCode(code);
                                      if (!result.valid) {
                                        setState(() {
                                          isValidating = false;
                                          errorMessage =
                                              'invalid_promo_code'.tr;
                                        });
                                        return;
                                      }

                                      // Link promo code via Cloud Function
                                      final functions =
                                          FirebaseFunctions.instanceFor(
                                            region: 'europe-west1',
                                          );
                                      await functions
                                          .httpsCallable(
                                            'storePromoCodeForPurchase',
                                          )
                                          .call({'promoCode': code});

                                      promoCode = code;
                                      setState(() {
                                        isValidating = false;
                                        isLinked = true;
                                      });

                                      // Auto-close or just let user click continue
                                      // User asked for "Apply" button at bottom.
                                      // After apply success, we can change button to "Continue" or close.
                                      // The original logic closed it.
                                      // Let's stick to closing or showing success state.

                                      // Auto-close check
                                      Future.delayed(
                                        const Duration(milliseconds: 1000),
                                        () {
                                          if (Get.isBottomSheetOpen == true) {
                                            Get.back(result: true);
                                          }
                                        },
                                      );
                                    } catch (e) {
                                      setState(() {
                                        isValidating = false;
                                        errorMessage = 'invalid_promo_code'.tr;
                                      });
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child:
                              isValidating
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                  : Text(
                                    'apply'.tr,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: Text(
                          'skip'.tr,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'continue'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  Future<void> buy() async {
    if (isPremium) {
      NotificationService.showInfo('already_premium'.tr);
      return;
    }

    if (offerings?.current == null ||
        offerings!.current!.availablePackages.isEmpty) {
      NotificationService.showError('no_offers_available'.tr);
      return;
    }

    // Guard: check if subscriptions are enabled via remote config
    if (Get.isRegistered<AppConfigService>()) {
      final cfg = Get.find<AppConfigService>();
      if (!cfg.subscriptionsEnabled) {
        NotificationService.showError('subscriptions_disabled'.tr);
        return;
      }
    }

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final ok = await AuthModal.show();
      if (!ok) {
        NotificationService.showError('login_to_continue'.tr);
        return;
      }
      Get.offAllNamed(Routes.leadingView);
      user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        NotificationService.showError('auth_failed'.tr);
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
            NotificationService.showInfo('already_premium_subscription'.tr);
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking subscription status: $e');
      NotificationService.showError('unable_verify_subscription'.tr);
      return;
    }

    if (isPremium) {
      NotificationService.showInfo('already_premium'.tr);
      return;
    }

    // Check if user has a linked promo code, if not, show dialog to enter one
    final hasLinkedPromo = await _checkAndPromptPromoCode();
    if (hasLinkedPromo == null) {
      // User cancelled the dialog
      return;
    }

    try {
      await RevenueCatService().identifyWithFirebaseUser();

      final package = offerings!.current!.availablePackages[selected];

      final result = await Purchases.purchasePackage(package);

      if (result.entitlements.active.isNotEmpty) {
        NotificationService.showSuccess('purchase_successful_verifying'.tr);
        try {
          // Wait briefly for RevenueCat to propagate the purchase before syncing
          await Future.delayed(const Duration(seconds: 3));
          // Force sync immediately after successful purchase
          await RevenueCatService().refreshSubscription();
          await _appUserService.isPremiumUser();
          // Refresh UsageService to update local isPremium and limits
          if (Get.isRegistered<UsageService>()) {
            await Get.find<UsageService>().getUsage();
          }
        } catch (e) {
          if (kDebugMode) print('Post-purchase sync error: $e');
        }
        NotificationService.showSuccess('subscription_active'.tr);
        return;
      } else {
        NotificationService.showInfo('purchase_cancelled'.tr);
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

      String errorMsg = 'purchase_failed'.tr;
      if (e is PlatformException) {
        // Error Code 6: ProductAlreadyPurchasedError
        if (e.code == '6' || e.message?.contains('already active') == true) {
          if (kDebugMode) {
            print('RevenueCat: Product already owned on this Play account.');
          }
          NotificationService.showError('subscription_already_active_play'.tr);
          // Do NOT restore here to avoid transferring entitlements between app accounts
          return;
        }

        // Error Code 5: ProductNotAvailableForPurchaseError (ITEM_UNAVAILABLE)
        if (e.code == '5' ||
            e.message?.contains('not available for purchase') == true) {
          if (kDebugMode) {
            print(
              'RevenueCat: Product not available for purchase (ITEM_UNAVAILABLE)',
            );
          }
          NotificationService.showError(
            'subscription_temporarily_unavailable'.tr,
          );
          return;
        }

        errorMsg =
            e.message?.isNotEmpty == true
                ? 'Error: ${e.message}'
                : 'purchase_failed'.tr;
      }

      NotificationService.showError(errorMsg);
      return;
    }
  }

  Future<void> restorePurchases() async {
    try {
      NotificationService.showInfo('restore_in_progress'.tr);
      final restored = await RevenueCatService().restorePurchases();
      if (restored) {
        // sync Firestore subscription state after successful restore
        try {
          await RevenueCatService().refreshSubscription();
          await _appUserService.isPremiumUser();
          if (Get.isRegistered<UsageService>()) {
            await Get.find<UsageService>().getUsage();
          }
        } catch (e) {
          if (kDebugMode) print('Post-restore sync error: $e');
        }
        NotificationService.showSuccess('restore_success'.tr);
      } else {
        NotificationService.showError('restore_no_purchases'.tr);
      }
    } catch (e) {
      if (kDebugMode) print('Restore error: $e');
      NotificationService.showError('restore_failed'.tr);
    }
  }

  onChangeSelectedIndex(int index) {
    selected = index;
    update();
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
      promoError = 'enter_promo_code'.tr;
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
        NotificationService.showSuccess('promo_code_linked_success'.tr);
      } else {
        isPromoValid = false;
        discountRate = 0.0;
        promoError = 'invalid_promo_code'.tr;
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

  /// Returns the bonus days text for the currently selected package.
  /// Promo codes grant bonus subscription days, not a price discount.
  String? getBonusDaysText() {
    if (!promoEligible) return null;
    final package = offerings?.current?.availablePackages.elementAtOrNull(
      selected,
    );
    if (package == null) return null;
    final isYearly = package.packageType == PackageType.annual;
    return isYearly ? 'bonus_1_month'.tr : 'bonus_3_days'.tr;
  }

  @override
  void onClose() {
    _firestoreSubscription?.cancel();
    _promoUsesSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}
