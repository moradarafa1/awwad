// Motivation content: streak RANKS (levels), the generic RECOVERY TIMELINE
// for break habits, and slip TRIGGER keys (relapse journal). All trilingual
// inline (ar MSA, no em-dash). Thresholds align with the shield badges
// (7/30/60/90) so ranks, shields and stages tell one consistent story.

class StreakRank {
  final int minStreak;
  final String emoji;
  final Map<String, String> name;
  const StreakRank(this.minStreak, this.emoji, this.name);
  String n(String loc) => name[loc] ?? name['ar']!;
}

const List<StreakRank> kRanks = [
  StreakRank(0, '🌱', {'ar': 'بذرة العزم', 'en': 'Seed of resolve', 'fr': 'Graine de volonté'}),
  StreakRank(3, '🌿', {'ar': 'برعم الثبات', 'en': 'Sprout of steadiness', 'fr': 'Pousse de constance'}),
  StreakRank(7, '🛡️', {'ar': 'راسخ الأسبوع', 'en': 'Week warrior', 'fr': 'Vaillant de la semaine'}),
  StreakRank(14, '🏅', {'ar': 'مثابر الأسبوعين', 'en': 'Two-week achiever', 'fr': 'Persévérant des deux semaines'}),
  StreakRank(30, '🥈', {'ar': 'صابر الشهر', 'en': 'Month of patience', 'fr': 'Patient du mois'}),
  StreakRank(60, '🥇', {'ar': 'عزيمة الشهرين', 'en': 'Two-month resolve', 'fr': 'Volonté des deux mois'}),
  StreakRank(90, '💎', {'ar': 'قلب من ماس', 'en': 'Diamond heart', 'fr': 'Cœur de diamant'}),
  StreakRank(180, '🏆', {'ar': 'العوّاد', 'en': 'The Awwad', 'fr': 'Le Awwad'}),
];

StreakRank rankForStreak(int streak) {
  StreakRank r = kRanks.first;
  for (final k in kRanks) {
    if (streak >= k.minStreak) r = k;
  }
  return r;
}

/// The next rank above [streak], or null at the top.
StreakRank? nextRank(int streak) {
  for (final k in kRanks) {
    if (streak < k.minStreak) return k;
  }
  return null;
}

/// Generic recovery-timeline milestones for BREAK habits (clean streak days).
/// Deliberately non-medical neuroplasticity/HRT phrasing; the app already
/// shows a standing "not medical advice" disclaimer.
class RecoveryMilestone {
  final int day;
  final Map<String, String> text;
  const RecoveryMilestone(this.day, this.text);
  String t(String loc) => text[loc] ?? text['ar']!;
}

const List<RecoveryMilestone> kRecoveryTimeline = [
  RecoveryMilestone(1, {
    'ar': 'اليوم الأول: اتخذت القرار، وسجّل دماغك أول انتصار.',
    'en': 'Day 1: the decision is made, and your brain records its first win.',
    'fr': 'Jour 1 : la décision est prise, votre cerveau enregistre sa première victoire.',
  }),
  RecoveryMilestone(3, {
    'ar': 'ثلاثة أيام: حدة الرغبة تبدأ في التراجع بعد الذروة الأولى.',
    'en': 'Day 3: urge intensity starts easing after the first peak.',
    'fr': "Jour 3 : l'intensité de l'envie commence à baisser après le premier pic.",
  }),
  RecoveryMilestone(7, {
    'ar': 'أسبوع كامل: الحلقة العصبية القديمة تفقد قوتها تدريجياً.',
    'en': 'One week: the old habit loop is gradually losing its grip.',
    'fr': "Une semaine : l'ancienne boucle de l'habitude perd peu à peu sa force.",
  }),
  RecoveryMilestone(14, {
    'ar': 'أسبوعان: استجابتك البديلة أصبحت أسرع من اندفاع العادة.',
    'en': 'Two weeks: your competing response now fires faster than the urge.',
    'fr': "Deux semaines : votre réponse alternative devance désormais l'impulsion.",
  }),
  RecoveryMilestone(30, {
    'ar': 'شهر: مسار عصبي جديد يتشكل ويقوى مع كل يوم نظيف.',
    'en': 'One month: a new neural pathway is forming and strengthening daily.',
    'fr': 'Un mois : un nouveau chemin neuronal se forme et se renforce chaque jour.',
  }),
  RecoveryMilestone(60, {
    'ar': 'شهران: السلوك البديل يقترب من التلقائية الكاملة.',
    'en': 'Two months: the replacement behavior is nearing full autopilot.',
    'fr': 'Deux mois : le comportement de remplacement devient presque automatique.',
  }),
  RecoveryMilestone(90, {
    'ar': 'تسعون يوماً: مرحلة التعافي الراسخ، أول دورة إعادة تأهيل اكتملت.',
    'en': 'Ninety days: established recovery, the first rewiring cycle is complete.',
    'fr': 'Quatre-vingt-dix jours : rétablissement consolidé, premier cycle accompli.',
  }),
];

/// Slip triggers (relapse journal). Key is stored on the entry.
class SlipTrigger {
  final String key;
  final String emoji;
  final Map<String, String> label;
  const SlipTrigger(this.key, this.emoji, this.label);
  String l(String loc) => label[loc] ?? label['ar']!;
}

const List<SlipTrigger> kSlipTriggers = [
  SlipTrigger('stress', '😣', {'ar': 'توتر وضغط', 'en': 'Stress', 'fr': 'Stress'}),
  SlipTrigger('boredom', '🥱', {'ar': 'ملل وفراغ', 'en': 'Boredom', 'fr': 'Ennui'}),
  SlipTrigger('loneliness', '😔', {'ar': 'وحدة', 'en': 'Loneliness', 'fr': 'Solitude'}),
  SlipTrigger('fatigue', '😮‍💨', {'ar': 'إرهاق', 'en': 'Fatigue', 'fr': 'Fatigue'}),
  SlipTrigger('social', '👥', {'ar': 'رفقة ومجاملة', 'en': 'Social pressure', 'fr': 'Pression sociale'}),
  SlipTrigger('phone', '📱', {'ar': 'الهاتف والمحتوى', 'en': 'Phone & content', 'fr': 'Téléphone et contenu'}),
  SlipTrigger('hunger', '🍽️', {'ar': 'جوع', 'en': 'Hunger', 'fr': 'Faim'}),
  SlipTrigger('anger', '😠', {'ar': 'غضب', 'en': 'Anger', 'fr': 'Colère'}),
  SlipTrigger('sadness', '😢', {'ar': 'حزن وضيق', 'en': 'Sadness', 'fr': 'Tristesse'}),
  SlipTrigger('other', '✨', {'ar': 'سبب آخر', 'en': 'Other', 'fr': 'Autre'}),
];

SlipTrigger? triggerByKey(String? key) {
  if (key == null) return null;
  for (final t in kSlipTriggers) {
    if (t.key == key) return t;
  }
  return null;
}
