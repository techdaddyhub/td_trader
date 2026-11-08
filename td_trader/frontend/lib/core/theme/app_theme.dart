import 'package:flutter/material.dart';

class AppColors {
  // Binance Official Dark Palette
  static const Color background = Color(0xFF0B0E11); // Deepest obsidian void
  static const Color surface = Color(0xFF181A20);    // Binance card surface
  static const Color surfaceLight = Color(0xFF2B313A); // Elevated elements & card highlights
  static const Color border = Color(0xFF2B313A);     // Subtle divider & border

  // Binance Signature Gold & Highlights
  static const Color binanceGold = Color(0xFFF0B90B);      // Binance Primary Gold
  static const Color binanceGoldLight = Color(0xFFFCD535); // Binance Accent Highlight
  static const Color binanceGoldDark = Color(0xFFC99400);  // Binance Deep Amber
  
  // Backward compatibility alias for UI elements
  static const Color primaryCyan = Color(0xFFF0B90B);
  static const Color goldAccent = Color(0xFFF0B90B);

  // Binance High-Visibility Market Dynamics
  static const Color bullishGreen = Color(0xFF0ECB81); // Binance Bullish Green
  static const Color bearishRed = Color(0xFFF6465D);   // Binance Bearish Crimson
  static const Color warningAmber = Color(0xFFF0B90B); // Cautionary Gold

  // Typography Palette
  static const Color textPrimary = Color(0xFFEAECEF);   // High-contrast clean white
  static const Color textSecondary = Color(0xFF848E9C); // Binance muted gray
  static const Color textMuted = Color(0xFF5E6673);     // Inactive hints
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.binanceGold,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.binanceGold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.binanceGold,
          foregroundColor: const Color(0xFF0B0E11),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.binanceGold, width: 1.5),
        ),
      ),
    );
  }
}
