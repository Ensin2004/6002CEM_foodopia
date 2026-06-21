import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Defines behavior for app theme.
/// Contains the light theme configuration for the application.
class AppTheme {
  /// Light theme configuration.
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // =========================================================================
    // 🎨 COLOR SYSTEM
    // =========================================================================
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF4F5F4),
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: Colors.white,

    // =========================================================================
    // 📱 APP BAR
    // =========================================================================
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.grey.withValues(alpha: 0.35),
      centerTitle: true,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border, width: 0.5),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: 20,
      ),
    ),

    // =========================================================================
    // 📝 TEXT SYSTEM (industry standard)
    // =========================================================================
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ),

    // =========================================================================
    // 📝 INPUT DECORATION
    // =========================================================================
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.55),
        fontSize: 14,
      ),
    ),

    // =========================================================================
    // 🔘 BUTTON DEFAULT STYLE
    // =========================================================================
    // elevatedButtonTheme: ElevatedButtonThemeData(
    //   style: ElevatedButton.styleFrom(
    //     backgroundColor: AppColors.primary,
    //     foregroundColor: Colors.white,
    //     padding: const EdgeInsets.symmetric(vertical: 16),
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(8),
    //     ),
    //   ),
    // ),
  );
}