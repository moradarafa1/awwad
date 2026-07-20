import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/app/theme.dart';

// Locks down the type scale introduced on 2026-07-20 when the app moved off
// google_fonts (runtime download, broke offline-first) onto the BUNDLED
// IBM Plex Sans Arabic - the same family wabl.sa uses for its titles and
// sublines. The rules here are the ones that are easy to undo by accident:
// a stray letterSpacing, an 11pt label, or a style that quietly falls back to
// the platform font because someone dropped the family.
void main() {
  final themes = {
    'dark': buildAwwadTheme(dark: true),
    'light': buildAwwadTheme(dark: false),
  };

  themes.forEach((name, theme) {
    group('type scale ($name)', () {
      final t = theme.textTheme;
      final all = <String, TextStyle?>{
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineLarge': t.headlineLarge,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };

      test('every style uses the bundled family', () {
        expect(theme.textTheme.bodyMedium?.fontFamily, kFontFamily);
        all.forEach((key, style) {
          expect(style, isNotNull, reason: '$key is missing');
          expect(style!.fontFamily, kFontFamily, reason: '$key lost the family');
        });
      });

      // Arabic is cursive. Positive tracking pushes joined letterforms apart
      // and reads as broken text, so the scale pins it to zero everywhere.
      test('no style carries letter spacing', () {
        all.forEach((key, style) {
          expect(style!.letterSpacing, 0, reason: '$key has tracking');
        });
      });

      // The brief: «لا حجم صغير جداً». Material's own labelSmall is 11.
      test('nothing renders below 12', () {
        all.forEach((key, style) {
          expect(style!.fontSize, greaterThanOrEqualTo(12),
              reason: '$key is too small to read');
        });
      });

      // Arabic ascenders, descenders and tashkeel need more leading than the
      // Latin defaults give.
      test('leading is generous enough for Arabic', () {
        for (final key in ['bodyLarge', 'bodyMedium', 'bodySmall']) {
          expect(all[key]!.height, greaterThanOrEqualTo(1.45),
              reason: '$key is too tight');
        }
        for (final key in ['displayLarge', 'headlineMedium', 'titleMedium']) {
          expect(all[key]!.height, greaterThanOrEqualTo(1.28),
              reason: '$key is too tight');
        }
      });

      // Weight, not family, is what separates the roles - the wabl.sa model.
      test('roles are separated by weight', () {
        for (final key in [
          'displayLarge',
          'displayMedium',
          'displaySmall',
          'headlineLarge',
          'headlineMedium',
          'headlineSmall',
        ]) {
          expect(all[key]!.fontWeight, FontWeight.w700, reason: '$key');
        }
        for (final key in ['titleLarge', 'titleMedium', 'titleSmall']) {
          expect(all[key]!.fontWeight, FontWeight.w600, reason: '$key');
        }
        for (final key in ['bodyLarge', 'bodyMedium', 'bodySmall']) {
          expect(all[key]!.fontWeight, FontWeight.w400, reason: '$key');
        }
        for (final key in ['labelLarge', 'labelMedium', 'labelSmall']) {
          expect(all[key]!.fontWeight, FontWeight.w500, reason: '$key');
        }
      });

      // A phone headline at Material's stock 57 clips on a 320dp screen in
      // Arabic. Keep the top of the scale phone-sized.
      test('display sizes stay phone sized', () {
        expect(all['displayLarge']!.fontSize, lessThanOrEqualTo(40));
        expect(all['headlineLarge']!.fontSize, lessThanOrEqualTo(28));
      });

      test('the scale descends monotonically', () {
        final order = [
          'displayLarge',
          'displayMedium',
          'displaySmall',
          'headlineLarge',
          'headlineMedium',
          'headlineSmall',
        ];
        for (var i = 1; i < order.length; i++) {
          expect(all[order[i]]!.fontSize,
              lessThan(all[order[i - 1]]!.fontSize!),
              reason: '${order[i]} is not smaller than ${order[i - 1]}');
        }
      });
    });
  });

  test('the family is declared, not downloaded', () {
    // google_fonts fetched the face over HTTP on first launch: with no
    // connection the app fell back to the platform font. The family must be a
    // plain bundled asset name, never a package-qualified runtime font.
    expect(kFontFamily, 'IBM Plex Sans Arabic');
    expect(kFontFamily.contains('packages/'), isFalse);
  });
}
