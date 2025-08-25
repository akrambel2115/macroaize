import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../SharePrefHelper/SharePref.dart';
import '../../SharePrefHelper/SharePrefKey.dart';
import '../../constant/Appkey.dart';
import '../../routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/auth_modal.dart';

class PremiumController extends GetxController {
  int selected = 0;
  bool isPremium = false;
  InAppPurchase inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<dynamic> streamSubscription;
  Set<String> ids =
      Platform.isAndroid
          ? {
            androidInAppPurchaseIdWeekly,
            androidInAppPurchaseIdMonthly,
            androidInAppPurchaseIdYearly,
          }
          : {
            iOSInAppPurchaseIdWeekly,
            iOSInAppPurchaseIdMonthly,
            iOSInAppPurchaseIdYearly,
          };
  List<ProductDetails> products = [];


  @override
  void onInit() {
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
          // Store the purchase date
          storeDate(purchaseDate.toString());
        }
      } else if (element.status == PurchaseStatus.purchased) {
        Fluttertoast.showToast(msg: "purchased");
      }
    }
  }

  Future<void> buy() async {
    // Auth gate: if not logged in, show modal
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final ok = await AuthModal.show();
      if (!ok) {
        Fluttertoast.showToast(msg: 'Please login to continue');
        return;
      }
    }
    DateTime date = DateTime.now();
    DateTime monthLater = DateTime(date.year, date.month + 1, date.day);
    DateTime yearLater = DateTime(date.year + 1, date.month, date.day);
    try {
      if (products.isNotEmpty) {
        final PurchaseParam param = PurchaseParam(
          productDetails: products[selected],
        );
        inAppPurchase.buyNonConsumable(purchaseParam: param);
        InAppPurchase.instance.purchaseStream.listen((event) {
          for (var element in event) {
            if (element.status == PurchaseStatus.purchased) {
              if (Platform.isIOS) {
                if (element.productID == iOSInAppPurchaseIdMonthly) {
                  storeDate(monthLater.toString());
                } else if (element.productID == iOSInAppPurchaseIdYearly) {
                  storeDate(yearLater.toString());
                }
              } else {
                if (element.productID == androidInAppPurchaseIdMonthly) {
                  storeDate(monthLater.toString());
                } else if (element.productID == androidInAppPurchaseIdYearly) {
                  storeDate(yearLater.toString());
                }
              }
            } else if (element.status == PurchaseStatus.canceled) {
              Fluttertoast.showToast(msg: "Something went wrong");
            }
          }
        });
      } else {
        Fluttertoast.showToast(msg: "No products available for purchase");
      }
    } catch (e) {
      print("error ==> $e");
    }
  }

  storeDate(String dateTime) async {
    // await sharePrefService.addStringToSF(key: 'Premium_Date', value: dateTime);
    await SharedPref.saveString(SharePrefKey.premiumDate, dateTime);
    await SharedPref.saveBool(SharePrefKey.isPremium, true);
    isPremium = true;
    update();
    Get.toNamed(Routes.leadingView);
  }

  onChangeSelectedIndex(int index) {
    selected = index;
    update(['plan_selection']); // Update specific GetBuilder
  }

  getDate() async {
    String premiumDate = await SharedPref.readString(SharePrefKey.premiumDate);
    if (premiumDate.isNotEmpty) {
      DateTime fin = DateTime.parse(premiumDate);
      DateTime date = DateTime.now();
      DateTime time = DateTime(date.year, date.month, date.day);
      if (premiumDate != "") {
        if (time.compareTo(fin) < 0) {
          isPremium = true;
          update();
        } else {
          isPremium = false;
          update();
        }
      }
    }
  }

  getPremium() async {
    isPremium = await SharedPref.readBool(SharePrefKey.isPremium) ?? false;
    if (isPremium) {
      getDate();
    }
    update();
  }

  openPrivacy() async {
    final Uri url = Uri.parse(privacyLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  openTerms() async {
    final Uri url = Uri.parse(termsLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
