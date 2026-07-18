// Applies the prayer-time notification window (next 2 days) from the saved
// PrayerConfig. Called on every app open (times shift daily) and whenever the
// user edits the prayer settings. All no-ops on web via the notifications
// facade. Trilingual MSA copy lives here; prayer NAMES come from one map.

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../data/local_store.dart';
import '../models.dart';
import '../notifications/notifications.dart';
import 'prayer_engine.dart';

const _kPrayerNames = {
  'fajr': {'ar': 'الفجر', 'en': 'Fajr', 'fr': 'Fajr'},
  'dhuhr': {'ar': 'الظهر', 'en': 'Dhuhr', 'fr': 'Dhouhr'},
  'asr': {'ar': 'العصر', 'en': 'Asr', 'fr': 'Asr'},
  'maghrib': {'ar': 'المغرب', 'en': 'Maghrib', 'fr': 'Maghreb'},
  'isha': {'ar': 'العشاء', 'en': 'Isha', 'fr': 'Icha'},
};

String prayerName(String key, String loc) =>
    _kPrayerNames[key]?[loc] ?? _kPrayerNames[key]?['ar'] ?? key;

const _kMain = {
  'ar': 'حان وقت صلاة {p}',
  'en': 'It is time for {p} prayer',
  'fr': "C'est l'heure de la prière de {p}",
};
const _kMainBody = {
  'ar': 'قُم إليها وقلبك مطمئن. «إن الصلاة كانت على المؤمنين كتاباً موقوتاً».',
  'en': 'Rise to it with a calm heart.',
  'fr': 'Levez-vous pour la prière, le coeur apaisé.',
};
const _kPre = {
  'ar': 'بعد ٥ دقائق: صلاة {p}',
  'en': 'In 5 minutes: {p} prayer',
  'fr': 'Dans 5 minutes : prière de {p}',
};
const _kPreBody = {
  'ar': 'تهيّأ وتوضأ، خير العمل الصلاة في وقتها.',
  'en': 'Get ready and make wudu.',
  'fr': 'Preparez-vous et faites vos ablutions.',
};
const _kAdhkarAm = {
  'ar': 'أذكار الصباح',
  'en': 'Morning adhkar',
  'fr': 'Adhkar du matin',
};
const _kAdhkarPm = {
  'ar': 'أذكار المساء',
  'en': 'Evening adhkar',
  'fr': 'Adhkar du soir',
};
const _kAdhkarBody = {
  'ar': 'حصّن يومك بذكر الله. دقائق قليلة تكفي.',
  'en': 'Guard your day with remembrance. A few minutes suffice.',
  'fr': 'Protégez votre journée par le dhikr. Quelques minutes suffisent.',
};
const _kKahfTitle = {
  'ar': 'سورة الكهف',
  'en': 'Surah Al-Kahf',
  'fr': 'Sourate Al-Kahf',
};
const _kKahfBody = {
  'ar': 'اليوم الجمعة: اقرأ سورة الكهف يُضِئ لك من النور ما بين الجمعتين.',
  'en': 'It is Friday: read Surah Al-Kahf for light between the two Fridays.',
  'fr': "C'est vendredi : lisez la sourate Al-Kahf pour une lumière entre les deux vendredis.",
};

/// Fixed notification id for the weekly Kahf reminder (outside the 4000-4299
/// prayer window so the daily reschedule never cancels it).
const _kKahfId = 4300;

String _t(Map<String, String> m, String loc) => m[loc] ?? m['ar']!;

/// Rebuilds the whole 4000-4299 window from the saved config + the user's
/// habits. Safe to call often; it always cancels the window first.
Future<void> applyPrayerSchedule({
  required LocalStore store,
  required List<Habit> habits,
  required bool notificationsEnabled,
  required bool showReligious,
  required String locale,
}) async {
  await cancelIdRange(4000, 4299);
  await cancelIdRange(_kKahfId, _kKahfId);
  if (!notificationsEnabled || !showReligious) return;

  final keys = habits.map((h) => h.catalogKey).whereType<String>().toSet();
  final raw = store.loadPrayer();
  final cfg = raw != null ? PrayerConfig.fromJson(raw) : const PrayerConfig();

  // Surah Al-Kahf is INDEPENDENT of the prayer location: weekly on Friday, at
  // the computed dhuhr+1h when a location exists, else a sensible 13:30.
  if (keys.contains('surah_kahf')) {
    var h = 13, m = 30;
    if (cfg.configured) {
      final dhuhr = timesFor(cfg, DateTime.now())['dhuhr'];
      if (dhuhr != null) {
        h = (dhuhr.hour + 1).clamp(0, 23);
        m = dhuhr.minute;
      }
    }
    await scheduleWeekly(_kKahfId, DateTime.friday, h, m,
        _t(_kKahfTitle, locale), _t(_kKahfBody, locale));
  }

  // Everything below needs a real location (astronomical times).
  if (!cfg.configured) return;
  final wantPrayers =
      keys.contains('pray_on_time') || keys.contains('wake_fajr');
  final wantAdhkar = keys.contains('adhkar');
  if (!wantPrayers && !wantAdhkar) return;

  // 6 days on Android so prayers keep firing when the app stays closed for a
  // long weekend (id scheme d*10+i fits: 60 slots per 100-id base). iOS keeps
  // 2 days: it caps pending requests at 64 and 6 days of prayers alone would
  // eat 72 slots.
  final windowDays =
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? 2 : 6;
  for (final a in buildAlarms(cfg,
      wantPrayers: wantPrayers, wantAdhkar: wantAdhkar, days: windowDays)) {
    switch (a.prayer) {
      case 'adhkar_am':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarAm, locale), _t(_kAdhkarBody, locale));
      case 'adhkar_pm':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarPm, locale), _t(_kAdhkarBody, locale));
      default:
        final p = prayerName(a.prayer, locale);
        final title =
            _t(a.pre ? _kPre : _kMain, locale).replaceFirst('{p}', p);
        final body = _t(a.pre ? _kPreBody : _kMainBody, locale);
        // The adhan SOUND plays only on the actual prayer-time notification,
        // never on the 5-minute pre-alert.
        if (cfg.adhanSound && !a.pre) {
          await scheduleAdhan(a.id, a.when, title, body);
        } else {
          await scheduleAt(a.id, a.when, title, body);
        }
    }
  }
}
