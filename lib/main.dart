import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'MainController.dart';
import 'ThemeService/AppTheme.dart';
import 'ThemeService/ThemeController.dart';
import 'constant/DatabaseHelper.dart';
import 'constant/LocalString.dart';
import 'routes/app_pages.dart';
import 'screens/PremiumScreen/PremiumController.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(  SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  Get.put(MainController());
  cameras = await availableCameras();
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
    MainController controller = Get.put(MainController());
    Get.put(PremiumController());

    // Arabic made the default + fallback locale (migration Aug 2025)
    return GetMaterialApp(
      translations: LocalString(),
      locale: const Locale('ar','AR'),
      fallbackLocale: const Locale('ar','AR'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: controller.isLogin ? AppPages.home : AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
