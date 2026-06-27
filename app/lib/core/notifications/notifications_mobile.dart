// Real local-notification implementation for mobile (Android/iOS).
// Schedules a daily reminder at the user's chosen hour. Server-pushed nudges
// (FCM) are wired in P4; this gives a zero-cost on-device reminder now.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const _channelId = 'awwad_daily';
const _channelName = 'Daily reminder';
const _reminderId = 1001;

bool _ready = false;

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
  const ios = DarwinInitializationSettings();
  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );

  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  await _plugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  _ready = true;
}

tz.TZDateTime _nextInstanceOfHour(int hour) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

Future<void> scheduleDailyReminder(int hour, String title, String body) async {
  await initNotifications();
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily habit reminder',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  await _plugin.zonedSchedule(
    _reminderId,
    title,
    body,
    _nextInstanceOfHour(hour),
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // repeat daily
  );
}

Future<void> cancelReminders() async {
  await _plugin.cancel(_reminderId);
}
