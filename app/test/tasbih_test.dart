import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/widgets/tasbih_counter.dart';

// MANDATE_PLAN CU3: the tasbih counter's pure pieces. The count maps onto
// the existing 0-10 primary metric, so no schema, sync or stats change.

void main() {
  test('only count-based worship habits use the counter', () {
    for (final k in ['istighfar', 'salawat', 'adhkar', 'gratitude', 'dua']) {
      expect(habitUsesTasbih(k), isTrue, reason: k);
    }
    for (final k in ['quit_smoking', 'daily_quran', 'surah_kahf', null]) {
      expect(habitUsesTasbih(k), isFalse, reason: '$k');
    }
  });

  test('targets match the classic portions', () {
    expect(tasbihTargetFor('istighfar'), 100);
    expect(tasbihTargetFor('salawat'), 100);
    expect(tasbihTargetFor('dua'), 100);
    expect(tasbihTargetFor('adhkar'), 33);
    expect(tasbihTargetFor('gratitude'), 33);
  });

  test('count maps onto the 0-10 metric without losing the extremes', () {
    // Never 0: the metric feeds a Slider with min:1, and a 0 both breaks
    // that slider and persists an out-of-domain value.
    expect(tasbihToMetric(0, 100), 1);
    // Any real effort must register as at least 1, never round down to 0.
    expect(tasbihToMetric(1, 100), 1);
    expect(tasbihToMetric(4, 100), 1);
    expect(tasbihToMetric(50, 100), 5);
    expect(tasbihToMetric(100, 100), 10);
    // Going past the portion stays capped at the top of the scale.
    expect(tasbihToMetric(250, 100), 10);
    // The 33-count portion behaves the same way.
    expect(tasbihToMetric(33, 33), 10);
    expect(tasbihToMetric(17, 33), 5);
  });

  test('mapping is safe for a zero or negative target', () {
    expect(tasbihToMetric(5, 0), 10);
    expect(tasbihToMetric(0, 0), 1);
  });

  test('labels are trilingual, non-empty and em-dash free', () {
    for (final loc in ['ar', 'en', 'fr']) {
      for (final s in [
        tasbihTitle(loc),
        tasbihHint(loc),
        tasbihReset(loc),
        tasbihDone(loc),
      ]) {
        expect(s, isNotEmpty);
        expect(s.contains('—'), isFalse);
      }
    }
    // An unknown locale falls back to Arabic, the app default.
    expect(tasbihTitle('de'), tasbihTitle('ar'));
  });
}
