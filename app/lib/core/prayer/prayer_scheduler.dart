// Applies the prayer-time notification window (next 2 days) from the saved
// PrayerConfig. Called on every app open (times shift daily) and whenever the
// user edits the prayer settings. All no-ops on web via the notifications
// facade. Trilingual MSA copy lives here; prayer NAMES come from one map.

import 'dart:convert' show jsonEncode;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../data/local_store.dart';
import '../models.dart';
import '../notifications/notifications.dart';
import 'adhan_native.dart';
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

// --- Native Android adhan table -------------------------------------------
// Copy for the native chain. The LATE variants are what the native receiver
// shows when a Doze-deferred fire arrives 5-30 minutes after the prayer:
// re-stating «حان وقت صلاة X» half an hour later would be false, and >30
// minutes late nothing is shown at all. Matches the snoozed-prayer copy in
// notification_actions.dart (duplicated on purpose: importing that file here
// would drag flutter_local_notifications into the web build).
const _kLateTitle = {
  'ar': 'تذكير: صلاة {p}',
  'en': 'Reminder: {p} prayer',
  'fr': 'Rappel : prière de {p}',
};
const _kLateBody = {
  'ar': 'ما زال الوقت قائماً. قُم إليها وقلبك مطمئن.',
  'en': 'The window is still open. Rise to it with a calm heart.',
  'fr': "Le temps n'est pas écoulé. Levez-vous, le coeur apaisé.",
};
const _kStopAdhan = {
  'ar': 'إيقاف الأذان',
  'en': 'Stop the adhan',
  'fr': "Arrêter l'adhan",
};
// The NATIVE notification channel's user-visible name/description (shown in
// Android Settings > Notifications). Passed through the table because channel
// names are user-facing text and nothing native may hardcode a language.
const _kChName = {
  'ar': 'الأذان',
  'en': 'Adhan (prayer call)',
  'fr': "Adhan (appel à la prière)",
};
const _kChDesc = {
  'ar': 'إشعار الأذان عند دخول وقت كل صلاة.',
  'en': 'The call to prayer at each prayer time.',
  'fr': "L'appel à la prière à chaque heure de prière.",
};
Map<String, String> _kSnoozeLabel(int minutes) => {
      'ar': 'أمهلني $minutes د',
      'en': 'Snooze $minutes min',
      'fr': 'Reporter $minutes min',
    };

/// Days of adhan moments the native table carries. Far beyond the 10-day FLN
/// window: the native chain re-arms itself after every fire, so the adhan
/// keeps sounding for a month even if the app is never opened.
const int kAdhanNativeTableDays = 30;

/// Builds the JSON table the native Android adhan chain consumes
/// (AdhanScheduler.kt). PURE (no plugins, [now] injectable) so it is
/// unit-testable; entries carry epoch-milliseconds moments plus the fully
/// localized copy, because nothing on the native side may hardcode strings.
String buildAdhanTableJson(
  PrayerConfig cfg, {
  required String locale,
  required int snoozeMinutes,
  DateTime? now,
  int days = kAdhanNativeTableDays,
}) {
  final ref = now ?? DateTime.now();
  final entries = <Map<String, Object>>[];
  for (var d = 0; d < days; d++) {
    // Date-component arithmetic, NOT .add(Duration(days: d)): a Duration is
    // 24 wall-clock hours, so a 23/25-hour DST day would duplicate or skip a
    // calendar day over a 30-day horizon (Egypt observes DST again).
    final day = DateTime(ref.year, ref.month, ref.day + d);
    final times = timesFor(cfg, day);
    for (final key in kPrayerKeys) {
      final t = times[key];
      if (t == null || !t.isAfter(ref)) continue;
      final p = prayerName(key, locale);
      entries.add({
        'at': t.millisecondsSinceEpoch,
        'key': key,
        'title': _t(_kMain, locale).replaceFirst('{p}', p),
        'body': _t(_kMainBody, locale),
        'lateTitle': _t(_kLateTitle, locale).replaceFirst('{p}', p),
        'lateBody': _t(_kLateBody, locale),
        'snTitle': _t(_kLateTitle, locale).replaceFirst('{p}', p),
        'snBody': _t(_kLateBody, locale),
      });
    }
  }
  return jsonEncode({
    'v': 1,
    'stop': _t(_kStopAdhan, locale),
    'snooze': _t(_kSnoozeLabel(snoozeMinutes), locale),
    'snoozeMinutes': snoozeMinutes,
    'chName': _t(_kChName, locale),
    'chDesc': _t(_kChDesc, locale),
    'entries': entries,
  });
}

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
  if (!notificationsEnabled || !showReligious) {
    await clearNativeAdhan();
    return;
  }

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
  if (!cfg.configured) {
    await clearNativeAdhan();
    return;
  }
  final wantPrayers =
      keys.contains('pray_on_time') || keys.contains('wake_fajr');
  final wantAdhkar = keys.contains('adhkar');
  // THE ADHAN IS A CORE FEATURE (owner order 2026-07-31, confirmed by the
  // adversarial review): it follows the Settings toggle + a location alone,
  // NEVER the habit list. A user with no prayer habit who enabled the adhan
  // still gets the five adhan-time alerts; without this, the Settings switch
  // would promise a sound that never fires.
  final adhanWanted = cfg.adhanSound;
  if (!wantPrayers && !wantAdhkar && !adhanWanted) {
    await clearNativeAdhan();
    return;
  }

  // ANDROID + adhan sound on: the five prayer mains are handled end-to-end by
  // the NATIVE chain (exact AlarmManager alarm -> AdhanService plays the
  // owner's adhan and any hardware button stops it -> its own notification).
  // Scheduling FLN mains too would double-notify every prayer. Pre-alerts,
  // adhkar and Kahf stay on FLN; iOS keeps the FLN adhan path untouched.
  //
  // The table is synced FIRST: if the native sync fails (prefs write or the
  // platform channel), nativeAdhan stays false and the loop below falls back
  // to FLN adhan mains, so a sync failure can never mean a silent prayer.
  var nativeAdhan = false;
  if (isNativeAdhanPlatform && adhanWanted) {
    final snooze = store.loadSettings().snoozeMinutes;
    nativeAdhan = await syncNativeAdhan(buildAdhanTableJson(cfg,
        locale: locale, snoozeMinutes: snooze));
  }
  if (!nativeAdhan) {
    await clearNativeAdhan();
  }

  // 10 days on Android: the MAXIMUM the id scheme allows without collision
  // (mains use kPrayerIdBase + d*10 + i with i <= 4, and the next base is
  // 100 ids away, so d <= 9). Rebuilt on every app open, so this only has to
  // cover a stretch of the app never being opened. iOS keeps 2 days: it caps
  // pending requests at 64 and 10 days of prayers alone would eat 120 slots.
  //
  // Going beyond 10 would need a background re-arm for the SILENT mains too;
  // the ADHAN mains get exactly that via the native 30-day chain. The FLN
  // window deliberately stays Dart-computed: a native re-implementation of
  // the astronomical engine could compute WRONG prayer times, and a wrong
  // adhan is worse than a lapsed reminder. See kMaxPrayerWindowDays.
  final windowDays =
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? 2 : kMaxPrayerWindowDays;
  // Mains (and the adhan) follow adhanWanted OR a prayer habit; pre-alerts
  // stay habit-gated (they exist for the pray-on-time routine, and an
  // adhan-only user asked for the adhan, not a 5-minute drumroll).
  for (final a in buildAlarms(cfg,
      wantPrayers: wantPrayers || adhanWanted,
      wantAdhkar: wantAdhkar,
      days: windowDays)) {
    switch (a.prayer) {
      case 'adhkar_am':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarAm, locale), _t(_kAdhkarBody, locale),
            channel: PrayerChannel.adhkar);
      case 'adhkar_pm':
        await scheduleAt(
            a.id, a.when, _t(_kAdhkarPm, locale), _t(_kAdhkarBody, locale),
            channel: PrayerChannel.adhkar);
      default:
        if (a.pre && !wantPrayers) continue; // pre-alerts are habit-gated
        final p = prayerName(a.prayer, locale);
        final title =
            _t(a.pre ? _kPre : _kMain, locale).replaceFirst('{p}', p);
        final body = _t(a.pre ? _kPreBody : _kMainBody, locale);
        // The adhan SOUND plays only on the actual prayer-time notification,
        // never on the 5-minute pre-alert.
        if (adhanWanted && !a.pre) {
          if (nativeAdhan) {
            // Handled by the native chain (table synced above): no FLN
            // notification for the mains, or every prayer shows twice.
            continue;
          }
          await scheduleAdhan(a.id, a.when, title, body, prayerKey: a.prayer);
        } else {
          if (!a.pre && !wantPrayers) continue; // silent mains are habit-gated
          await scheduleAt(a.id, a.when, title, body,
              channel: a.pre ? PrayerChannel.preAlert : PrayerChannel.main,
              prayerKey: a.prayer);
        }
    }
  }
}
