// Prayer-times engine (TODO 0d Phase A). Fully OFFLINE and zero-cost: the
// `adhan` package computes the five daily times astronomically from a
// latitude/longitude; the location comes from GPS when the user grants it,
// otherwise from the bundled 306-city list (assets/data/cities.json), and
// every time can additionally be nudged manually (per-prayer minute offsets).
//
// The engine is PURE (no plugins) so it is fully unit-testable; GPS and
// scheduling live in the UI/scheduler layers.

import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The five prayers, in day order. Names are catalog keys, not UI strings.
const kPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

class PrayerConfig {
  final double? lat;
  final double? lng;
  final String? cityAr;
  final String? cityEn;
  final String? countryAr;
  final String? countryEn;

  /// Notify 5 minutes before each prayer too (owner-spec toggle).
  final bool preAlert;

  /// Per-prayer manual adjustment in minutes (e.g. {'fajr': -3}).
  final Map<String, int> offsets;

  const PrayerConfig({
    this.lat,
    this.lng,
    this.cityAr,
    this.cityEn,
    this.countryAr,
    this.countryEn,
    this.preAlert = false,
    this.offsets = const {},
  });

  bool get configured => lat != null && lng != null;

  PrayerConfig copyWith({
    double? lat,
    double? lng,
    String? cityAr,
    String? cityEn,
    String? countryAr,
    String? countryEn,
    bool? preAlert,
    Map<String, int>? offsets,
  }) =>
      PrayerConfig(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        cityAr: cityAr ?? this.cityAr,
        cityEn: cityEn ?? this.cityEn,
        countryAr: countryAr ?? this.countryAr,
        countryEn: countryEn ?? this.countryEn,
        preAlert: preAlert ?? this.preAlert,
        offsets: offsets ?? this.offsets,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'city_ar': cityAr,
        'city_en': cityEn,
        'country_ar': countryAr,
        'country_en': countryEn,
        'pre_alert': preAlert,
        'offsets': offsets,
      };

  factory PrayerConfig.fromJson(Map<String, dynamic> j) => PrayerConfig(
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        cityAr: j['city_ar'] as String?,
        cityEn: j['city_en'] as String?,
        countryAr: j['country_ar'] as String?,
        countryEn: j['country_en'] as String?,
        preAlert: j['pre_alert'] == true,
        offsets: (j['offsets'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
            const {},
      );
}

/// One bundled city (fallback picker when GPS is unavailable).
class PrayerCity {
  final String countryAr, countryEn, cityAr, cityEn, tz;
  final double lat, lng;
  const PrayerCity(this.countryAr, this.countryEn, this.cityAr, this.cityEn,
      this.lat, this.lng, this.tz);
}

List<PrayerCity>? _cities;

Future<List<PrayerCity>> loadCities() async {
  if (_cities != null) return _cities!;
  final raw = await rootBundle.loadString('assets/data/cities.json');
  final list = jsonDecode(raw) as List<dynamic>;
  _cities = [
    for (final c in list.cast<Map<String, dynamic>>())
      PrayerCity(
        c['country_ar'] as String,
        c['country_en'] as String,
        c['city_ar'] as String,
        c['city_en'] as String,
        (c['lat'] as num).toDouble(),
        (c['lng'] as num).toDouble(),
        c['tz'] as String? ?? '',
      ),
  ];
  return _cities!;
}

/// Nearest bundled city to a GPS fix (to show a human-readable name).
PrayerCity nearestCity(List<PrayerCity> cities, double lat, double lng) {
  PrayerCity best = cities.first;
  double bestD = double.infinity;
  for (final c in cities) {
    final dLat = c.lat - lat, dLng = c.lng - lng;
    final d = dLat * dLat + dLng * dLng;
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return best;
}

/// Regional calculation method: Egypt and the Gulf get their official
/// authorities; everywhere else the Muslim World League parameters.
CalculationParameters _methodFor(String? countryEn) {
  switch ((countryEn ?? '').toLowerCase()) {
    case 'egypt':
      return CalculationMethod.egyptian.getParameters();
    case 'saudi arabia':
      return CalculationMethod.umm_al_qura.getParameters();
    case 'united arab emirates':
      return CalculationMethod.dubai.getParameters();
    case 'qatar':
      return CalculationMethod.qatar.getParameters();
    case 'kuwait':
      return CalculationMethod.kuwait.getParameters();
    default:
      return CalculationMethod.muslim_world_league.getParameters();
  }
}

/// The five times for [day] (device-local), with manual offsets applied.
Map<String, DateTime> timesFor(PrayerConfig cfg, DateTime day) {
  if (!cfg.configured) return {};
  final params = _methodFor(cfg.countryEn);
  final pt = PrayerTimes(
    Coordinates(cfg.lat!, cfg.lng!),
    DateComponents.from(day),
    params,
  );
  final base = {
    'fajr': pt.fajr,
    'dhuhr': pt.dhuhr,
    'asr': pt.asr,
    'maghrib': pt.maghrib,
    'isha': pt.isha,
  };
  return base.map((k, v) =>
      MapEntry(k, v.add(Duration(minutes: cfg.offsets[k] ?? 0))));
}

/// One alarm to schedule (id + when + which prayer + kind).
class PrayerAlarm {
  final int id;
  final DateTime when;
  final String prayer; // fajr..isha, or 'adhkar_am'/'adhkar_pm'
  final bool pre; // true = the 5-minutes-before alert
  const PrayerAlarm(this.id, this.when, this.prayer, {this.pre = false});
}

// Notification id windows (keep stable; cancelled as a block on reschedule):
// 4000..4059 prayer mains, 4100..4159 pre-alerts, 4200..4219 adhkar.
const kPrayerIdBase = 4000;
const kPreIdBase = 4100;
const kAdhkarIdBase = 4200;

/// Builds every alarm for the next [days] days that is still in the future.
/// [wantPrayers] = user has a prayer habit; [wantAdhkar] = adhkar habit
/// (fajr+30 morning, asr+30 evening, per the owner spec).
List<PrayerAlarm> buildAlarms(
  PrayerConfig cfg, {
  required bool wantPrayers,
  required bool wantAdhkar,
  DateTime? now,
  int days = 2,
}) {
  if (!cfg.configured || (!wantPrayers && !wantAdhkar)) return const [];
  final ref = now ?? DateTime.now();
  final out = <PrayerAlarm>[];
  for (var d = 0; d < days; d++) {
    final day = DateTime(ref.year, ref.month, ref.day).add(Duration(days: d));
    final times = timesFor(cfg, day);
    var i = 0;
    for (final key in kPrayerKeys) {
      final t = times[key]!;
      final slot = d * 10 + i;
      if (wantPrayers) {
        if (t.isAfter(ref)) {
          out.add(PrayerAlarm(kPrayerIdBase + slot, t, key));
        }
        if (cfg.preAlert) {
          final pre = t.subtract(const Duration(minutes: 5));
          if (pre.isAfter(ref)) {
            out.add(PrayerAlarm(kPreIdBase + slot, pre, key, pre: true));
          }
        }
      }
      i++;
    }
    if (wantAdhkar) {
      final am = times['fajr']!.add(const Duration(minutes: 30));
      final pm = times['asr']!.add(const Duration(minutes: 30));
      if (am.isAfter(ref)) {
        out.add(PrayerAlarm(kAdhkarIdBase + d * 2, am, 'adhkar_am'));
      }
      if (pm.isAfter(ref)) {
        out.add(PrayerAlarm(kAdhkarIdBase + d * 2 + 1, pm, 'adhkar_pm'));
      }
    }
  }
  return out;
}
