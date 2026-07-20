// Notification ACTION buttons: «تم» (done) and «أمهلني» (snooze).
//
// Phase 0.6 item 3 (owner order 2026-07-20): a reminder must be actionable
// from the shade without opening the app. «تم» logs the habit and clears the
// notification; «أمهلني» re-fires it after the user's chosen 10 or 30 minutes.
//
// THE CONSTRAINT THAT SHAPES THIS WHOLE FILE: tapping an action button does
// NOT launch the app. The callback runs in a SEPARATE BACKGROUND ISOLATE with
// no Riverpod container, no AppController, and no widget tree. So nothing here
// may touch app state; it reads and writes SharedPreferences directly through
// LocalStore, exactly like the home-screen widget's quick-log callback does
// (core/widget/widget_sync.dart), and the foreground app reconciles from disk
// on its next open. A naive `ref.read(...)` here would silently no-op.

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/local_store.dart';
import '../state/app_state.dart' show buildQuickEntry, dayKey;

/// Action ids. STABLE STRINGS: an already-scheduled notification can outlive
/// an app update and will hand back the id it was built with.
const String kActionDone = 'aw_done';
const String kActionSnooze = 'aw_snooze';

/// iOS category ids. A Darwin notification only shows buttons if its
/// categoryIdentifier matches a category registered at init time.
const String kCategoryHabit = 'aw_cat_habit';
const String kCategoryPrayer = 'aw_cat_prayer';

/// Snooze re-fires under a DERIVED id, never the original one. Habit reminders
/// are scheduled with matchDateTimeComponents.time, i.e. they REPEAT daily;
/// rescheduling their own id would overwrite the repeat and silently destroy
/// the user's daily reminder. The offset is injective so two snoozed
/// reminders can never collide, and a re-snooze reuses the derived id so
/// snoozing twice replaces rather than stacks.
const int kSnoozeIdOffset = 100000;

int snoozeIdFor(int originalId) => originalId >= kSnoozeIdOffset
    ? originalId
    : originalId + kSnoozeIdOffset;

/// Button labels. Baked in at SCHEDULE time (foreground, locale known), so the
/// background isolate never has to resolve copy for the button it just handled.
const Map<String, String> kActionDoneLabel = {
  'ar': 'تم',
  'en': 'Done',
  'fr': 'Fait',
};

Map<String, String> kActionSnoozeLabel(int minutes) => {
      'ar': 'أمهلني $minutes د',
      'en': 'Snooze $minutes min',
      'fr': 'Reporter $minutes min',
    };

/// Copy for a SNOOZED prayer reminder. Deliberately NOT the original «حان وقت
/// صلاة الفجر»: re-firing that ten minutes later would state something false.
const Map<String, String> _kSnoozedPrayerTitle = {
  'ar': 'تذكير: صلاة {p}',
  'en': 'Reminder: {p} prayer',
  'fr': 'Rappel : prière de {p}',
};
const Map<String, String> _kSnoozedPrayerBody = {
  'ar': 'ما زال الوقت قائماً. قُم إليها وقلبك مطمئن.',
  'en': 'The window is still open. Rise to it with a calm heart.',
  'fr': "Le temps n'est pas écoulé. Levez-vous, le coeur apaisé.",
};

/// Copy for a snoozed HABIT reminder. The habit's own title carries the
/// specifics, so the body only has to say why it came back.
const Map<String, String> _kSnoozedHabitBody = {
  'ar': 'عُدنا إليك كما طلبت. خطوة صغيرة الآن 🌿',
  'en': 'Back as you asked. One small step now 🌿',
  'fr': "De retour comme demandé. Un petit pas maintenant 🌿",
};

String _t(Map<String, String> m, String loc) => m[loc] ?? m['ar']!;

/// The result of handling one action tap. Returned (rather than logged only)
/// so a test can assert on it without a plugin or a device.
class NotificationActionResult {
  final bool logged; // «تم» wrote an entry
  final bool alreadyLogged; // «تم» on a habit already done today
  final int? snoozedId; // «أمهلني» re-armed under this id
  final String? snoozeTitle;
  final String? snoozeBody;
  final DateTime? snoozeAt;

  const NotificationActionResult({
    this.logged = false,
    this.alreadyLogged = false,
    this.snoozedId,
    this.snoozeTitle,
    this.snoozeBody,
    this.snoozeAt,
  });

  static const none = NotificationActionResult();
}

/// Splits a notification payload into its kind and its argument.
/// `habit:abc` -> ('habit', 'abc'); `prayer:fajr` -> ('prayer', 'fajr');
/// a legacy bare `prayer` -> ('prayer', null).
(String, String?) parsePayload(String? payload) {
  if (payload == null || payload.isEmpty) return ('', null);
  final i = payload.indexOf(':');
  if (i < 0) return (payload, null);
  return (payload.substring(0, i), payload.substring(i + 1));
}

/// Decides what an action tap should DO, and performs the disk half of it
/// (the auto-log). Pure of any plugin call so it is testable with an in-memory
/// SharedPreferences; the caller performs the actual reschedule/cancel.
///
/// [now] is injectable for tests.
Future<NotificationActionResult> resolveNotificationAction({
  required LocalStore store,
  required String? actionId,
  required String? payload,
  required int notificationId,
  DateTime? now,
}) async {
  final at = now ?? DateTime.now();
  final (kind, arg) = parsePayload(payload);
  final settings = store.loadSettings();
  final loc = settings.locale ?? 'ar';

  if (actionId == kActionDone) {
    // «تم» auto-logs only where a log is meaningful: a habit reminder. On a
    // prayer alert it is a plain "stop and dismiss" (the owner's «where that
    // fits»): one of five prayers is not the same event as the daily
    // pray-on-time habit, and logging the habit off the Fajr alert would
    // credit a day that has four prayers still ahead of it.
    if (kind != 'habit' || arg == null) return NotificationActionResult.none;
    final habit = store.loadHabits().where((h) => h.id == arg).firstOrNull;
    if (habit == null) return NotificationActionResult.none;
    final today = dayKey(at);
    final entries = store.loadEntries();
    final already = entries
        .any((e) => e.habitId == habit.id && e.date == today && !e.isSkip);
    if (already) {
      return const NotificationActionResult(alreadyLogged: true);
    }
    // Replace any same-day SKIP entry, exactly like quickLogHabit does.
    final next = [
      ...entries.where((e) => !(e.date == today && e.habitId == habit.id)),
      buildQuickEntry(habit, today),
    ]..sort((a, b) => b.date.compareTo(a.date));
    await store.saveEntries(next);
    return const NotificationActionResult(logged: true);
  }

  if (actionId == kActionSnooze) {
    final minutes = settings.snoozeMinutes;
    final when = at.add(Duration(minutes: minutes));
    final id = snoozeIdFor(notificationId);
    switch (kind) {
      case 'habit':
        final habit = store.loadHabits().where((h) => h.id == arg).firstOrNull;
        if (habit == null) return NotificationActionResult.none;
        return NotificationActionResult(
          snoozedId: id,
          snoozeTitle: habit.title,
          snoozeBody: _t(_kSnoozedHabitBody, loc),
          snoozeAt: when,
        );
      case 'prayer':
        // arg is the prayer key (fajr/dhuhr/...). A legacy payload scheduled
        // before this shipped carries no key; fall back to the bare reminder
        // rather than dropping the snooze.
        final p = arg == null ? null : _prayerNames[arg]?[loc];
        return NotificationActionResult(
          snoozedId: id,
          snoozeTitle: p == null
              ? _t(_kSnoozedPrayerTitle, loc).replaceFirst(' {p}', '')
              : _t(_kSnoozedPrayerTitle, loc).replaceFirst('{p}', p),
          snoozeBody: _t(_kSnoozedPrayerBody, loc),
          snoozeAt: when,
        );
      default:
        return NotificationActionResult.none;
    }
  }

  return NotificationActionResult.none;
}

/// Prayer display names. Duplicated from prayer_scheduler ON PURPOSE: this
/// file is reached from the background isolate, and importing the scheduler
/// would drag the whole prayer engine (and the notifications facade it
/// imports) into a callback that must stay cheap and cycle-free.
/// prayer_names_test.dart fails if the two maps ever drift.
const Map<String, Map<String, String>> _prayerNames = {
  'fajr': {'ar': 'الفجر', 'en': 'Fajr', 'fr': 'Fajr'},
  'dhuhr': {'ar': 'الظهر', 'en': 'Dhuhr', 'fr': 'Dhouhr'},
  'asr': {'ar': 'العصر', 'en': 'Asr', 'fr': 'Asr'},
  'maghrib': {'ar': 'المغرب', 'en': 'Maghrib', 'fr': 'Maghreb'},
  'isha': {'ar': 'العشاء', 'en': 'Isha', 'fr': 'Icha'},
};

/// Test-visible mirror of the private map above.
Map<String, Map<String, String>> get debugActionPrayerNames => _prayerNames;

/// THE BACKGROUND ENTRY POINT. Fired by flutter_local_notifications when an
/// action button is tapped while the app is not in the foreground.
///
/// `@pragma('vm:entry-point')` and TOP-LEVEL are both mandatory: the engine
/// looks this function up by handle in a fresh isolate, and the release-mode
/// tree shaker would otherwise remove it, turning every action tap into a
/// silent no-op that no test would catch.
@pragma('vm:entry-point')
void notificationActionBackgroundHandler(NotificationResponse response) {
  // Sync signature (the plugin's), async body: fire and forget, with every
  // failure swallowed. An exception escaping here crashes the isolate and the
  // user's tap does nothing at all.
  handleNotificationActionResponse(response, initializePlugin: true);
}

/// The shared implementation, used by BOTH the background isolate and the
/// foreground callback so the two can never diverge.
///
/// [initializePlugin] must be true only in the background isolate, which
/// starts with an uninitialized plugin. In the FOREGROUND the app has already
/// called initialize() with its tap callbacks attached; initializing a second
/// instance there re-registers on the same platform channel and would drop
/// `onDidReceiveNotificationResponse`, silently killing tap routing for the
/// rest of the session.
Future<void> handleNotificationActionResponse(
  NotificationResponse response, {
  required bool initializePlugin,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // this isolate's cache predates the app's writes
    final store = LocalStore(prefs);
    final result = await resolveNotificationAction(
      store: store,
      actionId: response.actionId,
      payload: response.payload,
      notificationId: response.id ?? 0,
    );
    await applyActionResult(result, initializePlugin: initializePlugin);
  } catch (e) {
    debugPrint('awwad notif: action failed: $e');
  }
}

/// Performs the plugin half of a resolved action: re-arming the snooze. Split
/// from [resolveNotificationAction] so the decision logic stays testable
/// without a plugin binding.
///
/// In the BACKGROUND isolate the plugin must be initialized here; the
/// foreground app's initialize() does not carry over. In the foreground it
/// must NOT be (see handleNotificationActionResponse). Timezones are handled
/// by [_localFrom] for the same reason.
Future<void> applyActionResult(
  NotificationActionResult r, {
  bool initializePlugin = true,
}) async {
  final id = r.snoozedId;
  final when = r.snoozeAt;
  if (id == null || when == null) return;
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    if (initializePlugin) {
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_awwad'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
    }
    await scheduleSnoozeNotification(
      plugin: plugin,
      id: id,
      when: when,
      title: r.snoozeTitle ?? '',
      body: r.snoozeBody ?? '',
    );
  } catch (e) {
    debugPrint('awwad notif: snooze re-arm failed: $e');
  }
}

/// Re-arms one snoozed reminder. Uses the plain `zonedSchedule`-free
/// `periodicallyShow`-free path: a single one-off alarm, inexact-while-idle so
/// it needs no exact-alarm grant (a snooze that lands a few minutes late is
/// acceptable; a snooze that never fires because the grant was revoked is not).
///
/// The re-fired notification deliberately carries NO action buttons: a snooze
/// chain with no end is a dark pattern, and a «تم» here would need the payload
/// that the snooze copy no longer maps to a habit id one-to-one.
Future<void> scheduleSnoozeNotification({
  required FlutterLocalNotificationsPlugin plugin,
  required int id,
  required DateTime when,
  required String title,
  required String body,
}) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'awwad_snooze_v1',
      'Snoozed reminders',
      channelDescription: 'A reminder you asked to be shown again later',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  if (when.isBefore(DateTime.now())) return;
  await plugin.zonedSchedule(
    id,
    title,
    body,
    _localFrom(when),
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

/// A background isolate starts with an EMPTY timezone database, so
/// `tz.local` throws until it is loaded here. The foreground app's
/// initNotifications() ran in a different isolate and does not carry over.
/// The device's current UTC offset is enough for a snooze measured in
/// minutes, so no `flutter_timezone` round-trip (and no DST question) is
/// needed: the alarm lands inside the hour it was set in.
tz.TZDateTime _localFrom(DateTime when) {
  try {
    return tz.TZDateTime.from(when, tz.local);
  } catch (_) {
    tzdata.initializeTimeZones();
    try {
      final off = when.timeZoneOffset;
      tz.setLocalLocation(tz.Location(
        'AWWAD_SNOOZE',
        [tz.minTime],
        [0],
        [tz.TimeZone(off.inMilliseconds, isDst: false, abbreviation: 'FIX')],
      ));
    } catch (_) {
      // keep the package default (UTC)
    }
    return tz.TZDateTime.from(when, tz.local);
  }
}
