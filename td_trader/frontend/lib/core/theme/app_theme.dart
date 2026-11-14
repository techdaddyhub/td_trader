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
      fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.binanceGold,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          height: 1.25,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 14,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.binanceGold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.binanceGold,
          foregroundColor: const Color(0xFF0B0E11),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(
            color: AppColors.binanceGold, fontSize: 12, fontWeight: FontWeight.w600),
        helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        errorStyle: const TextStyle(color: AppColors.bearishRed, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.binanceGold, width: 1.5),
        ),
      ),
    );
  }
}
