import 'package:flutter/material.dart';
import '../constant/FontFamily.dart';

class AppTheme {
  static final dark = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.white,
      focusColor: Colors.orange,
      cardColor:   const Color(0xff151515),
      hintColor: Colors.black,
      hoverColor: Color(0xff5e5e5e),
      highlightColor: Colors.white,
      textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Colors.white,fontSize: 16,fontFamily: poppinsSemiBold,fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: Colors.white,fontFamily: poppins,fontWeight: FontWeight.w500,fontSize: 16),
          titleMedium: TextStyle(color: Colors.white,fontFamily: poppins,fontWeight: FontWeight.w500,fontSize: 18),
          headlineMedium: TextStyle(color: Colors.white,fontSize: 20,fontFamily: poppinsSemiBold,fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.white,fontSize: 22,fontFamily: poppins,fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.black,fontSize: 18,fontWeight: FontWeight.w500,fontFamily: poppinsSemiBold)
      ));

  static final light = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.black,
      focusColor: Colors.orange,
      hintColor: Colors.white,
      cardColor: Color(0xffeae9e9),
      highlightColor: Colors.black,
      hoverColor: Colors.white,
      textTheme: const TextTheme(
          titleSmall: TextStyle(color: Colors.black,fontFamily: poppins,fontWeight: FontWeight.w500,fontSize: 16),
          titleMedium: TextStyle(color: Colors.black,fontFamily: poppins,fontWeight: FontWeight.w500,fontSize: 18),
          headlineSmall: TextStyle(color: Colors.black,fontSize: 16,fontFamily: poppinsSemiBold,fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(color: Colors.black,fontSize: 20,fontFamily: poppinsSemiBold,fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.black,fontSize: 22,fontFamily: poppins,fontWeight: FontWeight.bold),
          bodySmall: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.w500,fontFamily: poppinsSemiBold)
      ));
}
