import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'meal_sync_service.dart';
import 'notification_preferences_service.dart';

class FirebaseMessagingService extends GetxService {
  static const String _logTag = 'FCMService';
  
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  final RxBool _isInitialized = false.obs;
  final RxString _currentToken = ''.obs;
  
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

  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint('[$_logTag] Permission status: ${settings.authorizationStatus}');
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
      debugPrint('[$_logTag] Received foreground message: ${message.messageId}');
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
      Get.showSnackbar(GetSnackBar(
        title: message.notification?.title ?? 'Notification',
        message: message.notification!.body!,
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      ));
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
      final String? token = await _firebaseMessaging.getToken();
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
          debugPrint('[$_logTag] No authenticated user, skipping token storage');
        }
        return;
      }

      final tokenData = {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set(tokenData, SetOptions(merge: true));

      // Ensure main user document exists for notification queries
      await MealSyncService().ensureUserDocument();
      
      // Sync notification preferences to Firestore for server-side FCM
      await _syncNotificationPreferences();

      if (kDebugMode) {
        debugPrint('[$_logTag] Token stored in Firestore for user: ${user.uid}');
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

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .update({
        'isActive': false,
        'removedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('[$_logTag] Token marked as inactive for user: ${user.uid}');
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
