import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF512D38);
  static const surface = Color(0xFF2A1014);
  static const card = Color(0xFFEFECE8);
  static const accent = Color(0xFF8ECFC4); // teal bottom nav
  static const textPrimary = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A1A);
  static const textMuted = Color(0xFFBBBBBB);
  static const iconBg = Color(0xFF1A1A1A);
  static const divider = Color(0xFFDDDAD6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Georgia',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
      ),
    ),
  );
}