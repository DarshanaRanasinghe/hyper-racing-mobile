import 'package:flutter/material.dart';

class AppColors {
  // ✅ Light UI (white)
  static const Color background = Color(0xFFF6F7FB); // soft white
  static const Color card = Color(0xFFFFFFFF);

  // ✅ keep your purple theme
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleAccent = Color(0xFFB388FF);

  // Text colors for light UI
  static const Color text = Color(0xFF111827);
  static const Color subtext = Color(0xFF6B7280);

  // Bubble colors (light)
  static const Color bubbleMe = Color(0xFFE7DDFF);
  static const Color bubbleOther = Color(0xFFF1F3F7);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.purple,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    colorScheme: const ColorScheme.light(
      primary: AppColors.purple,
      secondary: AppColors.purpleAccent,
      surface: AppColors.card,
      background: AppColors.background,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.subtext,
      textColor: AppColors.text,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
    ),
  );
}
