// End-of-month report (TODO 0d Phase C). Pure computation over the stored
// entries so it is fully unit-testable; the screen and the notification just
// render/trigger it. For each habit it summarises the CURRENT month and offers
// a per-habit relapse-recovery tip (scientific/HRT for behavioural habits,
// islamweb-sourced encouragement for religious ones, a generic template for
// custom habits).

import '../models.dart';

class HabitMonthReport {
  final Habit habit;
  final int loggedDays; // non-skip entries this month
  final int cleanDays; // break: no-slip; build: did the habit
  final int skipDays; // excused days this month
  final int slipDays; // break-track slips this month
  final int bestStreak; // longest in-month clean streak
  const HabitMonthReport({
    required this.habit,
    required this.loggedDays,
    required this.cleanDays,
    required this.skipDays,
    required this.slipDays,
    required this.bestStreak,
  });

  double get successRate =>
      loggedDays == 0 ? 0 : cleanDays / loggedDays;
}

class MonthlyReport {
  final int year;
  final int month; // 1..12
  final List<HabitMonthReport> habits;
  const MonthlyReport(
      {required this.year, required this.month, required this.habits});

  bool get isEmpty => habits.every((h) => h.loggedDays == 0);
}

int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

/// Build the report for [year]/[month] (defaults to the current month) from all
/// habits + entries.
MonthlyReport buildMonthlyReport(
  List<Habit> habits,
  List<DailyEntry> entries, {
  int? year,
  int? month,
}) {
  final now = DateTime.now();
  final y = year ?? now.year;
  final m = month ?? now.month;
  final prefix =
      '$y-${m.toString().padLeft(2, '0')}-'; // entry.date is yyyy-MM-dd

  final reports = <HabitMonthReport>[];
  for (final h in habits) {
    final monthEntries = entries
        .where((e) => e.habitId == h.id && e.date.startsWith(prefix))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var logged = 0, clean = 0, skip = 0, slip = 0;
    var run = 0, best = 0;
    final isBreak = h.track == 'break';
    for (final e in monthEntries) {
      if (e.isSkip) {
        skip++;
        continue; // excused days do not break the in-month streak
      }
      logged++;
      // "good" day = a break habit with no slip, or a build habit that was done.
      final good = isBreak ? !e.didSlip : !e.didSlip;
      if (good) {
        clean++;
        run++;
        if (run > best) best = run;
      } else {
        slip++;
        run = 0;
      }
    }
    reports.add(HabitMonthReport(
      habit: h,
      loggedDays: logged,
      cleanDays: clean,
      skipDays: skip,
      slipDays: slip,
      bestStreak: best,
    ));
  }
  return MonthlyReport(year: y, month: m, habits: reports);
}

/// True on the LAST day of the month (used to fire the report notification).
bool isLastDayOfMonth(DateTime d) => d.day == _daysInMonth(d.year, d.month);

/// A per-habit relapse-recovery tip. Religious habits get an islamweb-anchored
/// encouragement; known behavioural habits get an HRT/scientific line; custom
/// habits get a sensible generic template. Never a fatwa of our own.
String relapseTip(Habit habit, String locale) {
  final key = habit.catalogKey;
  final isBuild = habit.track == 'build';
  if (key != null && _kReligious.contains(key)) {
    return _t(_kTipReligious, locale);
  }
  if (habit.isCustom || key == null) {
    return _t(isBuild ? _kTipCustomBuild : _kTipCustomBreak, locale);
  }
  return _t(isBuild ? _kTipBuild : _kTipBreak, locale);
}

const _kReligious = {
  'pray_on_time', 'wake_fajr', 'adhkar', 'salawat', 'honor_parents', 'dua',
  'surah_kahf', 'break_porn', 'secret_habit', 'listening_wird', 'daily_quran',
  'qiyam', 'voluntary_fasting', 'istighfar', 'gratitude', 'daily_charity',
  'keeping_ties', 'gossip',
};

String _t(Map<String, String> m, String loc) => m[loc] ?? m['ar']!;

const _kTipReligious = {
  'ar': 'إن تعثّرت فلا تيأس، فباب التوبة مفتوح والله يفرح بتوبة عبده. جدّد نيّتك، واستعن بصحبة صالحة، وابدأ من جديد بخطوة صغيرة اليوم.',
  'en': 'If you slipped, do not despair: the door of repentance is open. Renew your intention, seek good company, and start again with one small step today.',
  'fr': "Si vous avez trébuché, ne désespérez pas : la porte du repentir est ouverte. Renouvelez votre intention et recommencez par un petit pas aujourd'hui.",
};
const _kTipBreak = {
  'ar': 'الانتكاسة ليست فشلاً بل جزء من التعافي. راجع ما الذي سبقها من مواقف، وأزل المثيرات من محيطك، وكافئ نفسك على كل يوم نظيف.',
  'en': 'A relapse is not failure, it is part of recovery. Review what triggered it, remove the cues from your environment, and reward each clean day.',
  'fr': "Une rechute n'est pas un échec, c'est une étape du rétablissement. Analysez le déclencheur, retirez les stimuli et récompensez chaque jour réussi.",
};
const _kTipBuild = {
  'ar': 'إن انقطعت فلا تترك العادة كلها بسبب يوم. اربط عادتك بموعد ثابت أو عادة قائمة، واجعل خطوتك أصغر حتى لا تُفوّتها.',
  'en': 'Missing a day is no reason to drop the whole habit. Anchor it to a fixed time or an existing routine, and make the step so small you cannot miss it.',
  'fr': "Manquer un jour ne justifie pas d'abandonner. Ancrez l'habitude à un moment fixe et réduisez l'effort pour ne plus la manquer.",
};
const _kTipCustomBreak = {
  'ar': 'حدّد المواقف التي تدفعك إلى العادة، وضع بديلاً جاهزاً تفعله بدلاً منها، وتابع تقدّمك يوماً بيوم.',
  'en': 'Identify the situations that trigger the habit, prepare a ready alternative to do instead, and track your progress day by day.',
  'fr': "Identifiez les situations déclencheuses, préparez une alternative prête, et suivez vos progrès jour après jour.",
};
const _kTipCustomBuild = {
  'ar': 'اجعل عادتك واضحة وسهلة البدء، واربطها بوقت ثابت في يومك، واحتفل بكل مرة تنجزها لتترسّخ.',
  'en': 'Make your habit clear and easy to start, tie it to a fixed time in your day, and celebrate each time you do it so it takes root.',
  'fr': "Rendez l'habitude claire et facile à commencer, liez-la à un moment fixe et célébrez chaque réussite.",
};
