import 'package:flutter/material.dart';
import '../constant/AppColor.dart';
import '../constant/FontFamily.dart';

class AppTheme {
  static final dark = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColor.darkBackground,
    primaryColor: AppColor.darkText,
    focusColor: AppColor.primaryOrange,
    cardColor: AppColor.darkCard,
    hintColor: AppColor.darkBackground,
    // dark overlay states
    hoverColor: AppColor.neutralGrey800.withOpacity(0.12),
    highlightColor: AppColor.neutralGrey800.withOpacity(0.12),
    dividerColor: AppColor.darkBorder,

    colorScheme: const ColorScheme.dark(
      primary: AppColor.primaryOrange,
      secondary: AppColor.accentOrange,
      surface: AppColor.darkSurface,
      error: AppColor.error,
      onPrimary: AppColor.neutralWhite,
      onSecondary: AppColor.neutralWhite,
      onSurface: AppColor.darkText,
      onError: AppColor.neutralWhite,
    ),

    textTheme: _textTheme(isDark: true),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.darkBackground,
      foregroundColor: AppColor.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColor.darkText,
        fontSize: 20,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColor.darkCard,
      shadowColor: Colors.black.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );

  static final light = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColor.neutralWhite,
    primaryColor: AppColor.neutralGrey900,
    focusColor: AppColor.primaryOrange,
    hintColor: AppColor.neutralWhite,
    cardColor: AppColor.neutralGrey50,
    // light overlay states
    highlightColor: AppColor.neutralGrey100.withOpacity(0.5),
    hoverColor: AppColor.neutralGrey100.withOpacity(0.3),
    splashColor: AppColor.neutralGrey100.withOpacity(0.4),
    dividerColor: AppColor.neutralGrey200,

    colorScheme: const ColorScheme.light(
      primary: AppColor.primaryOrange,
      secondary: AppColor.accentOrange,
      surface: AppColor.neutralGrey50,
      error: AppColor.error,
      onPrimary: AppColor.neutralWhite,
      onSecondary: AppColor.neutralWhite,
      onSurface: AppColor.neutralGrey900,
      onError: AppColor.neutralWhite,
    ),

    textTheme: _textTheme(isDark: false),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.neutralWhite,
      foregroundColor: AppColor.neutralGrey900,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColor.neutralGrey900,
        fontSize: 20,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColor.neutralWhite,
      shadowColor: AppColor.lightShadow,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );

  // typography with arabic fallbacks
  static TextTheme _textTheme({bool isDark = false}) {
    final color = isDark ? AppColor.darkText : AppColor.neutralGrey900;
    final secondaryColor =
        isDark ? AppColor.darkTextSecondary : AppColor.neutralGrey600;
    final inverseColor =
        isDark ? AppColor.neutralGrey900 : AppColor.neutralWhite;

    return TextTheme(
      displayLarge: TextStyle(
        color: color,
        fontSize: 32,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        color: color,
        fontSize: 28,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        color: color,
        fontSize: 24,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),

      headlineLarge: TextStyle(
        color: color,
        fontSize: 22,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        color: color,
        fontSize: 20,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        color: color,
        fontSize: 18,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      titleLarge: TextStyle(
        color: color,
        fontSize: 16,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: poppins,
        fontFamilyFallback: const [notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        color: secondaryColor,
        fontSize: 12,
        fontFamily: poppins,
        fontFamilyFallback: const [notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      bodyLarge: TextStyle(
        color: color,
        fontSize: 16,
        fontFamily: poppins,
        fontFamilyFallback: const [notoSansArabic],
        fontWeight: FontWeight.normal,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: poppins,
        fontFamilyFallback: const [notoSansArabic],
        fontWeight: FontWeight.normal,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        color: inverseColor,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
      ),

      labelLarge: TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        color: color,
        fontSize: 12,
        fontFamily: poppinsSemiBold,
        fontFamilyFallback: const [notoSansArabicSemiBold, notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        color: secondaryColor,
        fontSize: 10,
        fontFamily: poppins,
        fontFamilyFallback: const [notoSansArabic],
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
    );
  }
}
