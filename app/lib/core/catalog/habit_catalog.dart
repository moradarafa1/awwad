// Local mirror of the Supabase `habit_catalog` reference data, so onboarding
// works fully offline. Kept in sync with supabase/seed.sql.

/// Recommended external help channel for the "secret habit" track: the واعي
/// YouTube channel (we suggest spending ~15 min/day there as part of recovery).
const String kWaaiUrl =
    'https://www.youtube.com/channel/UCubgpaK2N08IKa1biOQPL1Q';

/// An optional curated resource attached to a catalog habit, shown in the daily
/// log under the "solutions" section (e.g. a recommended video channel).
class HabitResource {
  final Map<String, String> title; // ar/en/fr
  final Map<String, String> body;
  final String url;
  const HabitResource(
      {required this.title, required this.body, required this.url});

  String t(String locale) => title[locale] ?? title['ar'] ?? '';
  String b(String locale) => body[locale] ?? body['ar'] ?? '';
}

/// One of the two daily measurement sliders. Its meaning changes per habit:
/// for a break habit the primary is "urge" and the secondary is "resistance",
/// but a build habit (e.g. prayer) measures different things (delay, sunnah...).
class HabitMetric {
  final Map<String, String> label;
  final Map<String, String> low; // left/low end caption
  final Map<String, String> high; // right/high end caption
  const HabitMetric({required this.label, required this.low, required this.high});

  String l(String loc) => label[loc] ?? label['ar'] ?? '';
  String lo(String loc) => low[loc] ?? low['ar'] ?? '';
  String hi(String loc) => high[loc] ?? high['ar'] ?? '';
}

/// The two daily sliders shown on the log screen for a habit.
class HabitMetrics {
  final HabitMetric primary; // stored in DailyEntry.urge
  final HabitMetric secondary; // stored in DailyEntry.resistance
  const HabitMetrics({required this.primary, required this.secondary});
}

class CatalogHabit {
  final String key;
  final String track; // 'break' | 'build'
  final String category;
  final Map<String, String> title; // ar/en/fr
  final Map<String, String> description;
  final String icon;
  final bool isIslamic;
  final String? islamwebRef;
  final String templateKey;
  final HabitResource? resource; // optional curated help (e.g. واعي channel)
  final HabitMetrics? metrics; // optional custom daily sliders (else track default)
  final List<int> defaultReminderHours; // suggested reminder times (e.g. water)

  const CatalogHabit({
    required this.key,
    required this.track,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.isIslamic = false,
    this.islamwebRef,
    this.templateKey = 'generic',
    this.resource,
    this.metrics,
    this.defaultReminderHours = const [],
  });

  String t(String locale) => title[locale] ?? title['ar'] ?? key;
  String d(String locale) => description[locale] ?? description['ar'] ?? '';
}

// Default daily sliders for the BREAK track (urge + resistance). Trilingual
// inline so both the log and the stats screens can resolve labels without l10n.
const HabitMetrics kBreakMetrics = HabitMetrics(
  primary: HabitMetric(
    label: {'ar': 'شدة الرغبة', 'en': 'Urge level', 'fr': "Niveau d'envie"},
    low: {'ar': 'لا رغبة', 'en': 'No urge', 'fr': 'Aucune envie'},
    high: {'ar': 'شديدة جداً', 'en': 'Very strong', 'fr': 'Très forte'},
  ),
  secondary: HabitMetric(
    label: {'ar': 'قوة المقاومة', 'en': 'Resistance', 'fr': 'Résistance'},
    low: {'ar': 'ضعيفة', 'en': 'Weak', 'fr': 'Faible'},
    high: {'ar': 'قوية جداً', 'en': 'Very strong', 'fr': 'Très forte'},
  ),
);

// Default daily sliders for the BUILD track (progress + quality).
const HabitMetrics kBuildMetrics = HabitMetrics(
  primary: HabitMetric(
    label: {'ar': 'مدى الإنجاز اليوم', 'en': "Today's progress", 'fr': 'Progrès du jour'},
    low: {'ar': 'لم أبدأ', 'en': 'Not started', 'fr': 'Pas commencé'},
    high: {'ar': 'أنجزته كاملاً', 'en': 'Fully done', 'fr': 'Terminé'},
  ),
  secondary: HabitMetric(
    label: {'ar': 'جودة الأداء', 'en': 'Quality', 'fr': 'Qualité'},
    low: {'ar': 'ضعيفة', 'en': 'Poor', 'fr': 'Faible'},
    high: {'ar': 'متقنة', 'en': 'Excellent', 'fr': 'Excellente'},
  ),
);

// Prayer-on-time: measures delay (instead of urge) and early-praying + sunnah
// (instead of resistance). Reused by other prayer-related build habits.
const HabitMetrics kPrayerMetrics = HabitMetrics(
  primary: HabitMetric(
    label: {'ar': 'تأخير الصلاة عن وقتها', 'en': 'Prayer delay', 'fr': 'Retard de la prière'},
    low: {'ar': 'في وقتها', 'en': 'On time', 'fr': "À l'heure"},
    high: {'ar': 'متأخرة جداً', 'en': 'Very late', 'fr': 'Très en retard'},
  ),
  secondary: HabitMetric(
    label: {'ar': 'التبكير والسنن', 'en': 'Early + sunnah', 'fr': 'Tôt + sunna'},
    low: {'ar': 'بدون سنن', 'en': 'None', 'fr': 'Aucune'},
    high: {'ar': 'بكّرت وصلّيت السنن', 'en': 'Early + sunnah done', 'fr': 'Tôt + sunna'},
  ),
);

// Water: cups + how evenly spread across the day (instead of progress/quality).
const HabitMetrics kWaterMetrics = HabitMetrics(
  primary: HabitMetric(
    label: {'ar': 'كمية الماء اليوم', 'en': "Today's water", 'fr': "Eau aujourd'hui"},
    low: {'ar': 'قليلة', 'en': 'Low', 'fr': 'Faible'},
    high: {'ar': 'كافية (٨ أكواب+)', 'en': 'Enough (8+ cups)', 'fr': 'Suffisant (8+ verres)'},
  ),
  secondary: HabitMetric(
    label: {'ar': 'الانتظام خلال اليوم', 'en': 'Spread over the day', 'fr': 'Réparti sur la journée'},
    low: {'ar': 'متقطّع', 'en': 'Irregular', 'fr': 'Irrégulier'},
    high: {'ar': 'منتظم', 'en': 'Steady', 'fr': 'Régulier'},
  ),
);

/// Resolve the two daily sliders for a habit: its own catalog metrics if any,
/// otherwise the track default (build vs break).
HabitMetrics metricsForHabit(String? catalogKey, String track) {
  final cat = catalogKey == null ? null : catalogByKey(catalogKey);
  if (cat?.metrics != null) return cat!.metrics!;
  return track == 'build' ? kBuildMetrics : kBreakMetrics;
}

/// Builds slider metrics from USER-TYPED labels (custom habits). The label is
/// shown as typed in every locale (it is the user's own wording); anchors are
/// generic low/high.
HabitMetrics customMetrics(String primary, String secondary) => HabitMetrics(
      primary: HabitMetric(
        label: {'ar': primary, 'en': primary, 'fr': primary},
        low: const {'ar': 'منخفض', 'en': 'Low', 'fr': 'Bas'},
        high: const {'ar': 'مرتفع', 'en': 'High', 'fr': 'Élevé'},
      ),
      secondary: HabitMetric(
        label: {'ar': secondary, 'en': secondary, 'fr': secondary},
        low: const {'ar': 'منخفض', 'en': 'Low', 'fr': 'Bas'},
        high: const {'ar': 'مرتفع', 'en': 'High', 'fr': 'Élevé'},
      ),
    );

/// FULL metric resolution for a habit instance, in priority order:
/// user-typed custom labels > generated per-habit override > catalog metrics
/// > track default. Pass kHabitMetricsOverrides[catalogKey] as
/// [generatedOverride] (kept as a parameter so this file stays independent of
/// the generated content file).
HabitMetrics resolveMetrics({
  String? catalogKey,
  required String track,
  String? customPrimary,
  String? customSecondary,
  HabitMetrics? generatedOverride,
}) {
  final p = customPrimary?.trim() ?? '';
  final s = customSecondary?.trim() ?? '';
  if (p.isNotEmpty && s.isNotEmpty) return customMetrics(p, s);
  return generatedOverride ?? metricsForHabit(catalogKey, track);
}

/// The واعي recommendation attached to the secret-habit track.
const HabitResource _waaiResource = HabitResource(
  url: kWaaiUrl,
  title: {
    'ar': 'حلٌّ مقترح: قناة واعي',
    'en': 'Suggested help: Waai channel',
    'fr': 'Aide suggérée : chaîne Waai',
  },
  body: {
    'ar':
        'عند اشتداد الرغبة، اقضِ نحو ١٥ دقيقة على قناة واعي على يوتيوب بدلاً من الاستسلام. محتوى توعويّ يعينك على الفهم والثبات.',
    'en':
        'When the urge hits, spend about 15 minutes on the Waai YouTube channel instead of giving in. Awareness content that helps you understand and stay firm.',
    'fr':
        "Quand l'envie surgit, passez environ 15 minutes sur la chaîne YouTube Waai au lieu de céder. Un contenu de sensibilisation qui aide à comprendre et à tenir.",
  },
);

const Map<String, String> _categoryNamesAr = {
  'health': 'الصحة',
  'mind': 'النفس والعقل',
  'productivity': 'الإنتاجية',
  'social': 'العلاقات',
  'worship': 'العبادات',
};
const Map<String, String> _categoryNamesEn = {
  'health': 'Health',
  'mind': 'Mind',
  'productivity': 'Productivity',
  'social': 'Relationships',
  'worship': 'Worship',
};
const Map<String, String> _categoryNamesFr = {
  'health': 'Santé',
  'mind': 'Esprit',
  'productivity': 'Productivité',
  'social': 'Relations',
  'worship': 'Adoration',
};

String categoryName(String category, String locale) {
  switch (locale) {
    case 'en':
      return _categoryNamesEn[category] ?? category;
    case 'fr':
      return _categoryNamesFr[category] ?? category;
    default:
      return _categoryNamesAr[category] ?? category;
  }
}

const List<CatalogHabit> kHabitCatalog = [
  // ---------- BREAK ----------
  CatalogHabit(key: 'quit_smoking', track: 'break', category: 'health', icon: '🚭', templateKey: 'hrt_8week', islamwebRef: 'https://www.islamweb.net/ar/fatwa/4257/',
    title: {'ar': 'الإقلاع عن التدخين', 'en': 'Quit smoking', 'fr': 'Arrêter de fumer'},
    description: {'ar': 'تحرّر من السجائر خطوة بخطوة', 'en': 'Break free from cigarettes.', 'fr': 'Libérez-vous de la cigarette.'}),
  CatalogHabit(key: 'quit_vaping', track: 'break', category: 'health', icon: '💨', templateKey: 'hrt_8week',
    title: {'ar': 'ترك الفيب', 'en': 'Quit vaping', 'fr': 'Arrêter la vape'},
    description: {'ar': 'توقّف عن التدخين الإلكتروني', 'en': 'Stop e-cigarettes.', 'fr': 'Arrêtez l\'e-cigarette.'}),
  CatalogHabit(key: 'nail_biting', track: 'break', category: 'mind', icon: '💅', templateKey: 'hrt_8week',
    title: {'ar': 'قضم الأظافر', 'en': 'Nail biting', 'fr': 'Rongement des ongles'},
    description: {'ar': 'عادة عصبية شائعة نتعامل معها بوعي', 'en': 'A common nervous habit.', 'fr': 'Une habitude nerveuse courante.'}),
  CatalogHabit(key: 'hair_pulling', track: 'break', category: 'mind', icon: '💇', templateKey: 'hrt_8week',
    title: {'ar': 'متلازمة نتف الشعر', 'en': 'Hair pulling (Trichotillomania)', 'fr': 'Trichotillomanie (arrachage des cheveux)'},
    description: {'ar': 'متابعة بمنهج HRT العلمي', 'en': 'Tracked with the HRT method.', 'fr': 'Suivi avec la méthode HRT.'}),
  CatalogHabit(key: 'skin_picking', track: 'break', category: 'mind', icon: '🤚', templateKey: 'hrt_8week',
    title: {'ar': 'نتش الجلد', 'en': 'Skin picking', 'fr': 'Grattage de la peau'},
    description: {'ar': 'عادة جلدية متكررة نخفّفها بالتدريب', 'en': 'A repetitive skin habit.', 'fr': 'Une habitude cutanée répétitive.'}),
  CatalogHabit(key: 'secret_habit', track: 'break', category: 'mind', icon: '🔒', templateKey: 'hrt_8week', isIslamic: true, resource: _waaiResource,
    title: {'ar': 'العادة السرية', 'en': 'Compulsive masturbation', 'fr': 'Masturbation compulsive'},
    description: {'ar': 'تحرّر بثبات وستر، بمنهج علمي وروح داعمة', 'en': 'Break free with discretion and support.', 'fr': 'Libérez-vous avec discrétion et soutien.'}),
  CatalogHabit(key: 'phone_addiction', track: 'break', category: 'productivity', icon: '📱',
    title: {'ar': 'إدمان الهاتف', 'en': 'Phone addiction', 'fr': 'Addiction au téléphone'},
    description: {'ar': 'قلّل التصفّح اللاواعي واسترجع وقتك', 'en': 'Reclaim your time.', 'fr': 'Reprenez votre temps.'}),
  CatalogHabit(key: 'excessive_gaming', track: 'break', category: 'productivity', icon: '🎮',
    title: {'ar': 'الإفراط في الألعاب', 'en': 'Excessive gaming', 'fr': 'Jeux excessifs'},
    description: {'ar': 'توازن أفضل مع الألعاب', 'en': 'Find a healthier balance.', 'fr': 'Trouvez l\'équilibre.'}),
  CatalogHabit(key: 'procrastination', track: 'break', category: 'productivity', icon: '⏳',
    title: {'ar': 'التسويف والمماطلة', 'en': 'Procrastination', 'fr': 'Procrastination'},
    description: {'ar': 'ابدأ بدلاً من التأجيل', 'en': 'Start instead of postponing.', 'fr': 'Commencez au lieu de reporter.'}),
  CatalogHabit(key: 'junk_food', track: 'break', category: 'health', icon: '🍔',
    title: {'ar': 'الأكل غير الصحي', 'en': 'Junk food', 'fr': 'Malbouffe'},
    description: {'ar': 'قلّل السكر والوجبات السريعة', 'en': 'Cut sugar and fast food.', 'fr': 'Réduisez le sucre.'}),
  CatalogHabit(key: 'oversleeping', track: 'break', category: 'health', icon: '😴',
    title: {'ar': 'كثرة النوم', 'en': 'Oversleeping', 'fr': 'Trop dormir'},
    description: {'ar': 'نظّم نومك واستيقظ بنشاط', 'en': 'Regulate your sleep.', 'fr': 'Régulez votre sommeil.'}),
  CatalogHabit(key: 'gossip', track: 'break', category: 'social', icon: '🤐', isIslamic: true, islamwebRef: 'https://www.islamweb.net/ar/fatwa/1531/',
    title: {'ar': 'الغيبة والنميمة', 'en': 'Gossip & backbiting', 'fr': 'Médisance'},
    description: {'ar': 'احفظ لسانك خير لك في دينك ودنياك', 'en': 'Guard your tongue.', 'fr': 'Préservez votre langue.'}),
  CatalogHabit(key: 'bad_language', track: 'break', category: 'social', icon: '🗯️', isIslamic: true,
    title: {'ar': 'الألفاظ السيّئة', 'en': 'Bad language', 'fr': 'Langage grossier'},
    description: {'ar': 'كلام طيّب وأخلاق أحسن', 'en': 'Cleaner, kinder speech.', 'fr': 'Un langage plus doux.'}),
  CatalogHabit(key: 'impulse_buying', track: 'break', category: 'productivity', icon: '🛍️',
    title: {'ar': 'الشراء الاندفاعي', 'en': 'Impulse buying', 'fr': 'Achats impulsifs'},
    description: {'ar': 'قرارات إنفاق أوعى', 'en': 'Smarter spending.', 'fr': 'Des dépenses réfléchies.'}),
  CatalogHabit(key: 'caffeine_excess', track: 'break', category: 'health', icon: '☕',
    title: {'ar': 'الإفراط في الكافيين', 'en': 'Too much caffeine', 'fr': 'Excès de caféine'},
    description: {'ar': 'قلّل القهوة ومشروبات الطاقة', 'en': 'Cut back on caffeine.', 'fr': 'Réduisez la caféine.'}),
  CatalogHabit(key: 'late_nights', track: 'break', category: 'health', icon: '🌙', templateKey: 'hrt_8week',
    title: {'ar': "السهر المتأخر", 'en': "Staying up late", 'fr': "Veiller tard"},
    description: {'ar': "تخلّص من عادة السهر المتأخر الذي يسرق نومك وصلاة فجرك ونشاط نهارك، ونظّم وقت نومك.", 'en': "Break the habit of staying up late, which steals your sleep, your Fajr prayer, and your daytime energy. Regulate your bedtime.", 'fr': "Rompez avec l'habitude de veiller tard, qui vous prive de sommeil, de la prière de Fajr et de votre énergie. Régulez l'heure du coucher."}),
  CatalogHabit(key: 'binge_watching', track: 'break', category: 'productivity', icon: '📺', templateKey: 'hrt_8week',
    title: {'ar': "الإفراط في المشاهدة", 'en': "Binge-watching", 'fr': "Visionnage excessif"},
    description: {'ar': "قلّل ساعات مشاهدة المسلسلات والمقاطع القصيرة المتواصلة التي تسرق وقتك وتركيزك، واسترجع ساعاتك لما ينفعك.", 'en': "Cut back on hours of nonstop series and short clips that steal your time and focus, and reclaim your hours for what benefits you.", 'fr': "Réduisez les heures de séries et de clips courts ininterrompus qui volent votre temps et votre concentration, et récupérez vos heures pour ce qui est utile."}),
  CatalogHabit(key: 'anger', track: 'break', category: 'mind', icon: '😤', templateKey: 'hrt_8week', isIslamic: true,
    title: {'ar': "الغضب وسرعة الانفعال", 'en': "Anger & quick temper", 'fr': "Colère et emportement"},
    description: {'ar': "تعلّم ضبط غضبك وكظم غيظك في المواقف الصعبة، فالقوي من يملك نفسه عند الغضب، واحفظ علاقاتك وصحتك.", 'en': "Learn to control your anger and restrain it in difficult moments. The strong one is who masters himself when angry, protecting your relationships and health.", 'fr': "Apprenez à maîtriser votre colère et à la contenir dans les moments difficiles. Le fort est celui qui se domine quand il est en colère, préservant ses relations et sa santé."}),

  // ---------- BUILD ----------
  CatalogHabit(key: 'pray_on_time', track: 'build', category: 'worship', icon: '🕌', isIslamic: true, islamwebRef: 'https://www.islamweb.net/ar/fatwa/13619/', metrics: kPrayerMetrics,
    title: {'ar': 'المحافظة على الصلاة في وقتها', 'en': 'Pray on time', 'fr': 'Prier à l\'heure'},
    description: {'ar': 'عماد الدين حافظ على صلواتك الخمس', 'en': 'Keep the five prayers on time.', 'fr': 'Les cinq prières à l\'heure.'}),
  CatalogHabit(key: 'daily_quran', track: 'build', category: 'worship', icon: '📖', isIslamic: true,
    title: {'ar': 'وِرد القرآن اليومي', 'en': 'Daily Qur\'an', 'fr': 'Coran quotidien'},
    description: {'ar': 'اجعل لك وِرداً ثابتاً من كتاب الله', 'en': 'A steady daily portion.', 'fr': 'Une portion quotidienne.'}),
  CatalogHabit(key: 'adhkar', track: 'build', category: 'worship', icon: '📿', isIslamic: true, defaultReminderHours: [6, 17],
    title: {'ar': 'أذكار الصباح والمساء', 'en': 'Morning & evening adhkar', 'fr': 'Adhkar matin et soir'},
    description: {'ar': 'حصّن يومك بالذكر', 'en': 'Fortify your day.', 'fr': 'Protégez votre journée.'}),
  CatalogHabit(key: 'voluntary_fasting', track: 'build', category: 'worship', icon: '🌙', isIslamic: true, islamwebRef: 'https://www.islamweb.net/ar/fatwa/50964/',
    title: {'ar': 'صيام النوافل', 'en': 'Voluntary fasting', 'fr': 'Jeûne surérogatoire'},
    description: {'ar': 'الاثنين والخميس والأيام البيض', 'en': 'Mondays, Thursdays, white days.', 'fr': 'Lundi, jeudi, jours blancs.'}),
  CatalogHabit(key: 'qiyam', track: 'build', category: 'worship', icon: '🌌', isIslamic: true,
    title: {'ar': 'قيام الليل', 'en': 'Night prayer (Qiyam)', 'fr': 'Prière de nuit'},
    description: {'ar': 'شرف المؤمن قيامه بالليل', 'en': 'The honor of the believer.', 'fr': 'L\'honneur du croyant.'}),
  CatalogHabit(key: 'keeping_ties', track: 'build', category: 'social', icon: '🤝', isIslamic: true,
    title: {'ar': 'صلة الرحم', 'en': 'Keeping family ties', 'fr': 'Liens familiaux'},
    description: {'ar': 'تواصل مع أهلك وقرابتك', 'en': 'Stay connected with kin.', 'fr': 'Restez en lien.'}),
  CatalogHabit(key: 'daily_charity', track: 'build', category: 'worship', icon: '💝', isIslamic: true,
    title: {'ar': 'صدقة يومية', 'en': 'Daily charity', 'fr': 'Aumône quotidienne'},
    description: {'ar': 'ولو بالقليل الصدقة تطفئ الخطيئة', 'en': 'Even a little, every day.', 'fr': 'Même peu, chaque jour.'}),
  CatalogHabit(key: 'istighfar', track: 'build', category: 'worship', icon: '🤲', isIslamic: true,
    title: {'ar': 'الاستغفار اليومي', 'en': 'Daily istighfar', 'fr': 'Istighfar quotidien'},
    description: {'ar': 'عوّد لسانك على الاستغفار', 'en': 'Keep your tongue in istighfar.', 'fr': 'Habituez votre langue.'}),
  CatalogHabit(key: 'exercise', track: 'build', category: 'health', icon: '🏃',
    title: {'ar': 'ممارسة الرياضة', 'en': 'Exercise', 'fr': 'Faire du sport'},
    description: {'ar': 'حرّك جسمك كل يوم', 'en': 'Move your body daily.', 'fr': 'Bougez chaque jour.'}),
  CatalogHabit(key: 'drink_water', track: 'build', category: 'health', icon: '💧', defaultReminderHours: [9, 12, 15, 18, 21], metrics: kWaterMetrics,
    title: {'ar': 'شرب الماء بانتظام', 'en': 'Drink water', 'fr': 'Boire de l\'eau'},
    description: {'ar': 'رطّب جسمك على مدار اليوم', 'en': 'Stay hydrated.', 'fr': 'Restez hydraté.'}),
  CatalogHabit(key: 'read_books', track: 'build', category: 'productivity', icon: '📚',
    title: {'ar': 'القراءة اليومية', 'en': 'Daily reading', 'fr': 'Lecture quotidienne'},
    description: {'ar': 'صفحات كل يوم تبني عقلك', 'en': 'A few pages every day.', 'fr': 'Quelques pages chaque jour.'}),
  CatalogHabit(key: 'sleep_early', track: 'build', category: 'health', icon: '🌃',
    title: {'ar': 'النوم مبكراً', 'en': 'Sleep early', 'fr': 'Dormir tôt'},
    description: {'ar': 'نوم مبكر = استيقاظ للفجر بنشاط', 'en': 'Early to bed, up for Fajr.', 'fr': 'Au lit tôt.'}),
  CatalogHabit(key: 'gratitude', track: 'build', category: 'mind', icon: '🤍', isIslamic: true,
    title: {'ar': 'الحمد والشكر', 'en': 'Praise & gratitude', 'fr': 'Louange et gratitude'},
    description: {'ar': 'احمد الله على نِعَمه واشكره كل يوم', 'en': 'Praise Allah for His blessings and thank Him daily.', 'fr': 'Louez Dieu pour Ses bienfaits et remerciez-Le chaque jour.'}),
  CatalogHabit(key: 'learn_skill', track: 'build', category: 'productivity', icon: '🧠',
    title: {'ar': 'تعلّم مهارة جديدة', 'en': 'Learn a new skill', 'fr': 'Apprendre une compétence'},
    description: {'ar': 'تقدّم بسيط كل يوم', 'en': 'A little progress daily.', 'fr': 'Un peu de progrès.'}),
  CatalogHabit(key: 'wake_fajr', track: 'build', category: 'worship', icon: '🌅', isIslamic: true, metrics: kPrayerMetrics, defaultReminderHours: [4, 21],
    title: {'ar': 'الاستيقاظ للفجر', 'en': 'Wake up for Fajr', 'fr': 'Se lever pour Fajr'},
    description: {'ar': 'بركة يومك تبدأ من الفجر', 'en': 'Begin your day with Fajr.', 'fr': 'Commencez par Fajr.'}),
  CatalogHabit(key: 'salawat', track: 'build', category: 'worship', icon: '🌹', templateKey: 'generic', isIslamic: true,
    title: {'ar': "الصلاة على النبي", 'en': "Salawat on the Prophet", 'fr': "Salawat sur le Prophète"},
    description: {'ar': "أكثِر من الصلاة على النبي صلى الله عليه وسلم، فهي نورٌ لقلبك وسببٌ لرفعة درجاتك، وأكثِر منها يوم الجمعة.", 'en': "Send abundant blessings upon the Prophet, peace be upon him. It brings light to your heart and raises your rank, especially on Fridays.", 'fr': "Multipliez les prières sur le Prophète, paix sur lui. Elles illuminent le cœur et élèvent les rangs, surtout le vendredi."}),
  CatalogHabit(key: 'honor_parents', track: 'build', category: 'social', icon: '👵', templateKey: 'generic', isIslamic: true,
    title: {'ar': "بر الوالدين", 'en': "Honoring your parents", 'fr': "Honorer ses parents"},
    description: {'ar': "أحسِن إلى والديك كل يوم بكلمة طيبة أو خدمة أو دعاء، فرضاهما من رضا الله، وبرّهما باب من أبواب الجنة.", 'en': "Be good to your parents every day with a kind word, a service, or a prayer. Their pleasure is from God's pleasure, and honoring them is a gate to Paradise.", 'fr': "Soyez bon envers vos parents chaque jour par une parole douce, un service ou une prière. Leur satisfaction relève de celle de Dieu, et les honorer est une porte du Paradis."}),
  CatalogHabit(key: 'dua', track: 'build', category: 'worship', icon: '🤍', templateKey: 'generic', isIslamic: true,
    title: {'ar': "الدعاء اليومي", 'en': "Daily supplication", 'fr': "Invocation quotidienne"},
    description: {'ar': "اجعل لك نصيباً ثابتاً من الدعاء كل يوم، وارفع حاجاتك إلى الله بقلب موقن بالإجابة، فالدعاء مفتاح كل خير.", 'en': "Set aside a steady portion of supplication each day, raising your needs to God with a heart certain of an answer. Supplication is the key to every good.", 'fr': "Réservez chaque jour un moment d'invocation, en présentant vos besoins à Dieu avec un cœur convaincu de la réponse. L'invocation est la clé de tout bien."}),
  // Weekly build habit: reminder is scheduled Friday at dhuhr+1h by the prayer
  // engine, not the daily reminder path (see notif scheduleWeekly / kahf wiring).
  CatalogHabit(key: 'surah_kahf', track: 'build', category: 'worship', icon: '📖', templateKey: 'generic', isIslamic: true,
    islamwebRef: 'https://www.islamweb.net/ar/fatwa/21395/',
    title: {'ar': "قراءة سورة الكهف", 'en': "Reading Surah Al-Kahf", 'fr': "Lecture de sourate Al-Kahf"},
    description: {'ar': "اقرأ سورة الكهف كل جمعة، فمن قرأها أضاء له من النور ما بين الجمعتين. اجعلها موعداً ثابتاً بعد صلاة الجمعة.", 'en': "Read Surah Al-Kahf every Friday; whoever reads it is granted light between the two Fridays. Make it a fixed appointment after Jumu'ah.", 'fr': "Lisez la sourate Al-Kahf chaque vendredi; celui qui la lit reçoit une lumière entre les deux vendredis. Fixez ce rendez-vous après la prière du vendredi."}),
  // Distinct from secret_habit: opens the DNS content shield immediately on
  // selection (see add_habit / onboarding _onPick hook).
  CatalogHabit(key: 'break_porn', track: 'break', category: 'mind', icon: '🛡️', templateKey: 'hrt_8week', isIslamic: true, resource: _waaiResource,
    islamwebRef: 'https://www.islamweb.net/ar/fatwa/125402/',
    title: {'ar': "كسر إدمان الإباحية", 'en': "Break porn addiction", 'fr': "Briser l'addiction au porno"},
    description: {'ar': "طريق التعافي يبدأ بصدق التوبة وقطع الطريق على المحرَّم. فعّل حاجب المحتوى، واملأ فراغك بالخير، واستعن بالله ثم بمن تثق به.", 'en': "Recovery starts with sincere repentance and cutting off access. Turn on the content shield, fill your time with good, and lean on God then a trusted companion.", 'fr': "La guérison commence par un repentir sincère et la coupure de l'accès. Activez le filtre de contenu, occupez votre temps par le bien, et appuyez-vous sur Dieu puis sur une personne de confiance."}),
  // Quran listening wird: opens an in-app audio player (50 reciters) from the
  // daily log resource card. Build habit (a daily good deed).
  CatalogHabit(key: 'listening_wird', track: 'build', category: 'worship', icon: '🎧', templateKey: 'generic', isIslamic: true,
    islamwebRef: 'https://www.islamweb.net/ar/fatwa/13782/',
    title: {'ar': "ورد الاستماع للقرآن", 'en': "Quran listening wird", 'fr': "Wird d'écoute du Coran"},
    description: {'ar': "اجعل لك وِرداً يومياً تستمع فيه إلى القرآن بصوت قارئك المفضّل، فللاستماع للقرآن سكينةٌ للقلب ورحمة. اختر السورة وعدد ما تسمع.", 'en': "Set a daily wird of listening to the Quran in your favourite reciter's voice; listening brings calm and mercy to the heart. Pick a surah and how much to hear.", 'fr': "Fixez un wird quotidien d'écoute du Coran par votre récitateur préféré; l'écoute apporte sérénité et miséricorde au cœur."}),
];

List<CatalogHabit> catalogForTrack(String track) =>
    kHabitCatalog.where((h) => h.track == track).toList();

CatalogHabit? catalogByKey(String key) {
  for (final h in kHabitCatalog) {
    if (h.key == key) return h;
  }
  return null;
}
