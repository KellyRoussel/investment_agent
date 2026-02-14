import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dividerColor: AppColors.border,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.purple,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.cyan,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
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
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      errorStyle: const TextStyle(color: AppColors.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
  );
}
