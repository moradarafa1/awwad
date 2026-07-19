// No-op notifications for web (and any non-io platform). Every function here
// MUST mirror a signature in notifications_mobile.dart or the web build breaks.

Future<void> initNotifications() async {}

Future<bool> ensureNotificationPermission() async => false;

Future<void> scheduleDailyReminder(int hour, String title, String body) async {}

Future<void> scheduleHabitReminder(
    int slot, int hour, String title, String body) async {}

Future<void> cancelHabitReminders() async {}

Future<void> scheduleDhikrReminder(int hour, String title, String body) async {}

Future<void> scheduleReengageNudge(
    Duration delay, String title, String body) async {}

Future<void> showBadgeNotification(int slot, String title, String body) async {}

Future<void> schedulePomodoroDone(
    Duration after, String title, String body) async {}

Future<void> sendTestNotifications(
    String title, String nowBody, String laterBody) async {}

Future<void> scheduleAt(
    int id, DateTime when, String title, String body) async {}

Future<void> scheduleAdhan(
    int id, DateTime when, String title, String body) async {}

Future<void> cancelIdRange(int from, int to) async {}

Future<void> scheduleWeekly(int id, int weekday, int hour, int minute,
    String title, String body) async {}

Future<void> scheduleMonthlyReport(String title, String body) async {}

Future<void> cancelMonthlyReport() async {}

Future<void> cancelPomodoroDone() async {}

Future<void> cancelReminders() async {}

Future<void> cancelDhikr() async {}

Future<void> cancelReengageNudge() async {}

Future<bool> canUseExactAlarms() async => false;

Future<bool> requestExactAlarmsPermission() async => false;

Future<bool> osNotificationsEnabled() async => true;
