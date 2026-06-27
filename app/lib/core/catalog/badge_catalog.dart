// Local mirror of `badge_definitions` + a pure-Dart evaluator.
// Kept in sync with supabase/seed.sql. In P4 the server re-validates awards.

class BadgeDef {
  final String key;
  final String tier; // bronze/silver/gold/diamond/special
  final String category; // streak/consistency/milestone/recovery
  final Map<String, String> title; // ar/en/fr
  final Map<String, String> description;
  final String icon;
  final String criteriaType; // streak_clean_days/days_logged/first_log/comeback_after_relapse
  final int threshold;

  const BadgeDef({
    required this.key,
    required this.tier,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.criteriaType,
    required this.threshold,
  });

  String t(String locale) => title[locale] ?? title['ar'] ?? key;
  String d(String locale) => description[locale] ?? description['ar'] ?? '';
}

const List<BadgeDef> kBadges = [
  BadgeDef(key: 'first_log', tier: 'bronze', category: 'milestone', icon: '🌱', criteriaType: 'first_log', threshold: 1,
    title: {'ar': 'أول خطوة', 'en': 'First Step', 'fr': 'Premier pas'},
    description: {'ar': 'سجّلت أول يوم — البداية أصعب خطوة', 'en': 'You logged your first day.', 'fr': 'Votre premier jour enregistré.'}),
  BadgeDef(key: 'streak_3', tier: 'bronze', category: 'streak', icon: '💪', criteriaType: 'streak_clean_days', threshold: 3,
    title: {'ar': '٣ أيام متتالية', 'en': '3-Day Streak', 'fr': 'Série de 3 jours'},
    description: {'ar': 'العادة بدأت تتشكّل', 'en': 'The habit is forming.', 'fr': 'L\'habitude se forme.'}),
  BadgeDef(key: 'streak_7', tier: 'bronze', category: 'streak', icon: '⭐', criteriaType: 'streak_clean_days', threshold: 7,
    title: {'ar': 'أسبوع كامل', 'en': 'One Week', 'fr': 'Une semaine'},
    description: {'ar': 'أسبوع بلا تعثّر', 'en': 'A full clean week.', 'fr': 'Une semaine complète.'}),
  BadgeDef(key: 'streak_14', tier: 'bronze', category: 'streak', icon: '🔥', criteriaType: 'streak_clean_days', threshold: 14,
    title: {'ar': 'أسبوعان', 'en': 'Two Weeks', 'fr': 'Deux semaines'},
    description: {'ar': 'إنجاز حقيقي', 'en': 'Two weeks strong.', 'fr': 'Deux semaines.'}),
  BadgeDef(key: 'streak_30_silver', tier: 'silver', category: 'streak', icon: '🥈', criteriaType: 'streak_clean_days', threshold: 30,
    title: {'ar': 'درع فضي — ٣٠ يوم', 'en': 'Silver Shield — 30 Days', 'fr': 'Bouclier argent — 30 jours'},
    description: {'ar': 'شهر كامل! إنجاز يستحق الفخر', 'en': 'A full month!', 'fr': 'Un mois entier !'}),
  BadgeDef(key: 'streak_60_gold', tier: 'gold', category: 'streak', icon: '🥇', criteriaType: 'streak_clean_days', threshold: 60,
    title: {'ar': 'درع ذهبي — ٦٠ يوم', 'en': 'Gold Shield — 60 Days', 'fr': 'Bouclier or — 60 jours'},
    description: {'ar': 'شهران متتاليان', 'en': 'Two months in a row!', 'fr': 'Deux mois d\'affilée !'}),
  BadgeDef(key: 'streak_90_diamond', tier: 'diamond', category: 'streak', icon: '💎', criteriaType: 'streak_clean_days', threshold: 90,
    title: {'ar': 'درع ماسي — ٩٠ يوم', 'en': 'Diamond Shield — 90 Days', 'fr': 'Bouclier diamant — 90 jours'},
    description: {'ar': '٩٠ يوم! العادة أصبحت جزءاً منك', 'en': '90 days — a new you!', 'fr': '90 jours !'}),
  BadgeDef(key: 'streak_180_diamond', tier: 'diamond', category: 'streak', icon: '💎', criteriaType: 'streak_clean_days', threshold: 180,
    title: {'ar': 'ماسة الصبر — ١٨٠ يوم', 'en': 'Patience Diamond — 180 Days', 'fr': 'Diamant — 180 jours'},
    description: {'ar': 'نصف عام من الثبات', 'en': 'Half a year of consistency.', 'fr': 'Six mois de constance.'}),
  BadgeDef(key: 'logged_30', tier: 'silver', category: 'consistency', icon: '📈', criteriaType: 'days_logged', threshold: 30,
    title: {'ar': 'مواظب — ٣٠ تسجيلة', 'en': 'Consistent — 30 Logs', 'fr': 'Assidu — 30 journaux'},
    description: {'ar': '٣٠ يوم من المتابعة', 'en': '30 days of tracking.', 'fr': '30 jours de suivi.'}),
];

BadgeDef? badgeByKey(String key) {
  for (final b in kBadges) {
    if (b.key == key) return b;
  }
  return null;
}

/// Returns the set of badge keys the user qualifies for given current stats.
Set<String> evaluateBadges({
  required int currentStreak,
  required int daysLogged,
  required bool hasComeback,
}) {
  final earned = <String>{};
  for (final b in kBadges) {
    switch (b.criteriaType) {
      case 'first_log':
        if (daysLogged >= 1) earned.add(b.key);
        break;
      case 'streak_clean_days':
        if (currentStreak >= b.threshold) earned.add(b.key);
        break;
      case 'days_logged':
        if (daysLogged >= b.threshold) earned.add(b.key);
        break;
      case 'comeback_after_relapse':
        if (hasComeback) earned.add(b.key);
        break;
    }
  }
  return earned;
}
