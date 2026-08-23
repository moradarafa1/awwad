// Prayer home-screen widget: the pure Dart half (the payload the native
// PrayerWidgetProvider parses). The native half - Chronometer countdown, Umm
// al-Qura conversion, refresh alarms - cannot be unit-tested from Dart and is
// verified on a device instead.
//
// What matters here is the CONTRACT: the native side splits on ',', '|' and
// '=', so any prayer name or city that ever contained one of those would
// silently corrupt the card. These tests lock that down.

import 'package:awwad/core/prayer/prayer_engine.dart';
import 'package:awwad/core/widget/prayer_widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

const _cairo = PrayerConfig(
  lat: 30.0444,
  lng: 31.2357,
  cityAr: 'القاهرة',
  cityEn: 'Cairo',
  countryAr: 'مصر',
  countryEn: 'Egypt',
);

void main() {
  group('encodePrayerWidgetTimes', () {
    test('is empty without a location (the widget then shows its guidance)',
        () {
      expect(encodePrayerWidgetTimes(const PrayerConfig()), '');
    });

    test('carries every prayer of every day, ascending, well-formed', () {
      final raw = encodePrayerWidgetTimes(_cairo,
          now: DateTime(2026, 8, 22, 13, 5), days: 30);
      final parts = raw.split(',');
      expect(parts.length, 5 * 30);
      var previous = 0;
      for (final p in parts) {
        final f = p.split('|');
        // epoch|key ONLY: no clock string is pushed, because it would be text
        // formatted in the timezone active at push time and a traveller would
        // read wrong times off the card for up to a month. The native side
        // formats the absolute epoch at render time.
        expect(f.length, 2, reason: 'entry must be epoch|key: $p');
        final at = int.parse(f[0]);
        expect(at, greaterThan(previous), reason: 'entries must ascend');
        previous = at;
        expect(kPrayerKeys, contains(f[1]));
      }
    });

    test('spans 30 DISTINCT calendar days (no DST duplicate or skip)', () {
      // Egypt re-introduced DST, and a 23/25-hour day is exactly what
      // .add(Duration(days: 1)) gets wrong over a month-long horizon.
      final raw = encodePrayerWidgetTimes(_cairo,
          now: DateTime(2026, 4, 20, 9), days: 30);
      final days = raw.split(',').map((p) {
        final t =
            DateTime.fromMillisecondsSinceEpoch(int.parse(p.split('|')[0]));
        return '${t.year}-${t.month}-${t.day}';
      }).toSet();
      expect(days.length, 30);
    });

    test('holds no character the native parser splits on', () {
      final raw = encodePrayerWidgetTimes(_cairo, days: 2);
      expect(raw.contains('='), isFalse);
      for (final p in raw.split(',')) {
        expect('|'.allMatches(p).length, 1);
      }
    });
  });

  group('pushed labels', () {
    test('the next-prayer label carries its own punctuation', () {
      // The native side must never invent punctuation for a language it does
      // not know: French puts a space before a colon, Arabic and English do
      // not. So the separator ships INSIDE the pushed label.
      expect(prayerWidgetNextLabel('ar'), 'الصلاة القادمة:');
      expect(prayerWidgetNextLabel('en'), 'Next prayer:');
      expect(prayerWidgetNextLabel('fr'), 'Prochaine prière :');
    });

    test('an exhausted table gets its own line, not the no-location one', () {
      // A user whose 30-day table ran out HAS a location; telling them to go
      // set one would be a lie and would send them to a correct screen.
      for (final loc in ['ar', 'en', 'fr']) {
        expect(prayerWidgetStaleLabel(loc), isNotEmpty);
        expect(prayerWidgetStaleLabel(loc), isNot(prayerWidgetEmptyLabel(loc)));
      }
    });
  });

  group('row order', () {
    test('Arabic is reversed so الفجر sits on the right of an ltr row', () {
      expect(prayerRowOrder('ar'), 'isha,maghrib,asr,dhuhr,fajr');
    });

    test('English and French stay chronological', () {
      expect(prayerRowOrder('en'), 'fajr,dhuhr,asr,maghrib,isha');
      expect(prayerRowOrder('fr'), 'fajr,dhuhr,asr,maghrib,isha');
    });

    test('every order is a permutation of the five keys', () {
      for (final loc in ['ar', 'en', 'fr']) {
        expect(prayerRowOrder(loc).split(',').toSet(), kPrayerKeys.toSet());
      }
    });
  });

  group('names and months', () {
    test('names are pushed as key=name pairs, localized', () {
      expect(encodePrayerNames('ar'), contains('fajr=الفجر'));
      expect(encodePrayerNames('en'), contains('maghrib=Maghrib'));
      expect(encodePrayerNames('fr'), contains('dhuhr=Dhouhr'));
    });

    test('no prayer name contains a delimiter', () {
      for (final loc in ['ar', 'en', 'fr']) {
        for (final key in kPrayerKeys) {
          final n = prayerName(key, loc);
          expect(n.contains(','), isFalse, reason: n);
          expect(n.contains('='), isFalse, reason: n);
          expect(n.contains('|'), isFalse, reason: n);
          expect(n.trim(), isNotEmpty);
        }
      }
    });

    test('twelve Hijri months per language, none empty, no delimiter', () {
      for (final loc in ['ar', 'en', 'fr']) {
        final months = hijriMonthNames(loc).split('|');
        expect(months.length, 12, reason: loc);
        for (final m in months) {
          expect(m.trim(), isNotEmpty);
          expect(m.contains(','), isFalse);
        }
      }
      // Ramadan must be the ninth month in every language, or the whole
      // conversion is off by an index.
      expect(hijriMonthNames('ar').split('|')[8], 'رمضان');
      expect(hijriMonthNames('en').split('|')[8], 'Ramadan');
    });

    test('an unknown locale falls back to Arabic instead of breaking', () {
      expect(hijriMonthNames('de').split('|').length, 12);
      expect(prayerRowOrder('de').split(',').toSet(), kPrayerKeys.toSet());
    });
  });

  group('city line', () {
    test('follows the app language', () {
      expect(prayerWidgetCity(_cairo, 'ar'), 'القاهرة');
      expect(prayerWidgetCity(_cairo, 'en'), 'Cairo');
      expect(prayerWidgetCity(_cairo, 'fr'), 'Cairo');
    });

    test('is empty when the city is unknown (GPS-only config)', () {
      expect(
          prayerWidgetCity(const PrayerConfig(lat: 21.4, lng: 39.8), 'ar'), '');
    });
  });
}
