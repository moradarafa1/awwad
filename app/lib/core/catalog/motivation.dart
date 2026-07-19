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

// ---------------------------------------------------------------------------
// DAILY ROTATING ENCOURAGEMENT (MANDATE_PLAN CU6)
// One short line per day, chosen deterministically from the day key so the
// whole app agrees on today's line offline, and it changes every morning.
// Two pools: GENERAL (always eligible) and FAITH (only when the user keeps
// religious content on). The faith lines are plain encouragement in an
// Islamic register: no verse or hadith is quoted or attributed here, since
// every quoted religious text in this app must come from the verified
// pipeline (see core/content/dhikr.dart and the islamweb-sourced content).
// MSA, no em-dash.
// ---------------------------------------------------------------------------

class DailyLine {
  final Map<String, String> text;
  const DailyLine(this.text);
  String t(String loc) => text[loc] ?? text['ar']!;
}

const List<DailyLine> kDailyGeneral = [
  DailyLine({'ar': 'خطوةٌ صغيرةٌ اليوم خيرٌ من خطةٍ كبيرةٍ تؤجَّل.', 'en': 'A small step today beats a grand plan postponed.', 'fr': "Un petit pas aujourd'hui vaut mieux qu'un grand plan reporté."}),
  DailyLine({'ar': 'أنت لا تبني يوماً واحداً، بل تبني الشخص الذي ستكونه.', 'en': 'You are not building one day; you are building who you become.', 'fr': "Vous ne bâtissez pas un jour, mais la personne que vous devenez."}),
  DailyLine({'ar': 'التعثّر ليس نهاية الطريق، بل جزءٌ من تعلّمه.', 'en': 'A stumble is not the end of the road; it is part of learning it.', 'fr': "Un faux pas n'est pas la fin du chemin, mais une étape pour l'apprendre."}),
  DailyLine({'ar': 'اجعل البداية سهلة جداً حتى لا تجد عذراً للتأجيل.', 'en': 'Make starting so easy that postponing has no excuse.', 'fr': "Rendez le départ si facile qu'aucune excuse ne tienne."}),
  DailyLine({'ar': 'ما تكرّره كل يوم يصير طبعاً، فاختر ما تكرّره بعناية.', 'en': 'What you repeat daily becomes your nature; choose it carefully.', 'fr': "Ce que vous répétez chaque jour devient votre nature, choisissez-le avec soin."}),
  DailyLine({'ar': 'قلّل من قوّة المثير قبل أن تختبر قوّة إرادتك.', 'en': 'Weaken the trigger before you test your willpower.', 'fr': "Affaiblissez le déclencheur avant d'éprouver votre volonté."}),
  DailyLine({'ar': 'الرغبة موجةٌ ترتفع ثم تنحسر، فاصبر عليها قليلاً.', 'en': 'An urge is a wave: it rises, then it passes. Ride it out.', 'fr': "L'envie est une vague : elle monte puis retombe. Tenez bon."}),
  DailyLine({'ar': 'سجّل يومك ولو كان متعثّراً، فالصدق أساس التغيير.', 'en': 'Log your day even if it went badly; honesty is the base of change.', 'fr': "Notez votre journée même difficile, l'honnêteté fonde le changement."}),
  DailyLine({'ar': 'قارن نفسك بنفسك بالأمس، لا بأحدٍ سواك.', 'en': 'Compare yourself to yesterday, not to anyone else.', 'fr': "Comparez-vous à vous-même hier, à personne d'autre."}),
  DailyLine({'ar': 'رتّب بيئتك، فهي تنوب عنك في نصف المعركة.', 'en': 'Arrange your environment; it fights half the battle for you.', 'fr': "Aménagez votre environnement, il livre la moitié du combat."}),
  DailyLine({'ar': 'يومٌ واحدٌ متقنٌ خيرٌ من أسبوعٍ متردّد.', 'en': 'One deliberate day beats a hesitant week.', 'fr': "Une journée décidée vaut mieux qu'une semaine hésitante."}),
  DailyLine({'ar': 'الاستمرار البطيء يهزم الحماس المتقطّع.', 'en': 'Slow consistency beats bursts of enthusiasm.', 'fr': "La régularité lente bat l'enthousiasme intermittent."}),
  DailyLine({'ar': 'إن عدت اليوم فأنت لم تخسر، إنما استأنفت.', 'en': 'Coming back today is not losing; it is resuming.', 'fr': "Revenir aujourd'hui n'est pas perdre, c'est reprendre."}),
  DailyLine({'ar': 'اكتب سببك ثم اقرأه حين تضعف.', 'en': 'Write down your reason, then read it when you weaken.', 'fr': "Écrivez votre raison, puis relisez-la dans les moments faibles."}),
];

const List<DailyLine> kDailyFaith = [
  DailyLine({'ar': 'استعن بالله على نفسك، فمن استعان به لم يخذله.', 'en': 'Seek God\'s help with yourself; He does not fail those who ask.', 'fr': "Demandez l'aide de Dieu, Il ne délaisse pas celui qui la demande."}),
  DailyLine({'ar': 'باب التوبة مفتوح، فلا تجعل ذنب الأمس عذر اليوم.', 'en': 'The door of repentance is open; do not let yesterday excuse today.', 'fr': "La porte du repentir est ouverte, qu'hier n'excuse pas aujourd'hui."}),
  DailyLine({'ar': 'اجعل لك ورداً يومياً ولو قلّ، فأحبّ العمل أدومه.', 'en': 'Keep a small daily portion; the most beloved deed is the steady one.', 'fr': "Gardez une portion quotidienne, même petite : l'acte constant est le plus aimé."}),
  DailyLine({'ar': 'حاسِب نفسك قبل النوم بسؤالٍ واحد: ماذا قدّمت اليوم؟', 'en': 'Before sleep, ask one question: what did I offer today?', 'fr': "Avant de dormir, posez une question : qu'ai-je offert aujourd'hui ?"}),
  DailyLine({'ar': 'الدعاء سلاحٌ لا يصدأ، فادعُ لنفسك بالثبات.', 'en': 'Supplication never rusts; ask for steadfastness.', 'fr': "L'invocation ne rouille jamais, demandez la fermeté."}),
  DailyLine({'ar': 'غضّ بصرك تسلم، فأول الطريق نظرة.', 'en': 'Lower your gaze and stay safe; it all starts with a look.', 'fr': "Baissez le regard : tout commence par un coup d'œil."}),
  DailyLine({'ar': 'اصحب من يذكّرك بالخير، فالرفقة نصف الطريق.', 'en': 'Keep company that reminds you of good; company is half the road.', 'fr': "Fréquentez qui vous rappelle le bien, la compagnie fait la moitié du chemin."}),
  DailyLine({'ar': 'إذا ثقلت عليك الطاعة فابدأ بأيسرها ولا تتركها.', 'en': 'If worship feels heavy, start with its easiest form and do not abandon it.', 'fr': "Si l'adoration pèse, commencez par la plus simple sans l'abandonner."}),
  DailyLine({'ar': 'اشكر على القليل يُبارك لك فيه ويزد.', 'en': 'Be grateful for little and it is blessed and increased.', 'fr': "Soyez reconnaissant du peu, il sera béni et accru."}),
  DailyLine({'ar': 'استغفر بلسانك وقلبك، فالاستغفار يفتح المغلق.', 'en': 'Seek forgiveness with tongue and heart; it opens what is shut.', 'fr': "Demandez pardon du cœur et de la langue, cela ouvre ce qui est fermé."}),
];

/// Today's line, chosen deterministically from [dayKey] (yyyy-MM-dd) so the
/// app agrees with itself offline and the text changes each morning. Faith
/// lines join the pool only when [showReligious] is true.
DailyLine dailyLineFor(String dayKey, {required bool showReligious}) {
  final pool = showReligious
      ? <DailyLine>[...kDailyGeneral, ...kDailyFaith]
      : kDailyGeneral;
  var h = 0;
  for (final c in dayKey.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return pool[h % pool.length];
}
