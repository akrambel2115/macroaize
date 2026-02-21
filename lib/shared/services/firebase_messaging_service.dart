import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'meal_sync_service.dart';
import 'notification_preferences_service.dart';

const _kDeviceTokensCollection = 'deviceTokens';

class FirebaseMessagingService extends GetxService {
  static const String _logTag = 'FCMService';

  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final RxBool _isInitialized = false.obs;
  final RxString _currentToken = ''.obs;

  StreamSubscription<User?>? _authSubscription;

  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firebaseMessaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  bool get isInitialized => _isInitialized.value;
  String get currentToken => _currentToken.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeMessaging();
    _listenToAuthChanges();
  }

  Future<void> _initializeMessaging() async {
    try {
      if (kDebugMode) {
        debugPrint('[$_logTag] Initializing Firebase Messaging...');
      }

      await _requestPermissions();
      _setupMessageHandlers();
      await _handleTokenManagement();

      _isInitialized.value = true;

      if (kDebugMode) {
        debugPrint('[$_logTag] Firebase Messaging initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error initializing Firebase Messaging: $e');
      }
      // allow app without fcm
    }
  }

  void _listenToAuthChanges() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      final token = _currentToken.value;
      if (token.isEmpty) return;

      if (user != null) {
        await _storeTokenInFirestore(token);
      }
    });
  }

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (kDebugMode) {
        debugPrint(
          '[$_logTag] Permission status: ${settings.authorizationStatus}',
        );
      }

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          if (kDebugMode) {
            debugPrint('[$_logTag] Notifications are authorized');
          }
          break;
        case AuthorizationStatus.provisional:
          if (kDebugMode) {
            debugPrint('[$_logTag] Notifications are provisionally authorized');
          }
          break;
        case AuthorizationStatus.denied:
          if (kDebugMode) {
            debugPrint('[$_logTag] Notifications are denied');
          }
          break;
        case AuthorizationStatus.notDetermined:
          if (kDebugMode) {
            debugPrint('[$_logTag] Notification permissions not determined');
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error requesting permissions: $e');
      }
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _firebaseMessaging.getInitialMessage().then(_handleNotificationTap);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[$_logTag] Received foreground message: ${message.messageId}',
      );
      debugPrint('[$_logTag] Title: ${message.notification?.title}');
      debugPrint('[$_logTag] Body: ${message.notification?.body}');
      debugPrint('[$_logTag] Data: ${message.data}');
    }
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage? message) {
    if (message == null) return;

    if (kDebugMode) {
      debugPrint('[$_logTag] Notification tapped: ${message.messageId}');
      debugPrint('[$_logTag] Data: ${message.data}');
    }
    _handleNotificationNavigation(message.data);
  }

  void _showLocalNotification(RemoteMessage message) {
    if (message.notification?.body != null) {
      Get.rawSnackbar(
        title: message.notification?.title ?? 'Notification',
        message: message.notification!.body!,
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];

    switch (type) {
      case 'promo_used':
        if (Get.currentRoute != '/influencer') {
          Get.toNamed('/influencer');
        }
        break;
      case 'goal_progress':
        if (Get.currentRoute != '/progress') {
          Get.toNamed('/progress');
        }
        break;
      case 'meal_reminder':
        if (Get.currentRoute != '/food-tracker') {
          Get.toNamed('/food-tracker');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleTokenManagement() async {
    try {
      final String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              '[$_logTag] getToken() timed out – APNS token may not be available',
            );
          }
          return null;
        },
      );
      if (token != null) {
        _currentToken.value = token;
        await _storeTokenInFirestore(token);

        if (kDebugMode) {
          debugPrint('[$_logTag] Initial FCM token: $token');
        }
      }

      _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
        _currentToken.value = newToken;
        await _storeTokenInFirestore(newToken);

        if (kDebugMode) {
          debugPrint('[$_logTag] Token refreshed: $newToken');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error handling token: $e');
      }
    }
  }

  Future<void> _storeTokenInFirestore(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint(
            '[$_logTag] No authenticated user, skipping token storage',
          );
        }
        return;
      }

      final ownershipRef = _firestore
          .collection(_kDeviceTokensCollection)
          .doc(token);

      await _firestore.runTransaction((tx) async {
        final ownershipSnap = await tx.get(ownershipRef);

        final previousOwnerUid =
            ownershipSnap.exists
                ? (ownershipSnap.data()?['ownerUid'] as String?)
                : null;

        // Deactivate the token under the previous owner if it's a different account.
        if (previousOwnerUid != null && previousOwnerUid != user.uid) {
          final oldTokenRef = _firestore
              .collection('users')
              .doc(previousOwnerUid)
              .collection('fcmTokens')
              .doc(token);

          tx.set(oldTokenRef, {
            'isActive': false,
            'supersededByUid': user.uid,
            'supersededAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (kDebugMode) {
            debugPrint(
              '[$_logTag] Token ownership transferred from $previousOwnerUid → ${user.uid}',
            );
          }
        }

        // Claim ownership for the current user.
        tx.set(ownershipRef, {
          'ownerUid': user.uid,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final newTokenRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token);

        final newTokenSnap = await tx.get(newTokenRef);
        final tokenFields = <String, dynamic>{
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'lastUsed': FieldValue.serverTimestamp(),
          'isActive': true,
        };
        if (!newTokenSnap.exists) {
          tokenFields['createdAt'] = FieldValue.serverTimestamp();
        }
        tx.set(newTokenRef, tokenFields, SetOptions(merge: true));
      });

      await MealSyncService().ensureUserDocument();
      await _syncNotificationPreferences();

      if (kDebugMode) {
        debugPrint(
          '[$_logTag] Token stored in Firestore for user: ${user.uid}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error storing token in Firestore: $e');
      }
    }
  }

  Future<void> removeTokenFromFirestore() async {
    try {
      final User? user = _auth.currentUser;
      final String token = _currentToken.value;

      if (user == null || token.isEmpty) return;

      final batch = _firestore.batch();

      // Mark the token inactive under the user's subcollection.
      batch.set(
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token),
        {'isActive': false, 'removedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      batch.delete(_firestore.collection(_kDeviceTokensCollection).doc(token));

      await batch.commit();

      if (kDebugMode) {
        debugPrint('[$_logTag] Token deregistered for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error removing token from Firestore: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('[$_logTag] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error subscribing to topic $topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('[$_logTag] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error unsubscribing from topic $topic: $e');
      }
    }
  }

  Future<void> _syncNotificationPreferences() async {
    try {
      if (Get.isRegistered<NotificationPreferencesService>()) {
        final prefsService = Get.find<NotificationPreferencesService>();
        await prefsService.syncOnLogin();

        if (kDebugMode) {
          debugPrint('[$_logTag] Notification preferences synced to Firestore');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_logTag] Error syncing notification preferences: $e');
      }
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    if (_auth.currentUser != null) {
      removeTokenFromFirestore();
    }
    super.onClose();
  }
}

// background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCMService: Background message received: ${message.messageId}');
    debugPrint('FCMService: Title: ${message.notification?.title}');
    debugPrint('FCMService: Body: ${message.notification?.body}');
  }
}
