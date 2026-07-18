// Applies the user's notification preferences to the on-device schedule.
// Shared by HomeShell (on launch) and Settings (on toggle change) so the two
// never drift. All underlying calls are no-ops on web.

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../content/dhikr.dart';
import '../models.dart';
import 'notifications.dart';

/// One scheduled habit reminder (a habit may have several times).
class HabitReminderSpec {
  final int hour;
  final String title;
  final String body;
  const HabitReminderSpec(this.hour, this.title, this.body);
}

/// Build the reminder list for all habits at all their chosen times.
List<HabitReminderSpec> habitRemindersFor(List<Habit> habits, String loc) {
  final body = _kReminderBody[loc] ?? _kReminderBody['ar']!;
  final out = <HabitReminderSpec>[];
  for (final h in habits) {
    for (final hour in h.times) {
      out.add(HabitReminderSpec(hour, h.title, body));
    }
  }
  return out;
}

Future<void> applyNotificationSchedule({
  required bool enabled,
  required List<HabitReminderSpec> habitReminders,
  required bool dhikrEnabled,
  required bool showReligious,
  required int dhikrHour,
  required String dhikrTitle,
}) async {
  await cancelHabitReminders(); // clear old set before (re)scheduling
  if (!enabled) {
    await cancelDhikr();
    await cancelReengageNudge(); // honor a global opt-out for the pending nudge
    return;
  }
  // iOS keeps only the 64 SOONEST pending requests and silently drops the
  // rest; the prayer window alone can hold ~24. Capping habit slots at 30
  // there keeps prayers + habits + singletons safely under 64. Android has
  // no such limit and keeps the full 60.
  final maxSlots =
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ? 30 : 60;
  var slot = 0;
  for (final r in habitReminders) {
    if (slot >= maxSlots) break;
    await scheduleHabitReminder(slot++, r.hour, r.title, r.body);
  }
  if (dhikrEnabled && showReligious) {
    await scheduleDhikrReminder(dhikrHour, dhikrTitle, kIbrahimicPrayer);
  } else {
    await cancelDhikr();
  }
}

const Map<String, String> _kReminderBody = {
  'ar': 'حان وقت تسجيل هذه العادة. خطوة صغيرة اليوم 🌿',
  'en': 'Time to log this habit. One small step today 🌿',
  'fr': "C'est l'heure d'enregistrer cette habitude. Un petit pas aujourd'hui 🌿",
};

/// End-of-month report notification copy (fired on the last day at 20:00).
const Map<String, Map<String, String>> kMonthlyReportNotif = {
  'ar': {
    'title': 'تقرير شهرك جاهز 📊',
    'body': 'اطّلع على تقدّمك هذا الشهر في عاداتك، ومعه كلمة تشجيع لكل عادة.'
  },
  'en': {
    'title': 'Your monthly report is ready 📊',
    'body': "See this month's progress across your habits, with a word of encouragement."
  },
  'fr': {
    'title': 'Votre rapport mensuel est prêt 📊',
    'body': "Découvrez vos progrès du mois, avec un mot d'encouragement par habitude."
  },
};
