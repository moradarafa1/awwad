// Applies the prayer-time notification window (next 2 days) from the saved
// PrayerConfig. Called on every app open (times shift daily) and whenever the
// user edits the prayer settings. All no-ops on web via the notifications
// facade. Trilingual MSA copy lives here; prayer NAMES come from one map.

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
  'fr': 'Protegez votre journee par le dhikr. Quelques minutes suffisent.',
};

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
  if (!notificationsEnabled || !showReligious) return;
  final raw = store.loadPrayer();
  if (raw == null) return;
  final cfg = PrayerConfig.fromJson(raw);
  if (!cfg.configured) return;

  final keys = habits.map((h) => h.catalogKey).whereType<String>().toSet();
  final wantPrayers =
      keys.contains('pray_on_time') || keys.contains('wake_fajr');
  final wantAdhkar = keys.contains('adhkar');
  if (!wantPrayers && !wantAdhkar) return;

  for (final a
      in buildAlarms(cfg, wantPrayers: wantPrayers, wantAdhkar: wantAdhkar)) {
    switch (a.prayer) {
      case 'adhkar_am':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarAm, locale), _t(_kAdhkarBody, locale));
      case 'adhkar_pm':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarPm, locale), _t(_kAdhkarBody, locale));
      default:
        final p = prayerName(a.prayer, locale);
        await scheduleAt(
          a.id,
          a.when,
          _t(a.pre ? _kPre : _kMain, locale).replaceFirst('{p}', p),
          _t(a.pre ? _kPreBody : _kMainBody, locale),
        );
    }
  }
}
