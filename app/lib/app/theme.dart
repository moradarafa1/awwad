import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One palette = every semantic color the app uses.
class Palette {
  final Color bg, surface, surface2, border, accent, accent2, accent3;
  final Color danger, success, text, muted, heading, hairline;
  const Palette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.accent,
    required this.accent2,
    required this.accent3,
    required this.danger,
    required this.success,
    required this.text,
    required this.muted,
    required this.heading,
    required this.hairline,
  });
}

/// The original Awwad dark palette (default).
const Palette kDarkPalette = Palette(
  bg: Color(0xFF0D1117),
  surface: Color(0xFF161B22),
  surface2: Color(0xFF1C2230),
  border: Color(0xFF2A3441),
  accent: Color(0xFF4F8EF7), // blue
  accent2: Color(0xFF2DD4BF), // teal
  accent3: Color(0xFFF59E0B), // amber
  danger: Color(0xFFEF4444),
  success: Color(0xFF22C55E),
  text: Color(0xFFE2E8F0),
  muted: Color(0xFF7A8899),
  heading: Color(0xFFF0F6FF),
  hairline: Color(0x14FFFFFF), // white 8%
);

/// Light palette. Accents are DARKENED versions of the brand hues so text and
/// icons stay readable on white (WCAG AA against #FFFFFF / #F5F7FA).
const Palette kLightPalette = Palette(
  bg: Color(0xFFF5F7FA),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFEDF1F6),
  border: Color(0xFFD7DFE9),
  accent: Color(0xFF2563EB), // blue-600, 5.2:1 on white
  accent2: Color(0xFF0F766E), // teal-700, 5.3:1 on white
  accent3: Color(0xFFB45309), // amber-700, 4.9:1 on white
  danger: Color(0xFFDC2626),
  success: Color(0xFF15803D),
  text: Color(0xFF334155),
  muted: Color(0xFF5B6B7C),
  heading: Color(0xFF0F172A),
  hairline: Color(0x14000000), // black 8%
);

/// Awwad theme colors. NOT const anymore: the getters resolve against the
/// active palette so the whole app flips between dark and light instantly.
/// Callers must NOT wrap these in `const` expressions.
class AppColors {
  static Palette _p = kDarkPalette;
  static bool isDark = true;

  /// Switch the active palette. Call before building the MaterialApp.
  static void apply({required bool dark}) {
    isDark = dark;
    _p = dark ? kDarkPalette : kLightPalette;
  }

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surface2 => _p.surface2;
  static Color get border => _p.border;
  static Color get accent => _p.accent;
  static Color get accent2 => _p.accent2;
  static Color get accent3 => _p.accent3;
  static Color get danger => _p.danger;
  static Color get success => _p.success;
  static Color get text => _p.text;
  static Color get muted => _p.muted;
  static Color get heading => _p.heading;

  /// Subtle inner-border color for glass surfaces (white on dark, black on light).
  static Color get hairline => _p.hairline;
}

ThemeData buildAwwadTheme({bool dark = true}) {
  AppColors.apply(dark: dark);
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(
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
    // Slightly translucent surfaces so the ambient glow reads through them -
    // part of the premium "layered glass" look.
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: dark ? 0.78 : 0.86),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.hairline),
      ),
    ),
    // iOS-style page transitions on every platform (premium, subtle).
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
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
      fillColor: dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    ),
    // Glass (iOS "Liquid Glass") primary buttons: translucent tinted fill with
    // a luminous border and bright bold text, instead of a flat solid fill.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent.withValues(alpha: dark ? 0.26 : 0.14),
        foregroundColor: dark ? AppColors.heading : AppColors.accent,
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
        backgroundColor: (dark ? Colors.white : Colors.black)
            .withValues(alpha: 0.04),
        side: BorderSide(color: AppColors.text.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.accent,
    ),
  );
}
