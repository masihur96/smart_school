import 'package:flutter/material.dart';

/// Centralized color palette for the application
/// Keep all colors here to maintain design consistency
class AppColors {
  AppColors._(); // prevents instantiation

  /* --------------------------------------------------
   * Neutral Colors
   * -------------------------------------------------- */
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF898989);
  static const Color darkGrey = Color(0xFF424242);

  /* --------------------------------------------------
   * Text Colors
   * -------------------------------------------------- */
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF47475F);
  static const Color textMuted = Color(0xFFB8B8B8);
  static const Color textOnDark = Color(0xFFFFFFFF);

  /* --------------------------------------------------
   * Brand / Primary Colors
   * -------------------------------------------------- */
  static const Color primary = Color(0xFF1B67F6);
  static const Color primarySoft = Color(0xFFF0F0F0);
  static const Color primaryDark = Color(0xFF2B3674);
  static const Color primaryAdmin = Colors.purple;

  /* --------------------------------------------------
   * Background Colors
   * -------------------------------------------------- */
  static const Color backgroundLight = Color(0xFFF8F9FC);
  static const Color backgroundDark = Color(0xFF15181E);

  /* --------------------------------------------------
   * Button Colors
   * -------------------------------------------------- */
  static const Color buttonPrimary = Color(0xFF1B67F6);
  static const Color buttonSecondary = Color(0xFFFEDF89);

  /* --------------------------------------------------
   * Status / Feedback Colors
   * -------------------------------------------------- */
  static const Color success = Color(0xFF0AC51D);
  static const Color error = Color(0xFFFF005C);
  static const Color warning = Color(0xFFFFC107);
  static const Color loader = Color(0xFF898989);

  /* --------------------------------------------------
   * Accent / Utility Colors
   * -------------------------------------------------- */
  static const Color accentBlue = Color(0xFF0000FF);
  static const Color border = Color(0xFF424242);

  /* --------------------------------------------------
   * Modern UI / Glass / Gradient Set
   * -------------------------------------------------- */
  static const Color glassLight = Color(0xFFE1E5F2);
  static const Color glassMid = Color(0xFFBFDBF7);
  static const Color glassPrimary = Color(0xFF1F7A8C);
  static const Color glassDark = Color(0xFF022B3A);
}
