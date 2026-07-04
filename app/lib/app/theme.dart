import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Awwad dark theme — matches the original prototype palette.
class AppColors {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surface2 = Color(0xFF1C2230);
  static const border = Color(0xFF2A3441);
  static const accent = Color(0xFF4F8EF7); // blue
  static const accent2 = Color(0xFF2DD4BF); // teal
  static const accent3 = Color(0xFFF59E0B); // amber
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const text = Color(0xFFE2E8F0);
  static const muted = Color(0xFF7A8899);
  static const heading = Color(0xFFF0F6FF);
}

ThemeData buildAwwadTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      tertiary: AppColors.accent3,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.text,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.heading,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.heading,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
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
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
    // Glass (iOS "Liquid Glass") primary buttons: translucent tinted fill with
    // a luminous border and bright bold text, instead of a flat solid fill.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent.withValues(alpha: 0.26),
        foregroundColor: AppColors.heading,
        disabledBackgroundColor: AppColors.surface2.withValues(alpha: 0.6),
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shadowColor: Colors.transparent,
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
            AppColors.accent.withValues(alpha: 0.14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        side: BorderSide(color: AppColors.text.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.accent,
    ),
  );
}
