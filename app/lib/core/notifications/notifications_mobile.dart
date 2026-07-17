// Real local-notification implementation for mobile (Android/iOS).
// All notifications are on-device (zero-cost); server push (FCM) is P4.
//
// Notification id namespace (keep stable):
//   1001  daily habit reminder        (repeats daily at reminderHour)
//   1002  daily Ibrahimic-prayer dhikr (repeats daily at dhikrHour)
//   1003  one-off 3-day sign-up nudge  (fires once)
//   2000+ badge/shield congratulations (immediate, one per badge)

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const _habitChannelId = 'awwad_daily';
const _habitChannelName = 'Daily reminder';
const _dhikrChannelId = 'awwad_dhikr';
const _dhikrChannelName = 'Morning dhikr';
const _nudgeChannelId = 'awwad_account';
const _nudgeChannelName = 'Account';
const _badgeChannelId = 'awwad_badges';
const _badgeChannelName = 'Achievements';
// Prayer notifications with the adhan sound. A dedicated channel because an
// Android channel's sound is fixed at creation; the app switches between this
// channel and the silent prayer channel via the user's adhan-sound toggle.
const _adhanChannelId = 'awwad_adhan_v1';
const _adhanChannelName = 'Adhan (prayer call)';

const _reminderId = 1001; // legacy single habit reminder
const _dhikrId = 1002;
const _reengageId = 1003;
const _pomodoroId = 1004; // one-off end-of-phase chime
const _badgeIdBase = 2000;
const _habitReminderBase = 3000; // per-habit, per-time reminders (3000..3059)
const _habitReminderMax = 60;

bool _ready = false;

/// Initialize the plugin + timezone DB. Does NOT request permission (call
/// [ensureNotificationPermission] explicitly, after showing a rationale).
Future<void> initNotifications() async {
  if (_ready) return;
  tzdata.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    // fall back to UTC if the local zone can't be resolved
  }

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  try {
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  } catch (e) {
    // e.g. MissingPluginException under `flutter test`; callers stay no-op.
    debugPrint('awwad notif: init failed: $e');
  }
}

/// Explicitly request OS notification permission and return whether granted.
/// Show an in-app rationale BEFORE calling this.
Future<bool> ensureNotificationPermission() async {
  await initNotifications();
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    final granted = await android.requestNotificationsPermission();
    return granted ?? true; // older Android grants by default
  }
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) {
    final granted =
        await ios.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }
  return false;
}

tz.TZDateTime _nextInstanceOfHour(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

/// zonedSchedule with a per-call guard: ONE failing schedule must not abort
/// the whole reschedule loop (it used to kill every later reminder AND the
/// dhikr), and the failure is printed so a broken release pipeline (like the
/// pre-proguard R8/GSON breakage) is visible in `adb logcat` instead of
/// silently eating every reminder.
Future<void> _safeZoned(
  int id,
  String title,
  String body,
  tz.TZDateTime when,
  NotificationDetails details, {
  DateTimeComponents? match,
}) async {
  try {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  } catch (e) {
    debugPrint('awwad notif: schedule #$id failed: $e');
  }
}

Future<void> scheduleDailyReminder(int hour, String title, String body) async {
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _safeZoned(_reminderId, title, body, _nextInstanceOfHour(hour), details,
      match: DateTimeComponents.time); // repeat daily
}

/// Daily Ibrahimic-prayer dhikr. The [body] is the Arabic dhikr; a BigText
/// style lets the full text expand on Android.
Future<void> scheduleDhikrReminder(int hour, String title, String body) async {
  await initNotifications();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _dhikrChannelId,
      _dhikrChannelName,
      channelDescription: 'Daily morning dhikr',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  await _safeZoned(_dhikrId, title, body, _nextInstanceOfHour(hour), details,
      match: DateTimeComponents.time); // repeat daily
}

/// One-off sign-up re-engagement nudge (no matchDateTimeComponents => fires once).
Future<void> scheduleReengageNudge(Duration delay, String title, String body) async {
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _nudgeChannelId,
      _nudgeChannelName,
      channelDescription: 'Account and sync',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _safeZoned(_reengageId, title, body,
      tz.TZDateTime.now(tz.local).add(delay), details);
}

/// Immediate congratulation when a shield/badge is earned.
Future<void> showBadgeNotification(int slot, String title, String body) async {
  await initNotifications();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _badgeChannelId,
      _badgeChannelName,
      channelDescription: 'Badges and shields',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  await _plugin.show(_badgeIdBase + (slot.abs() % 900), title, body, details);
}

/// One per-habit, per-time daily reminder ([slot] 0.._habitReminderMax-1).
Future<void> scheduleHabitReminder(
    int slot, int hour, String title, String body) async {
  if (slot < 0 || slot >= _habitReminderMax) return;
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _safeZoned(_habitReminderBase + slot, title, body,
      _nextInstanceOfHour(hour), details,
      match: DateTimeComponents.time); // repeat daily
}

const _testNowId = 1998;
const _testLaterId = 1999;
const _monthlyId = 1005; // end-of-month report reminder

/// Schedules the end-of-month report notification at 20:00 on the last day of
/// the current month (re-armed on each app open; a no-op if already past).
Future<void> scheduleMonthlyReport(String title, String body) async {
  await initNotifications();
  final now = tz.TZDateTime.now(tz.local);
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  var when = tz.TZDateTime(tz.local, now.year, now.month, lastDay, 20);
  if (when.isBefore(now)) {
    // This month's slot passed: aim at next month's last day.
    final ny = now.month == 12 ? now.year + 1 : now.year;
    final nm = now.month == 12 ? 1 : now.month + 1;
    final nLast = DateTime(ny, nm + 1, 0).day;
    when = tz.TZDateTime(tz.local, ny, nm, nLast, 20);
  }
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _badgeChannelId,
      _badgeChannelName,
      channelDescription: 'Monthly report',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  await _safeZoned(_monthlyId, title, body, when, details);
}

Future<void> cancelMonthlyReport() async {
  try {
    await _plugin.cancel(_monthlyId);
  } catch (_) {}
}

/// Owner-facing sanity check: one notification NOW plus one scheduled in 60s.
/// The immediate one proves the permission/channel path; the delayed one
/// proves the AlarmManager + receiver path (the part that used to be broken).
Future<void> sendTestNotifications(
    String title, String nowBody, String laterBody) async {
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  try {
    await _plugin.show(_testNowId, title, nowBody, details);
  } catch (e) {
    debugPrint('awwad notif: test show failed: $e');
  }
  await _safeZoned(_testLaterId, title, laterBody,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 60)), details);
}

/// One-off notification when the running Pomodoro phase ends. Because this is
/// an OS alarm, it fires ON TIME even if the app is killed mid-session, which
/// is what makes the timer trustworthy on mobile.
Future<void> schedulePomodoroDone(Duration after, String title, String body) async {
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _safeZoned(
      _pomodoroId, title, body, tz.TZDateTime.now(tz.local).add(after), details);
}

Future<void> cancelPomodoroDone() async {
  try {
    await _plugin.cancel(_pomodoroId);
  } catch (_) {
    // plugin unavailable (tests) - nothing scheduled anyway
  }
}

/// Exact-moment one-off (prayer times shift daily, so these are scheduled as
/// absolute datetimes for the next ~2 days and rebuilt on every app open).
Future<void> scheduleAt(
    int id, DateTime when, String title, String body) async {
  await initNotifications();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  await _safeZoned(id, title, body, tz.TZDateTime.from(when, tz.local), details);
}

/// A prayer notification that plays the ADHAN sound (Android). The sound is the
/// raw resource `android/app/src/main/res/raw/adhan` (ships CC0 by default;
/// the owner can drop in a licensed Makkah/Qatami file of the same name).
/// iOS keeps its default sound until a bundled .caf is provided (documented).
Future<void> scheduleAdhan(
    int id, DateTime when, String title, String body) async {
  await initNotifications();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _adhanChannelId,
      _adhanChannelName,
      channelDescription: 'The call to prayer at prayer time',
      importance: Importance.max,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('adhan'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(
      // A licensed short adhan .caf can be bundled and named here later.
      presentSound: true,
    ),
  );
  await _safeZoned(id, title, body, tz.TZDateTime.from(when, tz.local), details);
}

/// Cancels an inclusive id range (used for the 4000-4299 prayer window).
Future<void> cancelIdRange(int from, int to) async {
  for (var i = from; i <= to; i++) {
    try {
      await _plugin.cancel(i);
    } catch (_) {
      return; // plugin unavailable (tests): nothing scheduled anyway
    }
  }
}

/// Weekly repeating reminder (e.g. surah Al-Kahf on Friday). [weekday] uses
/// DateTime constants (DateTime.friday = 5).
Future<void> scheduleWeekly(
    int id, int weekday, int hour, int minute, String title, String body) async {
  await initNotifications();
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _habitChannelId,
      _habitChannelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  var when = tz.TZDateTime.now(tz.local);
  when = tz.TZDateTime(
      tz.local, when.year, when.month, when.day, hour, minute);
  while (when.weekday != weekday || when.isBefore(tz.TZDateTime.now(tz.local))) {
    when = when.add(const Duration(days: 1));
  }
  try {
    await _plugin.zonedSchedule(
      id, title, body, when, details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  } catch (e) {
    debugPrint('awwad notif: weekly #$id failed: $e');
  }
}

/// Clears all per-habit reminders (and the legacy single one) before a reschedule.
Future<void> cancelHabitReminders() async {
  for (var i = 0; i < _habitReminderMax; i++) {
    await _plugin.cancel(_habitReminderBase + i);
  }
  await _plugin.cancel(_reminderId);
}

Future<void> cancelReminders() async {
  await _plugin.cancel(_reminderId);
  await cancelHabitReminders();
}

Future<void> cancelDhikr() async {
  await _plugin.cancel(_dhikrId);
}

Future<void> cancelReengageNudge() async {
  await _plugin.cancel(_reengageId);
}
