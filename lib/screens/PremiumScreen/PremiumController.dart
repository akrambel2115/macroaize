import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/shared/services/app_user_service.dart';
import 'package:foodcalorietracker/features/auth/presentation/auth_modal.dart';

import 'package:foodcalorietracker/shared/services/app_config_service.dart';
import '../../constant/AppColor.dart';
import '../../shared/services/influencer_service.dart';

class PremiumController extends GetxController {
  int selected = 0;
  bool isPremium = false;

  // Promo code functionality
  String promoCode = '';
  bool isValidatingPromo = false;
  bool isPromoValid = false;
  double discountRate = 0.0;
  String? promoError;
  final _influencerService = InfluencerService();
  final _appUserService = AppUserService();
  InAppPurchase inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<dynamic> streamSubscription;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;
  StreamSubscription<User?>? _authSubscription;
  late Set<String> ids;
  List<ProductDetails> products = [];

  @override
  void onInit() {
    final cfg = Get.find<AppConfigService>();
    ids = Platform.isAndroid
        ? {
            cfg.androidIapIds['weekly'] ?? '',
            cfg.androidIapIds['monthly'] ?? '',
            cfg.androidIapIds['yearly'] ?? '',
          }
        : {
            cfg.iosIapIds['weekly'] ?? '',
            cfg.iosIapIds['monthly'] ?? '',
            cfg.iosIapIds['yearly'] ?? '',
          };
    // TODO: implement onInit
    super.onInit();
    getPremium();
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
    streamSubscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        listenToPurchase(purchaseDetailsList);
      },
      onDone: () {
        streamSubscription.cancel();
      },
      onError: (error) {
        // handle error here.
      },
    );
    initStore();
    _subscribeToFirestore();
  }

  void _subscribeToFirestore() {
    // Cancel existing subscription if any
    _firestoreSubscription?.cancel();

    // Listen to auth changes and restart subscription accordingly
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

      // Listen to this user's subscription document
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

  initStore() async {
    bool isAvailable = await InAppPurchase.instance.isAvailable();
    if (kDebugMode) {
      print(isAvailable);
    }
    ProductDetailsResponse productDetailsResponse = await inAppPurchase
        .queryProductDetails(ids);
    if (productDetailsResponse.error == null) {
      if (kDebugMode) {
        print("loading Product$productDetailsResponse");
        print(productDetailsResponse.error);
        print(productDetailsResponse.notFoundIDs);
        print(productDetailsResponse.productDetails.length);
      }
      products = productDetailsResponse.productDetails;
      if (kDebugMode) {
        print("product length ${products.length}");
      }

      // Set default selection to yearly plan (12 months) if available
      if (products.isNotEmpty) {
        int yearlyIndex = _findYearlyPlanIndex();
        if (yearlyIndex >= 0) {
          selected = yearlyIndex;
        }
      }

      update(['plan_selection']); // Update specific GetBuilder
    }
  }

  /// Helper method to find the yearly plan index
  int _findYearlyPlanIndex() {
    const yearlyKeywords = ['year', 'annual'];
    return products.indexWhere((p) {
      final id = p.id.toLowerCase();
      final title = p.title.toLowerCase();
      return yearlyKeywords.any((k) => id.contains(k) || title.contains(k));
    });
  }

  listenToPurchase(List<PurchaseDetails> purchaseDetailsList) {
    for (var element in purchaseDetailsList) {
      if (element.status == PurchaseStatus.pending) {
        Fluttertoast.showToast(msg: "pending");
      } else if (element.status == PurchaseStatus.error) {
        Fluttertoast.showToast(msg: "Something went wrong");
      } else if (element.status == PurchaseStatus.restored) {
        Fluttertoast.showToast(msg: "Restored");
        DateTime? purchaseDate =
            element.transactionDate != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(element.transactionDate!),
                )
                : null;

        if (purchaseDate != null) {
          // In legacy flow this stored local entitlement; removed to rely on Firestore
          Fluttertoast.showToast(msg: 'Purchase restored');
        }
      } else if (element.status == PurchaseStatus.purchased) {
        Fluttertoast.showToast(msg: "purchased");
      }
    }
  }

  Future<void> buy() async {
    // SECURITY CHECK 1: Block duplicate purchase if already premium
    if (isPremium) {
      Fluttertoast.showToast(msg: 'You are already Premium');
      return;
    }

    // SECURITY CHECK 2: Auth gate - require authentication first
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

    // SECURITY CHECK 3: Account activation gating - refresh auth state then check email verification
    try {
      await user.reload();
      await user.getIdToken(true); // force refresh to update claims like email_verified
    } catch (_) {}
    // Use centralized gating with localization
    if (!_appUserService.checkAccountActivation('premium')) {
      return;
    }

    // SECURITY CHECK 3: After login, verify user doesn't have active premium
    try {
    // Attempt to read subscription; on permission issues, refresh token once and retry
    Future<DocumentSnapshot<Map<String, dynamic>>> readSub() => FirebaseFirestore
      .instance
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
            // Update local state and block purchase
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

    // SECURITY CHECK 4: Double-check local state before proceeding
    if (isPremium) {
      Fluttertoast.showToast(msg: 'You are already Premium');
      return;
    }

    // Now show promo code dialog after all security checks pass
    await _showPromoCodeDialog();
  }

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
                          // Skip promo code and proceed to checkout
                          Get.back();
                          _proceedToCheckout();
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
                            _proceedToCheckout();
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

  Future<void> _proceedToCheckout() async {
    // Map selected index to plan type conservatively (monthly/yearly)
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

    try {
      // SECURITY: Call backend function which should also verify user doesn't have active subscription
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('createChargilyPayment');
      final result = await callable.call({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'planType': planType,
        // Add timestamp for backend validation
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        // Include promo code if valid
        if (isPromoValid && promoCode.isNotEmpty) 'promoCode': promoCode,
      });

      final data = result.data as Map;
      final url = Uri.parse(data['checkoutUrl'] as String);

      // SECURITY CHECK 5: Final check before redirecting to payment
      if (isPremium) {
        Fluttertoast.showToast(
          msg: 'Subscription status changed. Payment cancelled.',
        );
        return;
      }

      // Open checkout in external browser (Chrome on Android, Safari on iOS)
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

      // Inform the user and rely on Firestore listener to reflect premium status
      Fluttertoast.showToast(
        msg: 'Complete payment in your browser. Return to the app when done.',
      );
    } catch (e) {
      if (kDebugMode) print('createChargilyPayment error: $e');

      // Handle specific error types
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already-subscribed') ||
          errorMsg.contains('already') ||
          errorMsg.contains('premium') ||
          errorMsg.contains('active')) {
        Fluttertoast.showToast(msg: 'You already have an active subscription');
        // Force refresh subscription status from server
        isPremium = true;
        update();
        _subscribeToFirestore();
      } else if (errorMsg.contains('unauthenticated')) {
        Fluttertoast.showToast(msg: 'Please login and try again');
        // Clear local auth state
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

  onChangeSelectedIndex(int index) {
    selected = index;
    update(['plan_selection']); // Update specific GetBuilder
  }

  // Remove client-side entitlement flags; rely on Firestore listener in _subscribeToFirestore
  // to update isPremium based on server-side subscription document
  getPremium() async {
    // No-op: isPremium is managed by Firestore subscription stream
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

  // Promo code functionality
  void updatePromoCode(String code) {
    promoCode = code.toUpperCase().trim();
    // Reset validation state when code changes
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

    // Extract number from price string (e.g., "3500 DZD" -> 3500)
    final match = RegExp(r'[\d.,]+').stringMatch(originalPrice);
    if (match == null) return originalPrice;

    final numericPrice = double.tryParse(match.replaceAll(',', ''));
    if (numericPrice == null) return originalPrice;

    final discountedPrice = (numericPrice * (1 - discountRate)).round();
    return originalPrice.replaceAll(match, discountedPrice.toString());
  }

  String getOriginalPrice(String currentPrice) {
    if (!isPromoValid || discountRate == 0.0) return '';

    // Extract number from price string
    final match = RegExp(r'[\d.,]+').stringMatch(currentPrice);
    if (match == null) return '';

    final numericPrice = double.tryParse(match.replaceAll(',', ''));
    if (numericPrice == null) return '';

    final originalPrice = (numericPrice / (1 - discountRate)).round();
    return currentPrice.replaceAll(match, originalPrice.toString());
  }

  @override
  void onClose() {
    streamSubscription.cancel();
    _firestoreSubscription?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }
}
