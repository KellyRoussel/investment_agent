import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const valueText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
