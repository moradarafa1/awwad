// Weekly insight (MANDATE_PLAN CU8). One honest sentence a week, computed
// PURELY from the entries already stored on the device: the dominant slip
// trigger, the cleanest weekday, and whether urges are rising or easing
// versus the previous week. Mirrors monthly_report.dart's pure-computation
// pattern so it is fully unit-testable and costs nothing to run offline.

import '../catalog/motivation.dart' show kSlipTriggers;
import '../models.dart';

class WeeklyInsight {
  /// Non-skip entries in the last 7 days. Below [kMinEntries] the card is
  /// not shown at all: a "finding" from two data points is noise.
  final int logged;
  final int cleanDays;
  final int slipDays;

  /// Trigger key that caused the most slips this week, or null.
  final String? topTrigger;
  final int topTriggerCount;

  /// 1-7 (DateTime.monday..sunday) with the best clean record, or null.
  final int? bestWeekday;

  /// Mean primary metric this week minus last week. Negative = easing for a
  /// break habit (lower urge), positive = rising.
  final double urgeDelta;

  const WeeklyInsight({
    required this.logged,
    required this.cleanDays,
    required this.slipDays,
    required this.topTrigger,
    required this.topTriggerCount,
    required this.bestWeekday,
    required this.urgeDelta,
  });

  static const int kMinEntries = 4;

  bool get hasEnoughData => logged >= kMinEntries;
  double get successRate => logged == 0 ? 0 : cleanDays / logged;
}

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _parseDay(String key) {
  final p = key.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Computes the insight for [habitId] over the 7 days ending today.
/// [now] is injectable so tests do not depend on the wall clock.
WeeklyInsight computeWeeklyInsight(
  List<DailyEntry> entries,
  String habitId, {
  DateTime? now,
}) {
  final today = _midnight(now ?? DateTime.now());
  final weekStart = today.subtract(const Duration(days: 6));
  final prevStart = today.subtract(const Duration(days: 13));

  var logged = 0, clean = 0, slips = 0;
  final triggerCounts = <String, int>{};
  final cleanByWeekday = <int, int>{};
  final totalByWeekday = <int, int>{};
  var thisSum = 0.0, thisN = 0, prevSum = 0.0, prevN = 0;

  for (final e in entries) {
    if (e.habitId != habitId) continue;
    final d = _parseDay(e.date);
    if (d == null) continue;
    final inThis = !d.isBefore(weekStart) && !d.isAfter(today);
    final inPrev = !d.isBefore(prevStart) && d.isBefore(weekStart);
    if (!inThis && !inPrev) continue;
    if (e.isSkip) continue; // excused days are transparent everywhere

    if (inThis) {
      logged++;
      thisSum += e.urge;
      thisN++;
      totalByWeekday[d.weekday] = (totalByWeekday[d.weekday] ?? 0) + 1;
      if (e.didSlip) {
        slips++;
        final t = e.trigger;
        if (t != null && t.isNotEmpty) {
          triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
        }
      } else {
        clean++;
        cleanByWeekday[d.weekday] = (cleanByWeekday[d.weekday] ?? 0) + 1;
      }
    } else {
      prevSum += e.urge;
      prevN++;
    }
  }

  String? topTrigger;
  var topCount = 0;
  triggerCounts.forEach((k, v) {
    if (v > topCount) {
      topTrigger = k;
      topCount = v;
    }
  });

  // Best weekday = highest clean RATE, needing at least one clean day, with
  // the count as the tie-breaker so a single lucky day cannot win.
  int? bestWeekday;
  var bestScore = -1.0;
  cleanByWeekday.forEach((day, cleanN) {
    final total = totalByWeekday[day] ?? cleanN;
    final score = cleanN / total + cleanN / 100;
    if (score > bestScore) {
      bestScore = score;
      bestWeekday = day;
    }
  });

  final delta = (thisN == 0 || prevN == 0)
      ? 0.0
      : (thisSum / thisN) - (prevSum / prevN);

  return WeeklyInsight(
    logged: logged,
    cleanDays: clean,
    slipDays: slips,
    topTrigger: topTrigger,
    topTriggerCount: topCount,
    bestWeekday: bestWeekday,
    urgeDelta: delta,
  );
}

const Map<int, Map<String, String>> _kWeekdayNames = {
  DateTime.monday: {'ar': 'الاثنين', 'en': 'Monday', 'fr': 'lundi'},
  DateTime.tuesday: {'ar': 'الثلاثاء', 'en': 'Tuesday', 'fr': 'mardi'},
  DateTime.wednesday: {'ar': 'الأربعاء', 'en': 'Wednesday', 'fr': 'mercredi'},
  DateTime.thursday: {'ar': 'الخميس', 'en': 'Thursday', 'fr': 'jeudi'},
  DateTime.friday: {'ar': 'الجمعة', 'en': 'Friday', 'fr': 'vendredi'},
  DateTime.saturday: {'ar': 'السبت', 'en': 'Saturday', 'fr': 'samedi'},
  DateTime.sunday: {'ar': 'الأحد', 'en': 'Sunday', 'fr': 'dimanche'},
};

String weekdayName(int weekday, String loc) =>
    _kWeekdayNames[weekday]?[loc] ?? _kWeekdayNames[weekday]?['ar'] ?? '';

/// One actionable MSA sentence per dominant trigger. Behavioural advice
/// (HRT), never a religious ruling.
const Map<String, Map<String, String>> kTriggerAdvice = {
  'stress': {
    'ar': 'التوتر هو محفزك الأول هذا الأسبوع. جرّب تنفساً بطيئاً لدقيقتين أو وضوءاً بارداً قبل أن تقترب من العادة.',
    'en': 'Stress was your main trigger this week. Try two minutes of slow breathing, or cold water, before the habit gets close.',
    'fr': "Le stress a été votre déclencheur principal. Essayez deux minutes de respiration lente avant que l'habitude n'approche.",
  },
  'boredom': {
    'ar': 'الفراغ هو محفزك الأول هذا الأسبوع. جهّز بديلاً جاهزاً: كتاب قريب أو مشي قصير أو مهمة صغيرة تبدأها فوراً.',
    'en': 'Boredom was your main trigger this week. Keep a ready alternative: a book within reach, a short walk, a small task you can start at once.',
    'fr': "L'ennui a été votre déclencheur principal. Gardez une alternative prête : un livre à portée, une marche, une petite tâche.",
  },
  'loneliness': {
    'ar': 'الوحدة هي محفزك الأول هذا الأسبوع. اتصل بشخص تثق به في اللحظة نفسها بدل أن تواجهها وحدك.',
    'en': 'Loneliness was your main trigger this week. Call someone you trust in that same moment instead of facing it alone.',
    'fr': "La solitude a été votre déclencheur principal. Appelez une personne de confiance au moment même.",
  },
  'fatigue': {
    'ar': 'الإرهاق هو محفزك الأول هذا الأسبوع. النوم مبكراً ليلة واحدة قد يقيك أكثر من أي مقاومة في اللحظة.',
    'en': 'Fatigue was your main trigger this week. One earlier night can protect you more than any in-the-moment resistance.',
    'fr': "La fatigue a été votre déclencheur principal. Une nuit plus tôt vous protège plus que toute résistance sur le moment.",
  },
  'social': {
    'ar': 'الرفقة هي محفزك الأول هذا الأسبوع. جهّز ردّاً قصيراً مهذباً مسبقاً، فالتردد هو ما يوقعك.',
    'en': 'Social pressure was your main trigger this week. Prepare a short polite answer in advance; hesitation is what catches you.',
    'fr': "La pression sociale a été votre déclencheur. Préparez une réponse courte et polie à l'avance.",
  },
  'phone': {
    'ar': 'الهاتف هو محفزك الأول هذا الأسبوع. أبعده عن متناول يدك في أوقات ضعفك، وفعّل حدّاً يومياً للتطبيق الذي يجرّك.',
    'en': 'Your phone was the main trigger this week. Keep it out of reach at your weak hours, and set a daily limit on the app that pulls you.',
    'fr': "Le téléphone a été votre déclencheur. Éloignez-le aux heures faibles et fixez une limite à l'application concernée.",
  },
  'hunger': {
    'ar': 'الجوع هو محفزك الأول هذا الأسبوع. وجبة منتظمة أو سناك صحي في متناولك يقطع الطريق على العادة.',
    'en': 'Hunger was your main trigger this week. A regular meal or a healthy snack within reach cuts the habit off.',
    'fr': "La faim a été votre déclencheur. Un repas régulier ou un en-cas sain coupe court à l'habitude.",
  },
  'anger': {
    'ar': 'الغضب هو محفزك الأول هذا الأسبوع. غيّر وضعك ومكانك أولاً، ثم عد للقرار بعد أن يهدأ.',
    'en': 'Anger was your main trigger this week. Change your posture and your room first, then decide once it settles.',
    'fr': "La colère a été votre déclencheur. Changez de position et de pièce, puis décidez une fois calmé.",
  },
  'sadness': {
    'ar': 'الحزن هو محفزك الأول هذا الأسبوع. لا تواجهه بالعادة، بل بحديث صادق مع من تثق به أو بكتابة ما تشعر.',
    'en': 'Sadness was your main trigger this week. Do not meet it with the habit; meet it with an honest talk or by writing it down.',
    'fr': "La tristesse a été votre déclencheur. N'y répondez pas par l'habitude, mais par une discussion sincère ou l'écriture.",
  },
  'other': {
    'ar': 'حدّد محفزك بدقة أكبر في تسجيلاتك القادمة، فمعرفة المحفز نصف الطريق إلى تجاوزه.',
    'en': 'Name your trigger more precisely in the coming logs: knowing the trigger is half of beating it.',
    'fr': "Nommez votre déclencheur plus précisément : le connaître, c'est déjà la moitié du chemin.",
  },
};

/// Advice for the week's dominant trigger, or null when there is none.
String? triggerAdvice(String? triggerKey, String loc) {
  if (triggerKey == null) return null;
  final m = kTriggerAdvice[triggerKey] ?? kTriggerAdvice['other']!;
  return m[loc] ?? m['ar'];
}

/// True when [key] is a trigger the app actually offers (guards against a
/// stale key from an older build).
bool isKnownTrigger(String? key) =>
    key != null && kSlipTriggers.any((t) => t.key == key);
