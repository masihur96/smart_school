import 'package:flutter/material.dart';
import 'package:smart_school/core/theme/app_colors.dart';

class CustomTheme {
  CustomTheme._();

  /* --------------------------------------------------
   * LIGHT THEME
   * -------------------------------------------------- */
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor: Colors.grey.shade300,
    primaryColor: AppColors.primary,

    /* ---------- Color Scheme ---------- */
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.buttonPrimary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.backgroundLight,
      error: AppColors.error,
    ),

    /* ---------- AppBar ---------- */
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.black),
      titleTextStyle: TextStyle(
        color: AppColors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    /* ---------- Cards ---------- */
    cardTheme: CardThemeData(
      elevation: .5, // shadow intensity
      color: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    /* ---------- Text ---------- */
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.black),
      displayMedium: TextStyle(color: AppColors.black),
      displaySmall: TextStyle(color: AppColors.black),

      headlineMedium: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.bold,
      ),

      titleLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w600,
      ),

      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall: TextStyle(color: AppColors.textMuted),

      labelLarge: TextStyle(
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
    ),

    /* ---------- Buttons ---------- */
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),

    /* ---------- Inputs ---------- */
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightGrey,
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
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),

    /* ---------- Icons ---------- */
    iconTheme: const IconThemeData(color: AppColors.black),

    /* ---------- Divider ---------- */
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.5,
    ),

    /* ---------- Bottom Navigation ---------- */
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );

  /* --------------------------------------------------
   * DARK THEME
   * -------------------------------------------------- */
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.backgroundDark,
    primaryColor: AppColors.primaryDark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.buttonPrimary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      background: AppColors.backgroundDark,
      surface: AppColors.darkGrey,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textOnDark),
      titleTextStyle: TextStyle(
        color: AppColors.textOnDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textOnDark),
      displayMedium: TextStyle(color: AppColors.textOnDark),
      displaySmall: TextStyle(color: AppColors.textOnDark),

      headlineMedium: TextStyle(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.bold,
      ),

      titleLarge: TextStyle(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w600,
      ),

      bodyLarge: TextStyle(color: AppColors.textOnDark),
      bodyMedium: TextStyle(color: AppColors.textMuted),
      bodySmall: TextStyle(color: AppColors.textMuted),

      labelLarge: TextStyle(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w500,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary,
        foregroundColor: AppColors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textOnDark,
        side: const BorderSide(color: AppColors.textOnDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.textOnDark),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.buttonPrimary),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textMuted),
    ),

    iconTheme: const IconThemeData(color: AppColors.textOnDark),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkGrey,
      thickness: 0.5,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: AppColors.buttonPrimary,
      unselectedItemColor: AppColors.textMuted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
