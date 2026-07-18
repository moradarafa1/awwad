import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/platform/usage_stats.dart';
import 'package:awwad/features/phone/usage_screen.dart';

// Per-app open counts (owner request 2026-07-18): the AppUsage model carries
// an opens field that defaults to 0 (old platform payloads stay valid), and
// the row label follows Arabic number agreement in MSA.

void main() {
  test('AppUsage opens defaults to 0 when absent', () {
    const legacy = AppUsage('com.x', 'X', 12);
    expect(legacy.opens, 0);
    const withOpens = AppUsage('com.x', 'X', 12, 7);
    expect(withOpens.opens, 7);
  });

  test('Arabic opens label follows number agreement', () {
    expect(usageOpensLabel('ar', 1), 'فُتح مرة واحدة اليوم');
    expect(usageOpensLabel('ar', 2), 'فُتح مرتين اليوم');
    expect(usageOpensLabel('ar', 3), 'فُتح 3 مرات اليوم');
    expect(usageOpensLabel('ar', 10), 'فُتح 10 مرات اليوم');
    expect(usageOpensLabel('ar', 11), 'فُتح 11 مرة اليوم');
    expect(usageOpensLabel('ar', 47), 'فُتح 47 مرة اليوم');
    // n % 100 buckets for three-digit heavy-usage days.
    expect(usageOpensLabel('ar', 100), 'فُتح 100 مرة اليوم');
    expect(usageOpensLabel('ar', 105), 'فُتح 105 مرات اليوم');
    expect(usageOpensLabel('ar', 120), 'فُتح 120 مرة اليوم');
  });

  test('English and French opens labels handle singular and plural', () {
    expect(usageOpensLabel('en', 1), 'Opened once today');
    expect(usageOpensLabel('en', 5), 'Opened 5 times today');
    expect(usageOpensLabel('fr', 1), "Ouvert 1 fois aujourd'hui");
    expect(usageOpensLabel('fr', 5), "Ouvert 5 fois aujourd'hui");
    // Unknown locale falls back to English.
    expect(usageOpensLabel('de', 2), 'Opened 2 times today');
  });

  test('no user-facing em-dash in the opens labels', () {
    for (final loc in ['ar', 'en', 'fr']) {
      for (final n in [1, 2, 5, 20]) {
        expect(usageOpensLabel(loc, n).contains('—'), isFalse);
      }
    }
  });
}
