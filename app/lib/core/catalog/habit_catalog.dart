// Local mirror of the Supabase `habit_catalog` reference data, so onboarding
// works fully offline. Kept in sync with supabase/seed.sql.

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
  });

  String t(String locale) => title[locale] ?? title['ar'] ?? key;
  String d(String locale) => description[locale] ?? description['ar'] ?? '';
}

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
    title: {'ar': 'نتف الشعر (هوس النتف)', 'en': 'Hair pulling', 'fr': 'Arrachage de cheveux'},
    description: {'ar': 'متابعة بمنهج HRT العلمي', 'en': 'Tracked with the HRT method.', 'fr': 'Suivi avec la méthode HRT.'}),
  CatalogHabit(key: 'skin_picking', track: 'break', category: 'mind', icon: '🤚', templateKey: 'hrt_8week',
    title: {'ar': 'نتش الجلد', 'en': 'Skin picking', 'fr': 'Grattage de la peau'},
    description: {'ar': 'عادة جلدية متكررة نخفّفها بالتدريب', 'en': 'A repetitive skin habit.', 'fr': 'Une habitude cutanée répétitive.'}),
  CatalogHabit(key: 'phone_addiction', track: 'break', category: 'productivity', icon: '📱',
    title: {'ar': 'إدمان الموبايل', 'en': 'Phone addiction', 'fr': 'Addiction au téléphone'},
    description: {'ar': 'قلّل التصفّح اللاواعي واسترجع وقتك', 'en': 'Reclaim your time.', 'fr': 'Reprenez votre temps.'}),
  CatalogHabit(key: 'excessive_gaming', track: 'break', category: 'productivity', icon: '🎮',
    title: {'ar': 'الإفراط في الألعاب', 'en': 'Excessive gaming', 'fr': 'Jeux excessifs'},
    description: {'ar': 'توازن أفضل مع الألعاب', 'en': 'Find a healthier balance.', 'fr': 'Trouvez l\'équilibre.'}),
  CatalogHabit(key: 'procrastination', track: 'break', category: 'productivity', icon: '⏳',
    title: {'ar': 'التسويف والمماطلة', 'en': 'Procrastination', 'fr': 'Procrastination'},
    description: {'ar': 'ابدأ بدل ما تأجّل', 'en': 'Start instead of postponing.', 'fr': 'Commencez au lieu de reporter.'}),
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

  // ---------- BUILD ----------
  CatalogHabit(key: 'pray_on_time', track: 'build', category: 'worship', icon: '🕌', isIslamic: true, islamwebRef: 'https://www.islamweb.net/ar/fatwa/13619/',
    title: {'ar': 'المحافظة على الصلاة في وقتها', 'en': 'Pray on time', 'fr': 'Prier à l\'heure'},
    description: {'ar': 'عماد الدين حافظ على صلواتك الخمس', 'en': 'Keep the five prayers on time.', 'fr': 'Les cinq prières à l\'heure.'}),
  CatalogHabit(key: 'daily_quran', track: 'build', category: 'worship', icon: '📖', isIslamic: true,
    title: {'ar': 'وِرد القرآن اليومي', 'en': 'Daily Qur\'an', 'fr': 'Coran quotidien'},
    description: {'ar': 'اجعل لك وِرداً ثابتاً من كتاب الله', 'en': 'A steady daily portion.', 'fr': 'Une portion quotidienne.'}),
  CatalogHabit(key: 'adhkar', track: 'build', category: 'worship', icon: '📿', isIslamic: true,
    title: {'ar': 'أذكار الصباح والمساء', 'en': 'Morning & evening adhkar', 'fr': 'Adhkar matin et soir'},
    description: {'ar': 'حصّن يومك بالذكر', 'en': 'Fortify your day.', 'fr': 'Protégez votre journée.'}),
  CatalogHabit(key: 'voluntary_fasting', track: 'build', category: 'worship', icon: '🌙', isIslamic: true, islamwebRef: 'https://www.islamweb.net/ar/fatwa/50964/',
    title: {'ar': 'صيام النفل', 'en': 'Voluntary fasting', 'fr': 'Jeûne surérogatoire'},
    description: {'ar': 'الإثنين والخميس والأيام البيض', 'en': 'Mondays, Thursdays, white days.', 'fr': 'Lundi, jeudi, jours blancs.'}),
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
  CatalogHabit(key: 'drink_water', track: 'build', category: 'health', icon: '💧',
    title: {'ar': 'شرب الماء بانتظام', 'en': 'Drink water', 'fr': 'Boire de l\'eau'},
    description: {'ar': 'رطّب جسمك على مدار اليوم', 'en': 'Stay hydrated.', 'fr': 'Restez hydraté.'}),
  CatalogHabit(key: 'read_books', track: 'build', category: 'productivity', icon: '📚',
    title: {'ar': 'القراءة اليومية', 'en': 'Daily reading', 'fr': 'Lecture quotidienne'},
    description: {'ar': 'صفحات كل يوم تبني عقلك', 'en': 'A few pages every day.', 'fr': 'Quelques pages chaque jour.'}),
  CatalogHabit(key: 'sleep_early', track: 'build', category: 'health', icon: '🌃',
    title: {'ar': 'النوم مبكراً', 'en': 'Sleep early', 'fr': 'Dormir tôt'},
    description: {'ar': 'نوم مبكر = استيقاظ للفجر بنشاط', 'en': 'Early to bed, up for Fajr.', 'fr': 'Au lit tôt.'}),
  CatalogHabit(key: 'gratitude', track: 'build', category: 'mind', icon: '🤍', isIslamic: true,
    title: {'ar': 'الامتنان اليومي', 'en': 'Gratitude journal', 'fr': 'Journal de gratitude'},
    description: {'ar': 'اكتب نِعَمك كل يوم', 'en': 'Note your blessings.', 'fr': 'Notez vos bienfaits.'}),
  CatalogHabit(key: 'learn_skill', track: 'build', category: 'productivity', icon: '🧠',
    title: {'ar': 'تعلّم مهارة جديدة', 'en': 'Learn a new skill', 'fr': 'Apprendre une compétence'},
    description: {'ar': 'تقدّم بسيط كل يوم', 'en': 'A little progress daily.', 'fr': 'Un peu de progrès.'}),
  CatalogHabit(key: 'wake_fajr', track: 'build', category: 'worship', icon: '🌅', isIslamic: true,
    title: {'ar': 'الاستيقاظ للفجر', 'en': 'Wake up for Fajr', 'fr': 'Se lever pour Fajr'},
    description: {'ar': 'بركة يومك تبدأ من الفجر', 'en': 'Begin your day with Fajr.', 'fr': 'Commencez par Fajr.'}),
];

List<CatalogHabit> catalogForTrack(String track) =>
    kHabitCatalog.where((h) => h.track == track).toList();

CatalogHabit? catalogByKey(String key) {
  for (final h in kHabitCatalog) {
    if (h.key == key) return h;
  }
  return null;
}
