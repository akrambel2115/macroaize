
import 'package:flutter/material.dart';

class AppColor {
  // Legacy colors (keeping for compatibility)
  static Color grey = Colors.grey;
  static Color white = Colors.white;
  static Color black = Colors.black;

  // Modern Design System - Soft & Contemporary Color Palette
  
  // Primary Brand Colors - Updated to Orange Theme
  static const Color primaryOrange = Color(0xFFfb7414);
  static const Color primaryOrangeLight = Color(0xFFff8c42);
  static const Color primaryOrangeDark = Color(0xFFe66100);
  
  // Legacy green aliases (for backward compatibility during transition)
  static const Color primaryGreen = primaryOrange;
  static const Color primaryGreenLight = primaryOrangeLight;
  static const Color primaryGreenDark = primaryOrangeDark;
  
  // Accent Colors
  static const Color accentOrange = Color(0xFFFF9F40);
  static const Color accentOrangeLight = Color(0xFFFFB366);
  static const Color accentOrangeDark = Color(0xFFE88B2A);
  
  // Neutral Colors - Light Theme
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGrey50 = Color(0xFFF8F9FA);
  static const Color neutralGrey100 = Color(0xFFF1F3F4);
  static const Color neutralGrey200 = Color(0xFFE8EAED);
  static const Color neutralGrey300 = Color(0xFFDADCE0);
  static const Color neutralGrey400 = Color(0xFFBDC1C6);
  static const Color neutralGrey500 = Color(0xFF9AA0A6);
  static const Color neutralGrey600 = Color(0xFF80868B);
  static const Color neutralGrey700 = Color(0xFF5F6368);
  static const Color neutralGrey800 = Color(0xFF3C4043);
  static const Color neutralGrey900 = Color(0xFF202124);
  
  // Neutral Colors - Dark Theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkText = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  
  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient Colors - Updated for Orange Theme
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, accentOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [neutralWhite, neutralGrey50],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkCard, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadow Colors
  static Color lightShadow = Colors.black.withOpacity(0.06);
  static Color mediumShadow = Colors.black.withOpacity(0.12);
  static Color heavyShadow = Colors.black.withOpacity(0.25);
  
  // Nutrition Colors (Modern & Accessible)
  static const Color proteinColor = Color(0xFFFF6B6B);
  static const Color carbsColor = Color(0xFF4ECDC4);
  static const Color fatsColor = Color(0xFFFFE66D);
  static const Color calorieColor = Color(0xFF6BCF7F);
  
    // New colors for enhanced design system
  static const Color secondary = Color(0xFF6B73FF);
  static const Color accent = Color(0xFFFF6B9D);
  static const Color tertiary = Color(0xFFFFB347);
  // History-specific accent (alias to primaryOrange to keep central control)
  static const Color historyAccent = primaryOrange;
}