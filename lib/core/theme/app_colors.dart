import 'package:flutter/material.dart';

/// App gradient colors: linear-gradient(90deg, #252B49, #315D9A, #618DCE, #0490B6, #B7CDED)
class AppColors {
  AppColors._();

  // Primary gradient colors
  static const Color gradient1 = Color(0xFF252B49);
  static const Color gradient2 = Color(0xFF315D9A);
  static const Color gradient3 = Color(0xFF618DCE);
  static const Color gradient4 = Color(0xFF0490B6);
  static const Color gradient5 = Color(0xFFB7CDED);

  // Semantic colors
  static const Color primary = Color(0xFF315D9A);
  static const Color primaryDark = Color(0xFF252B49);
  static const Color primaryLight = Color(0xFF618DCE);
  static const Color accent = Color(0xFF0490B6);
  static const Color accentLight = Color(0xFFB7CDED);

  // Background and surface
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Border and divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Chart colors (derived from gradient)
  static const List<Color> chartColors = [
    gradient1,
    gradient2,
    gradient3,
    gradient4,
    gradient5,
    Color(0xFF4A6FA5),
    Color(0xFF7BA3D3),
    Color(0xFF2E8B9F),
  ];

  // Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradient1, gradient2, gradient3, gradient4, gradient5],
  );

  // Horizontal gradient for app bar
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradient1, gradient2, gradient3],
  );

  // Vertical gradient for cards
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradient2, gradient4],
  );
}
