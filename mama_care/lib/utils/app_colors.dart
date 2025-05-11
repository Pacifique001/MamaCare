// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE91E63);
  static const Color secondary = Color(0xFFF06292);
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF212121);
  static const Color primaryLight = Color(0xFFFF80AB);
  static const Color accent = Color(0xFFFFC107);
  static const Color textDark = Color(0xFF333333);
  static const Color textGrey = Color(0xFF757575);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB00020);

  // --- ADDED COLORS ---
  static const Color backgroundLight = Color(
    0xFFFAFAFA,
  ); // Example: Very light grey
  static const Color greyLight = Color(
    0xFFE0E0E0,
  ); // Example: Light grey for borders/dividers
  // --------------------

  // Dark theme
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  // utils/app_colors.dart

  static final Color textSecondary = Color(0xFF666666); // Medium Gray
  static final Color textHint = Color(0xFF999999); // Light Gray
  static final Color border = Color(0xFFDDDDDD); // Very Light Gray
  static final Color divider = Color(0xFFEEEEEE); // Extremely Light Gray

  static final Color success = Color(0xFF2ECC71); // Green
  static final Color warning = Color(0xFFF39C12); // Orange
  static final Color info = Color(0xFF3498DB); // Blue
  static final Color white = Colors.white;

  // Dark Mode Colors

  static final Color secondaryDark = Color(0xFF5DADE2); // Lighter Blue
  static final Color accentDark = Color(0xFFEC7063); // Lighter Red

  static final Color surfaceDark = Color(0xFF1E1E1E);
  static final Color surfaceLight = Color.fromARGB(
    255,
    255,
    255,
    255,
  ); // Dark Gray

  static final Color textSecondaryDark = Color(0xFFBBBBBB); // Light Gray
  static final Color textHintDark = Color(0xFF888888); // Medium Gray
  static final Color borderDark = Color(0xFF444444); // Dark Gray
  static final Color dividerDark = Color(0xFF333333); // Very Dark Gray
  static final Color errorDark = Color(0xFFEC7063); // Lighter Red
  static final Color successDark = Color(0xFF7DCEA0); // Lighter Green
  static final Color warningDark = Color(0xFFF5B041); // Lighter Orange
  static final Color infoDark = Color(0xFF5DADE2); // Lighter Blue
}
