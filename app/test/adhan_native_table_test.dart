// The native Android adhan chain consumes a JSON table Dart writes
// (buildAdhanTableJson in prayer_scheduler.dart). These tests lock the
// contract the Kotlin side (AdhanScheduler/AdhanAlarmReceiver) parses:
// epoch-milliseconds moments, per-entry localized copy (normal + late +
// snoozed variants), the stop/snooze labels, and the 30-day horizon that
// lets the adhan keep firing for a month without an app open.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/prayer/prayer_engine.dart';
import 'package:awwad/core/prayer/prayer_scheduler.dart';

void main() {
  // Cairo (the owner's own city): Egyptian General Authority method.
  const cairo = PrayerConfig(
    lat: 30.0444,
    lng: 31.2357,
    cityAr: 'القاهرة',
    cityEn: 'Cairo',
    countryAr: 'مصر',
    countryEn: 'Egypt',
    adhanSound: true,
  );

  final now = DateTime(2026, 7, 31, 12, 0);

  Map<String, dynamic> build({String locale = 'ar', int days = 30}) =>
      jsonDecode(buildAdhanTableJson(cairo,
          locale: locale, snoozeMinutes: 10, now: now, days: days))
          as Map<String, dynamic>;

  test('covers ~30 days of five daily prayers, all in the future', () {
    final t = build();
    final entries = (t['entries'] as List).cast<Map<String, dynamic>>();
    // Midday start: today contributes the 3-4 remaining prayers, the other
    // 29 days contribute 5 each.
    expect(entries.length, greaterThan(140));
    expect(entries.length, lessThanOrEqualTo(150));
    for (final e in entries) {
      expect((e['at'] as num).toInt(),
          greaterThan(now.millisecondsSinceEpoch));
    }
    // Horizon really is ~30 days, not 10 (the FLN window limit does not
    // apply to the native chain).
    final last = entries
        .map((e) => (e['at'] as num).toInt())
        .reduce((a, b) => a > b ? a : b);
    final horizon = DateTime.fromMillisecondsSinceEpoch(last);
    expect(horizon.difference(now).inDays, greaterThanOrEqualTo(28));
  });

  test('each entry carries the full localized copy contract', () {
    final t = build();
    final entries = (t['entries'] as List).cast<Map<String, dynamic>>();
    final fajr = entries.firstWhere((e) => e['key'] == 'fajr');
    expect(fajr['title'], 'حان وقت صلاة الفجر');
    // A Doze-deferred fire must NOT re-claim "it is prayer time now".
    expect(fajr['lateTitle'], 'تذكير: صلاة الفجر');
    expect(fajr['lateBody'], isNotEmpty);
    expect(fajr['snTitle'], isNotEmpty);
    expect(fajr['snBody'], isNotEmpty);
    for (final e in entries) {
      expect(kPrayerKeys, contains(e['key']));
      for (final f in ['title', 'body', 'lateTitle', 'lateBody']) {
        expect(e[f], isA<String>());
        expect((e[f] as String), isNotEmpty);
        expect((e[f] as String).contains('—'), isFalse,
            reason: 'em-dash is banned in user-facing copy');
      }
    }
  });

  test('table-level labels: stop, snooze, snooze minutes', () {
    final t = build();
    expect(t['stop'], 'إيقاف الأذان');
    expect(t['snooze'], 'أمهلني 10 د');
    expect(t['snoozeMinutes'], 10);
    final en = build(locale: 'en');
    expect(en['stop'], 'Stop the adhan');
    expect(en['snooze'], 'Snooze 10 min');
  });

  test('an unconfigured location yields an empty table, never a throw', () {
    final t = jsonDecode(buildAdhanTableJson(const PrayerConfig(),
        locale: 'ar', snoozeMinutes: 10, now: now)) as Map<String, dynamic>;
    expect(t['entries'], isEmpty);
  });

  test('manual per-prayer offsets shift the table moments', () {
    final shifted = cairo.copyWith(offsets: {'fajr': 7});
    final base = jsonDecode(buildAdhanTableJson(cairo,
        locale: 'ar', snoozeMinutes: 10, now: now)) as Map<String, dynamic>;
    final off = jsonDecode(buildAdhanTableJson(shifted,
        locale: 'ar', snoozeMinutes: 10, now: now)) as Map<String, dynamic>;
    int firstFajr(Map<String, dynamic> t) =>
        ((t['entries'] as List).cast<Map<String, dynamic>>())
            .firstWhere((e) => e['key'] == 'fajr')['at'] as int;
    expect(firstFajr(off) - firstFajr(base), 7 * 60 * 1000);
  });
}
