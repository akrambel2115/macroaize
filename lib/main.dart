import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'main_controller.dart';
import 'shared/services/app_user_service.dart';
import 'shared/services/app_config_service.dart';
import 'shared/services/update_guard_service.dart';
import 'shared/services/revenuecat_service.dart';
import 'shared/services/firebase_messaging_service.dart';
import 'shared/services/app_tips_service.dart';
import 'shared/services/usage_service.dart';
import 'shared/services/remote_config_service.dart';
import 'shared/services/local_notification_service.dart';
import 'shared/services/notification_preferences_service.dart';
import 'shared/services/promo_code_service.dart';
import 'ThemeService/app_theme.dart';
import 'ThemeService/theme_controller.dart';
import 'constant/database_helper.dart';
import 'constant/local_string.dart';
import 'routes/app_pages.dart';
import 'screens/PremiumScreen/premium_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/auth/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load env files
  try {
    if (kDebugMode) print('Loading .env file...');
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print('.env loaded successfully');
      print('Keys in .env: ${dotenv.env.keys.toList()}');
    }
  } catch (e) {
    if (kDebugMode) print('Failed to load .env: $e');
  }

  try {
    await dotenv.load(fileName: ".env.macroaize");
    if (kDebugMode) print('.env.macroaize loaded');
  } catch (e) {
    if (kDebugMode) print('No .env.macroaize file found (optional): $e');
  }

  HttpOverrides.global = MyHttpOverrides();
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) print('Firebase init failed: $e');
    }
  }
  try {
    await Future.wait([
      initializeDateFormatting('en'),
      initializeDateFormatting('fr'),
      initializeDateFormatting('ar'),
    ]);
  } catch (e) {
    if (kDebugMode) print('DateFormatting init failed: $e');
  }
  Get.put(UsageService());
  Get.put(MainController());
  try {
    await Get.putAsync<AppConfigService>(() async => AppConfigService().load());
  } catch (e) {
    if (kDebugMode) print('AppConfigService load failed: $e');
  }
  try {
    // init revenuecat
    if (kDebugMode) {
      print('dotenv.env map: ${dotenv.env}');
      print('Trying to get IOS_PUBLIC_SDK_KEY...');
    }
    String? iosKey = dotenv.env['IOS_PUBLIC_SDK_KEY'];
    if (kDebugMode) print('iosKey result: $iosKey');
    String? androidKey = dotenv.env['ANDROID_PUBLIC_SDK_KEY'];
    if (kDebugMode) print('androidKey result: $androidKey');

    // fallback manual parse
    if ((iosKey == null || iosKey.isEmpty) ||
        (androidKey == null || androidKey.isEmpty)) {
      if (kDebugMode) {
        print('Dotenv returned empty keys, attempting manual .env parse...');
      }
      try {
        final raw = await rootBundle.loadString('.env', cache: false);
        final Map<String, String> parsed = {};
        for (final line in raw.split(RegExp(r'\r?\n'))) {
          if (line.trim().isEmpty) continue;
          if (line.trim().startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx <= 0) continue;
          final key = line.substring(0, idx).trim();
          final value = line.substring(idx + 1).trim();
          parsed[key] = value;
        }
        if (kDebugMode) {
          print('Manually parsed env keys: ${parsed.keys.toList()}');
        }
        iosKey = parsed['IOS_PUBLIC_SDK_KEY'] ?? iosKey;
        androidKey = parsed['ANDROID_PUBLIC_SDK_KEY'] ?? androidKey;

        // test store flags
        final testKey = parsed['REVENUECAT_TEST_SDK_KEY'];
        final useTestRaw = parsed['USE_REVENUECAT_TEST_STORE'];
        final useTest = (useTestRaw ?? '').toLowerCase().trim();
        final useTestStore =
            useTest == 'true' ||
            useTest == '1' ||
            useTest == 'yes' ||
            useTest == 'y';
        if (useTestStore && testKey != null && testKey.startsWith('test_')) {
          if (kDebugMode) print('Using RevenueCat Test Store key from .env');
          iosKey = testKey;
          androidKey = testKey;
        }
      } catch (e) {
        if (kDebugMode) print('Manual .env parse failed: $e');
      }
    }

    // check dotenv test flags
    final testKeyEnv = dotenv.env['REVENUECAT_TEST_SDK_KEY'];
    final useTestRawEnv = dotenv.env['USE_REVENUECAT_TEST_STORE'];
    final useTestEnv = (useTestRawEnv ?? '').toLowerCase().trim();
    final useTestStoreEnv =
        useTestEnv == 'true' ||
        useTestEnv == '1' ||
        useTestEnv == 'yes' ||
        useTestEnv == 'y';
    if ((iosKey == null || androidKey == null) &&
        useTestStoreEnv &&
        testKeyEnv != null &&
        testKeyEnv.startsWith('test_')) {
      if (kDebugMode) print('Using RevenueCat Test Store key from dotenv');
      iosKey = testKeyEnv;
      androidKey = testKeyEnv;
    }

    final iosKeyFinal = iosKey ?? '';
    final androidKeyFinal = androidKey ?? '';
    if (kDebugMode) {
      print(
        'Passing keys to RevenueCat: iOS=${iosKeyFinal.isNotEmpty} (${iosKeyFinal.length} chars), Android=${androidKeyFinal.isNotEmpty} (${androidKeyFinal.length} chars)',
      );
      if (iosKeyFinal.isNotEmpty) {
        print('iOS key: ${iosKeyFinal.substring(0, 10)}...');
      }
      if (androidKeyFinal.isNotEmpty) {
        print('Android key: ${androidKeyFinal.substring(0, 10)}...');
      }
    }

    await RevenueCatService().init(
      iosApiKey: iosKeyFinal,
      androidApiKey: androidKeyFinal,
    );
  } catch (e) {
    if (kDebugMode) print('RevenueCat init failed: $e');
  }
  try {
    if (!Get.isRegistered<UpdateGuardService>()) {
      Get.put<UpdateGuardService>(UpdateGuardService(), permanent: true);
    }
  } catch (e) {
    if (kDebugMode) print('UpdateGuardService init failed: $e');
  }
  try {
    // register app user service
    if (!Get.isRegistered<AppUserService>()) {
      final svc = AppUserService();
      Get.put<AppUserService>(svc, permanent: true);
      try {
        svc.initialize();
      } catch (e) {
        if (kDebugMode) print('AppUserService init failed: $e');
      }
    }
  } catch (e) {
    // Outer init errors are non-fatal; services recover lazily.
  }

  // Initialize promo code service for post-login validation
  try {
    PromoCodeService().initialize();
    if (kDebugMode) print('PromoCodeService initialized');
  } catch (e) {
    if (kDebugMode) print('PromoCodeService init failed: $e');
  }

  if (!kIsWeb) {
    try {
      if (!Get.isRegistered<FirebaseMessagingService>()) {
        Get.put<FirebaseMessagingService>(
          FirebaseMessagingService(),
          permanent: true,
        );
      }
    } catch (e) {
      if (kDebugMode) print('FirebaseMessagingService init failed: $e');
    }
  }

  try {
    if (!Get.isRegistered<AppTipsService>()) {
      await Get.putAsync(() => AppTipsService().init());
    }
  } catch (e) {
    if (kDebugMode) print('AppTipsService init failed: $e');
  }

  // Initialize Remote Config service
  if (!kIsWeb) {
    try {
      if (!Get.isRegistered<RemoteConfigService>()) {
        await Get.putAsync<RemoteConfigService>(
          () => RemoteConfigService().init(),
          permanent: true,
        );
        if (kDebugMode) print('RemoteConfigService initialized');
      }
    } catch (e) {
      if (kDebugMode) print('RemoteConfigService init failed: $e');
    }

    // Initialize Notification Preferences service
    try {
      if (!Get.isRegistered<NotificationPreferencesService>()) {
        await Get.putAsync<NotificationPreferencesService>(
          () => NotificationPreferencesService().init(),
          permanent: true,
        );
        if (kDebugMode) print('NotificationPreferencesService initialized');
      }
    } catch (e) {
      if (kDebugMode) print('NotificationPreferencesService init failed: $e');
    }

    // Initialize Local Notification service
    try {
      if (!Get.isRegistered<LocalNotificationService>()) {
        await Get.putAsync<LocalNotificationService>(
          () => LocalNotificationService().init(),
          permanent: true,
        );
        if (kDebugMode) print('LocalNotificationService initialized');
      }
    } catch (e) {
      if (kDebugMode) print('LocalNotificationService init failed: $e');
    }
  }

  if (!kIsWeb) {
    _initFcmTokenAndDb();
  }
  runApp(const MyApp());
}

void _initFcmTokenAndDb() {
  Future(() async {
    try {
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        if (kDebugMode) print('FCM getToken timed out on iOS – continuing without token');
        return null;
      });
      if (kDebugMode) print('FCM Token: $fcmToken');
    } catch (e) {
      if (kDebugMode) print('FCM getToken failed: $e');
    }
    try {
      final dBHelper = DatabaseHelper();
      dBHelper.initDatabase();
    } catch (e) {
      if (kDebugMode) print('DatabaseHelper init failed: $e');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_updateChecked) return;
      _updateChecked = true;
      try {
        await Get.find<UpdateGuardService>().enforceMinimumVersion();
      } catch (e) {
        if (kDebugMode) print('Update guard failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Get.put(PremiumController());

    return GetBuilder<MainController>(
      builder: (mc) {
        return GetMaterialApp(
          translations: LocalString(),
          // default to english
          locale: Locale(
            mc.languageCode.isNotEmpty ? mc.languageCode : 'en',
            mc.countryCode.isNotEmpty ? mc.countryCode : 'US',
          ),
          fallbackLocale: const Locale('en', 'US'),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          defaultTransition: Transition.cupertino,
          popGesture: true,
          // system ui overlay
          builder: (context, child) {
            final isDark = themeController.isDarkMode;
            final bg =
                isDark
                    ? AppTheme.dark.scaffoldBackgroundColor
                    : AppTheme.light.scaffoldBackgroundColor;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: bg,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: bg,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          debugShowCheckedModeBanner: false,
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
        );
      },
    );
  }
}
