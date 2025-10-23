import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'MainController.dart';
import 'shared/services/app_user_service.dart';
import 'shared/services/app_config_service.dart';
import 'shared/services/update_guard_service.dart';
import 'shared/services/revenuecat_service.dart';
import 'shared/services/firebase_messaging_service.dart';
import 'ThemeService/AppTheme.dart';
import 'ThemeService/ThemeController.dart';
import 'constant/DatabaseHelper.dart';
import 'constant/LocalString.dart';
import 'routes/app_pages.dart';
import 'screens/PremiumScreen/PremiumController.dart';
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
  try {
    await dotenv.load(fileName: ".env");
    try { await dotenv.load(fileName: ".env.macroaize"); } catch (_) {}
  } catch (_) {}
  HttpOverrides.global = MyHttpOverrides();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}
  try {
    await Future.wait([
      initializeDateFormatting('en'),
      initializeDateFormatting('fr'),
      initializeDateFormatting('ar'),
    ]);
  } catch (_) {}
  Get.put(MainController());
  try {
    await Get.putAsync<AppConfigService>(() async => AppConfigService().load());
  } catch (_) {}
  try {
    // init RevenueCat
    await RevenueCatService().init();
    await RevenueCatService().identifyWithFirebaseUser();
  } catch (_) {}
  try {
    if (!Get.isRegistered<UpdateGuardService>()) {
      Get.put<UpdateGuardService>(UpdateGuardService(), permanent: true);
    }
  } catch (_) {}
  try {
    // Lazily create and register singleton if not already present
    if (!Get.isRegistered<AppUserService>()) {
      final svc = AppUserService();
      Get.put<AppUserService>(svc, permanent: true);
      // initialize will create Firebase-backed streams; errors are caught inside
      try {
        svc.initialize();
      } catch (_) {
        // initialization may fail in test or missing-Firebase environments
      }
    }
  } catch (e) {}

  try {
    if (!Get.isRegistered<FirebaseMessagingService>()) {
      Get.put<FirebaseMessagingService>(
        FirebaseMessagingService(),
        permanent: true,
      );
    }
  } catch (_) {}

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('🔥 FCM Token: $fcmToken');
  final dBHelper = DatabaseHelper();
  dBHelper.initDatabase();
  runApp(const MyApp());
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
      } catch (_) {}
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
          // Default to English for first-time users if MainController hasn't loaded a saved locale yet
          locale: Locale(
            mc.languageCode.isNotEmpty ? mc.languageCode : 'en',
            mc.countryCode.isNotEmpty ? mc.countryCode : 'US',
          ),
          fallbackLocale: const Locale('en', 'US'),
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // apply a global system UI overlay that follows the current theme
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
