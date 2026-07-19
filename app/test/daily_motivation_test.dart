import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/catalog/motivation.dart';

// MANDATE_PLAN CU6: one deterministic encouragement line per day, offline,
// with the faith pool gated on the religious-content setting.

void main() {
  test('the same day always yields the same line', () {
    final a = dailyLineFor('2026-07-19', showReligious: true);
    final b = dailyLineFor('2026-07-19', showReligious: true);
    expect(identical(a, b), isTrue);
  });

  test('the line changes across consecutive days', () {
    final days = [
      '2026-07-19', '2026-07-20', '2026-07-21', '2026-07-22',
      '2026-07-23', '2026-07-24', '2026-07-25',
    ];
    final texts =
        days.map((d) => dailyLineFor(d, showReligious: true).t('ar')).toSet();
    // Not a guarantee of all-distinct (hash buckets), but a week must not
    // collapse to a single repeated line.
    expect(texts.length, greaterThanOrEqualTo(5));
  });

  test('religious lines never appear when the setting is off', () {
    final faith = kDailyFaith.map((l) => l.t('ar')).toSet();
    for (var i = 1; i <= 366; i++) {
      final key = '2026-01-${i.toString().padLeft(2, '0')}';
      final line = dailyLineFor(key, showReligious: false).t('ar');
      expect(faith.contains(line), isFalse);
    }
  });

  test('every line is trilingual, non-empty, and em-dash free', () {
    for (final l in [...kDailyGeneral, ...kDailyFaith]) {
      for (final loc in ['ar', 'en', 'fr']) {
        final t = l.t(loc);
        expect(t, isNotEmpty);
        expect(t.contains('—'), isFalse);
      }
      // Trilingual means three DISTINCT strings, not an Arabic fallback.
      expect(l.text.keys.toSet(), {'ar', 'en', 'fr'});
    }
  });

  test('pools are large enough to feel fresh', () {
    expect(kDailyGeneral.length, greaterThanOrEqualTo(14));
    expect(kDailyFaith.length, greaterThanOrEqualTo(10));
  });
}
