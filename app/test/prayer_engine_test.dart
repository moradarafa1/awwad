import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/prayer/prayer_engine.dart';

// Offline prayer engine: config roundtrip, astronomical sanity for Cairo,
// manual offsets, and the alarm-window builder (ids, pre-alerts, adhkar).

void main() {
  const cairo = PrayerConfig(
    lat: 30.04,
    lng: 31.24,
    cityAr: 'القاهرة',
    cityEn: 'Cairo',
    countryAr: 'مصر',
    countryEn: 'Egypt',
  );

  test('config json roundtrip keeps every field', () {
    final cfg = cairo.copyWith(preAlert: true, offsets: {'fajr': -3});
    final back = PrayerConfig.fromJson(cfg.toJson());
    expect(back.lat, cfg.lat);
    expect(back.cityAr, 'القاهرة');
    expect(back.preAlert, true);
    expect(back.offsets['fajr'], -3);
  });

  test('cairo times are astronomically sane and ordered', () {
    final t = timesFor(cairo, DateTime(2026, 7, 17));
    expect(t.length, 5);
    // Summer Cairo: fajr in the small hours, isha in the evening.
    expect(t['fajr']!.hour, inInclusiveRange(3, 5));
    expect(t['dhuhr']!.hour, inInclusiveRange(11, 13));
    expect(t['isha']!.hour, inInclusiveRange(19, 22));
    expect(t['fajr']!.isBefore(t['dhuhr']!), true);
    expect(t['dhuhr']!.isBefore(t['asr']!), true);
    expect(t['asr']!.isBefore(t['maghrib']!), true);
    expect(t['maghrib']!.isBefore(t['isha']!), true);
  });

  test('manual offsets shift a single prayer only', () {
    final base = timesFor(cairo, DateTime(2026, 7, 17));
    final t =
        timesFor(cairo.copyWith(offsets: {'asr': 7}), DateTime(2026, 7, 17));
    expect(t['asr']!.difference(base['asr']!).inMinutes, 7);
    expect(t['fajr'], base['fajr']);
  });

  test('alarm builder: futures only, pre-alerts and adhkar windows', () {
    // "Now" = just after midnight so all 5 prayers of day 0 are ahead.
    final now = DateTime(2026, 7, 17, 0, 30);
    final plain = buildAlarms(cairo,
        wantPrayers: true, wantAdhkar: false, now: now, days: 2);
    expect(plain.length, 10); // 5 prayers x 2 days, no pre-alerts
    expect(plain.every((a) => a.when.isAfter(now)), true);
    expect(plain.every((a) => !a.pre), true);

    final withPre = buildAlarms(cairo.copyWith(preAlert: true),
        wantPrayers: true, wantAdhkar: true, now: now, days: 2);
    // 10 mains + 10 pre-alerts + 4 adhkar (am+pm x 2 days).
    expect(withPre.length, 24);
    expect(withPre.where((a) => a.pre).length, 10);
    final adhkar =
        withPre.where((a) => a.prayer.startsWith('adhkar')).toList();
    expect(adhkar.length, 4);
    // Ids stay inside their reserved windows.
    for (final a in withPre) {
      if (a.prayer.startsWith('adhkar')) {
        expect(a.id, inInclusiveRange(kAdhkarIdBase, kAdhkarIdBase + 19));
      } else if (a.pre) {
        expect(a.id, inInclusiveRange(kPreIdBase, kPreIdBase + 59));
      } else {
        expect(a.id, inInclusiveRange(kPrayerIdBase, kPrayerIdBase + 59));
      }
    }
  });

  test('unconfigured or habit-less builds nothing', () {
    expect(buildAlarms(const PrayerConfig(), wantPrayers: true, wantAdhkar: true),
        isEmpty);
    expect(buildAlarms(cairo, wantPrayers: false, wantAdhkar: false), isEmpty);
  });
}
