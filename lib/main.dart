import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'MainController.dart';
import 'shared/services/app_user_service.dart';
import 'ThemeService/AppTheme.dart';
import 'ThemeService/ThemeController.dart';
import 'constant/DatabaseHelper.dart';
import 'constant/LocalString.dart';
import 'routes/app_pages.dart';
import 'screens/PremiumScreen/PremiumController.dart';
import 'package:firebase_core/firebase_core.dart';
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
  } catch (_) {
    // Safe to continue without env in local/dev; defaults will be used
  }
  HttpOverrides.global = MyHttpOverrides();
  // Firebase init (safe no-op on unsupported platforms without config)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // ignore if missing config in local dev; will be required in production
  }
  // Initialize date formatting for supported locales to avoid LocaleDataException
  try {
    await Future.wait([
      initializeDateFormatting('en'),
      initializeDateFormatting('fr'),
      initializeDateFormatting('ar'),
    ]);
  } catch (_) {
    // If locale data fails to initialize, fall back to default formats
  }
  Get.put(MainController());
  // Ensure AppUserService is registered early so Get.find<AppUserService>()
  // calls from views/controllers won't throw. Use putPermanent to avoid
  // accidental disposal during navigation.
  try {
    // Lazily create and register singleton if not already present
    if (!Get.isRegistered<AppUserService>()) {
      final svc = AppUserService();
      Get.put<AppUserService>(svc, permanent: true);
      // initialize will create Firebase-backed streams; errors are caught inside
      try {
        svc.initialize();
      } catch (_) {
        // initialization may fail in test or missing-Firebase environments — it's safe
        // because AppUserService exposes a fallback stream until initialization succeeds.
      }
    }
  } catch (e) {
    // If registration fails, continue — controllers should handle missing service gracefully
  }
  final dBHelper = DatabaseHelper();
  dBHelper.initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.put(ThemeController());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Get.put(MainController());
    Get.put(PremiumController());

    return GetBuilder<MainController>(
      builder: (mc) {
        return GetMaterialApp(
          translations: LocalString(),
          // Default to Arabic for first-time users if MainController hasn't loaded a saved locale yet
          locale: Locale(
            mc.languageCode.isNotEmpty ? mc.languageCode : 'ar',
            mc.countryCode.isNotEmpty ? mc.countryCode : 'SA',
          ),
          fallbackLocale: const Locale('ar', 'SA'),
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
          initialRoute: mc.isLogin ? AppPages.home : AppPages.initial,
          getPages: AppPages.routes,
        );
      },
    );
  }
}
