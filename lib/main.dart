import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'shared/services/app_tips_service.dart';
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
  } catch (_) {
    if (kDebugMode) print('No .env.macroaize file found (optional)');
  }
  
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
    if ((iosKey == null || iosKey.isEmpty) || (androidKey == null || androidKey.isEmpty)) {
      if (kDebugMode) print('Dotenv returned empty keys, attempting manual .env parse...');
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
        if (kDebugMode) print('Manually parsed env keys: ${parsed.keys.toList()}');
        iosKey = parsed['IOS_PUBLIC_SDK_KEY'] ?? iosKey;
        androidKey = parsed['ANDROID_PUBLIC_SDK_KEY'] ?? androidKey;

        // test store flags
        final testKey = parsed['REVENUECAT_TEST_SDK_KEY'];
        final useTestRaw = parsed['USE_REVENUECAT_TEST_STORE'];
        final useTest = (useTestRaw ?? '').toLowerCase().trim();
        final useTestStore = useTest == 'true' || useTest == '1' || useTest == 'yes' || useTest == 'y';
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
    final useTestStoreEnv = useTestEnv == 'true' || useTestEnv == '1' || useTestEnv == 'yes' || useTestEnv == 'y';
    if ((iosKey == null || androidKey == null) && useTestStoreEnv && testKeyEnv != null && testKeyEnv.startsWith('test_')) {
      if (kDebugMode) print('Using RevenueCat Test Store key from dotenv');
      iosKey = testKeyEnv;
      androidKey = testKeyEnv;
    }

    final iosKeyFinal = iosKey ?? '';
    final androidKeyFinal = androidKey ?? '';
    if (kDebugMode) {
      print('Passing keys to RevenueCat: iOS=${iosKeyFinal.isNotEmpty} (${iosKeyFinal.length} chars), Android=${androidKeyFinal.isNotEmpty} (${androidKeyFinal.length} chars)');
      if (iosKeyFinal.isNotEmpty) {
        print('iOS key: ${iosKeyFinal.substring(0, 10)}...');
      }
      if (androidKeyFinal.isNotEmpty) {
        print('Android key: ${androidKeyFinal.substring(0, 10)}...');
      }
    }

    await RevenueCatService().init(iosApiKey: iosKeyFinal, androidApiKey: androidKeyFinal);
  } catch (e) {
    if (kDebugMode) print('RevenueCat init failed: $e');
  }
  try {
    if (!Get.isRegistered<UpdateGuardService>()) {
      Get.put<UpdateGuardService>(UpdateGuardService(), permanent: true);
    }
  } catch (_) {}
  try {
    // register app user service
    if (!Get.isRegistered<AppUserService>()) {
      final svc = AppUserService();
      Get.put<AppUserService>(svc, permanent: true);
      try {
        svc.initialize();
      } catch (_) {}
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

  try {
    if (!Get.isRegistered<AppTipsService>()) {
      await Get.putAsync(() => AppTipsService().init());
    }
  } catch (_) {}

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (kDebugMode) print('FCM Token: $fcmToken');
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
