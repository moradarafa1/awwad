// No-op notifications for web (and any non-io platform).

Future<void> initNotifications() async {}

Future<void> scheduleDailyReminder(int hour, String title, String body) async {}

Future<void> cancelReminders() async {}
