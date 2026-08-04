import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const background = Color(0xFFF4F4F4);
  static const accent = Color(0xFF6E8DA6);
  static const text = Color(0xFF333333);
}

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.background,
    ),
    fontFamily: 'Roboto',
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF171B1F),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF20262C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF171B1F),
      foregroundColor: Colors.white,
    ),
    fontFamily: 'Roboto',
  );

  static const brandName = 'Powered by Elektrik Baterai Indonesia';

  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const darkSystemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF171B1F),
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
