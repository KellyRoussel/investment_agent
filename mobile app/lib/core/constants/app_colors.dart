import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFF0A0E27);
  static const surface = Color(0xFF151932);
  static const border = Color(0xFF1F2544);
  static const hover = Color(0xFF252B4A);

  // Accents
  static const cyan = Color(0xFF22D3EE);
  static const cyanDark = Color(0xFF06B6D4);
  static const purple = Color(0xFFA78BFA);
  static const purpleDark = Color(0xFF8B5CF6);
  static const pink = Color(0xFFF472B6);
  static const pinkDark = Color(0xFFEC4899);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Text
  static const textPrimary = Color(0xFFF3F4F6);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  // Chart palette
  static const chartColors = [
    cyan,
    purple,
    pink,
    success,
    warning,
    Color(0xFF3B82F6),
    danger,
    purpleDark,
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  // Gradients
  static const gradientCyanPurple = LinearGradient(
    colors: [cyan, purple],
  );

  static const gradientButton = LinearGradient(
    colors: [cyan, cyanDark],
  );

  static const gradientDanger = LinearGradient(
    colors: [danger, Color(0xFFDC2626)],
  );
}
