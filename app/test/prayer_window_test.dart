import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/prayer/prayer_engine.dart';

// MANDATE_PLAN N1: the prayer window was raised to the maximum the id scheme
// allows. These tests lock that invariant, because a collision would make one
// notification silently REPLACE another (the same id can only hold one).

PrayerConfig _cairo() => const PrayerConfig(
      lat: 30.0444,
      lng: 31.2357,
      cityAr: 'القاهرة',
      cityEn: 'Cairo',
      countryAr: 'مصر',
      countryEn: 'Egypt',
      preAlert: true,
    );

void main() {
  test('the documented maximum is what the id bases actually allow', () {
    // Mains occupy kPrayerIdBase + d*10 + i, i in 0..4. The last id used on
    // the final day must stay below the next family's base.
    final lastMain = kPrayerIdBase + (kMaxPrayerWindowDays - 1) * 10 + 4;
    expect(lastMain, lessThan(kPreIdBase));

    final lastPre = kPreIdBase + (kMaxPrayerWindowDays - 1) * 10 + 4;
    expect(lastPre, lessThan(kAdhkarIdBase));

    // Adhkar use kAdhkarIdBase + d*2 (+1), and the whole window is cancelled
    // as the range 4000..4299, so it must not spill past that.
    final lastAdhkar = kAdhkarIdBase + (kMaxPrayerWindowDays - 1) * 2 + 1;
    expect(lastAdhkar, lessThanOrEqualTo(4299));
  });

  test('a full-window build emits no duplicate ids', () {
    final alarms = buildAlarms(
      _cairo(),
      wantPrayers: true,
      wantAdhkar: true,
      days: kMaxPrayerWindowDays,
      now: DateTime(2026, 7, 19, 0, 1), // just after midnight: nothing skipped
    );
    final ids = alarms.map((a) => a.id).toList();
    expect(ids.length, greaterThan(50), reason: 'window should be well filled');
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
  });

  test('every emitted id stays inside the cancelled range', () {
    final alarms = buildAlarms(
      _cairo(),
      wantPrayers: true,
      wantAdhkar: true,
      days: kMaxPrayerWindowDays,
      now: DateTime(2026, 7, 19, 0, 1),
    );
    for (final a in alarms) {
      expect(a.id, inInclusiveRange(4000, 4299), reason: '${a.prayer} ${a.id}');
    }
  });

  test('alarms are all in the future and ordered within the window', () {
    final now = DateTime(2026, 7, 19, 12, 0);
    final alarms = buildAlarms(_cairo(),
        wantPrayers: true, wantAdhkar: true, days: kMaxPrayerWindowDays, now: now);
    for (final a in alarms) {
      expect(a.when.isAfter(now), isTrue, reason: '${a.prayer} ${a.when}');
    }
    // The window really does reach ~10 days out, which is the whole point.
    final furthest =
        alarms.map((a) => a.when).reduce((x, y) => x.isAfter(y) ? x : y);
    expect(furthest.difference(now).inDays, greaterThanOrEqualTo(8));
  });
}
