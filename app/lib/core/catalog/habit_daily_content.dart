// GENERATED daily-log content overlays. DO NOT EDIT BY HAND.
// Regenerate with scratchpad/assemble_daily_content.mjs (see PROJECT_STATE).
// - kHabitVideos: CURATED + VERIFIED scholar videos (<30 min) per habit.
//   The suggested-video card exists ONLY for habits present here (owner rule).
// - kHabitQuestions: per-habit wording of the daily did-you-do-it question.
// - kHabitMetricsOverrides: per-habit sliders that beat the track defaults.
// - kExtraCompeting/kExtraEnvironment: generated checklists for habits not
//   covered by kHabitChecklists (mainly BUILD habits).

import 'habit_catalog.dart' show HabitMetric, HabitMetrics;

class ScholarVideo {
  final String id; // YouTube video id
  final String title;
  final String scholar;
  final int seconds; // verified < 1800
  const ScholarVideo(
      {required this.id,
      required this.title,
      required this.scholar,
      required this.seconds});

  String get url => 'https://www.youtube.com/watch?v=$id';
  int get minutes => (seconds / 60).round();
}

const Map<String, List<ScholarVideo>> kHabitVideos = {
  'secret_habit': [
    ScholarVideo(id: '-MBzN7N5FUk', title: 'خطوات ذهبية لعلاج إدمان الإباحية والعادة السرية 100%', scholar: 'قناة واعي', seconds: 761),
    ScholarVideo(id: '46q4vjTuKIY', title: 'نصائح ذهبية لترك الإباحية والعادة السرية', scholar: 'قناة واعي', seconds: 230),
  ],
  'gossip': [
    ScholarVideo(id: 'YyMNUWdwXCY', title: 'علاج الغيبة والنميمة ؟ للشيخ مصطفي العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 118),
  ],
  'pray_on_time': [
    ScholarVideo(id: '2YBNEwB3a7M', title: 'صحة حديث : الصلاة لأول وقتها | الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 105),
  ],
  'adhkar': [
    ScholarVideo(id: 'GszetJqbyZQ', title: 'هل ورد عن النبي ﷺ أنه كان يقرأ أذكار الصباح والمساء كاملة بنفس الترتيب؟ الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 363),
    ScholarVideo(id: 'kFn_3_aMOnc', title: 'كتاب ووقت أذكار الصباح والمساء ؟ للشيخ مصطفي العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 62),
  ],
  'keeping_ties': [
    ScholarVideo(id: '6M4-mzXHz8M', title: 'صلة الأرحام - معراج الروح - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 1184),
    ScholarVideo(id: 'EsgRroD5eI0', title: 'الرحم معلقة بالعرش: من وصلني وصله الله ومن قطعني قطعه الله - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 313),
  ],
  'daily_charity': [
    ScholarVideo(id: 'WGo79srmiQo', title: 'ما نقصت صدقة من مال - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 442),
    ScholarVideo(id: '0mQf3K9ayY8', title: 'أفضل الصدقة صدقة الصحيح الشحيح - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 459),
  ],
  'istighfar': [
    ScholarVideo(id: 'r21k3cL69gU', title: 'الاستغفار والمداومة عليه - معراج الروح - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 1232),
    ScholarVideo(id: '49aKz8DBms0', title: 'الاستغفار والحث عليه - الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 999),
  ],
  'gratitude': [
    ScholarVideo(id: 'P5_WFOIOKcU', title: 'نعمة الظل | الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 92),
  ],
  'honor_parents': [
    ScholarVideo(id: 'VtE1H5x0l78', title: 'هل بر الوالدين أفضل من الجهاد في سبيل الله؟ | الشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 175),
  ],
  'dua': [
    ScholarVideo(id: 'MCf-VVnkKxQ', title: 'فقه الدعاء (1) للشيخ مصطفى العدوي', scholar: 'الشيخ مصطفى العدوي', seconds: 640),
  ],
};

const Map<String, Map<String, String>> kHabitQuestions = {
  'quit_smoking': {'ar': 'هل دخّنت اليوم؟', 'en': 'Did you smoke today?', 'fr': 'Avez-vous fumé aujourd\'hui ?'},
  'quit_vaping': {'ar': 'هل استخدمت الفيب اليوم؟', 'en': 'Did you vape today?', 'fr': 'Avez-vous vapoté aujourd\'hui ?'},
  'nail_biting': {'ar': 'هل قضمت أظافرك اليوم؟', 'en': 'Did you bite your nails today?', 'fr': 'Vous êtes-vous rongé les ongles aujourd\'hui ?'},
  'hair_pulling': {'ar': 'هل نتفت شعرك اليوم؟', 'en': 'Did you pull your hair today?', 'fr': 'Vous êtes-vous arraché les cheveux aujourd\'hui ?'},
  'skin_picking': {'ar': 'هل نتشت جلدك اليوم؟', 'en': 'Did you pick at your skin today?', 'fr': 'Vous êtes-vous gratté la peau aujourd\'hui ?'},
  'secret_habit': {'ar': 'هل وقعت في العادة اليوم؟', 'en': 'Did you fall into the habit today?', 'fr': 'Êtes-vous retombé dans l\'habitude aujourd\'hui ?'},
  'phone_addiction': {'ar': 'هل ضاع وقتك في التصفح اليوم؟', 'en': 'Did you waste your time scrolling today?', 'fr': 'Avez-vous perdu votre temps à naviguer sans but aujourd\'hui ?'},
  'excessive_gaming': {'ar': 'هل تجاوزت وقت اللعب المسموح اليوم؟', 'en': 'Did you exceed your gaming limit today?', 'fr': 'Avez-vous dépassé votre limite de jeu aujourd\'hui ?'},
  'procrastination': {'ar': 'هل سوّفت مهامك اليوم؟', 'en': 'Did you procrastinate on your tasks today?', 'fr': 'Avez-vous procrastiné sur vos tâches aujourd\'hui ?'},
  'junk_food': {'ar': 'هل أكلت وجبة غير صحية اليوم؟', 'en': 'Did you eat junk food today?', 'fr': 'Avez-vous mangé de la malbouffe aujourd\'hui ?'},
  'oversleeping': {'ar': 'هل نمت أكثر من حاجتك اليوم؟', 'en': 'Did you sleep more than you needed today?', 'fr': 'Avez-vous dormi plus que nécessaire aujourd\'hui ?'},
  'gossip': {'ar': 'هل اغتبت أحداً اليوم؟', 'en': 'Did you backbite anyone today?', 'fr': 'Avez-vous médit de quelqu\'un aujourd\'hui ?'},
  'bad_language': {'ar': 'هل نطقت بلفظ سيئ اليوم؟', 'en': 'Did you use bad language today?', 'fr': 'Avez-vous dit une grossièreté aujourd\'hui ?'},
  'impulse_buying': {'ar': 'هل اشتريت شيئاً بلا تخطيط اليوم؟', 'en': 'Did you buy anything unplanned today?', 'fr': 'Avez-vous fait un achat imprévu aujourd\'hui ?'},
  'caffeine_excess': {'ar': 'هل تجاوزت حدك من الكافيين اليوم؟', 'en': 'Did you exceed your caffeine limit today?', 'fr': 'Avez-vous dépassé votre limite de caféine aujourd\'hui ?'},
  'late_nights': {'ar': 'هل سهرت متأخراً الليلة الماضية؟', 'en': 'Did you stay up late last night?', 'fr': 'Avez-vous veillé tard la nuit dernière ?'},
  'binge_watching': {'ar': 'هل أفرطت في المشاهدة اليوم؟', 'en': 'Did you binge-watch today?', 'fr': 'Avez-vous enchaîné les épisodes aujourd\'hui ?'},
  'anger': {'ar': 'هل انفجرت غضباً اليوم؟', 'en': 'Did you lose your temper today?', 'fr': 'Avez-vous explosé de colère aujourd\'hui ?'},
  'pray_on_time': {'ar': 'هل صلّيت الفرائض الخمس في وقتها اليوم؟', 'en': 'Did you pray all five prayers on time today?', 'fr': 'Avez-vous accompli les cinq prières à l\'heure aujourd\'hui ?'},
  'wake_fajr': {'ar': 'هل استيقظت وصلّيت الفجر في وقته اليوم؟', 'en': 'Did you wake up and pray Fajr on time today?', 'fr': 'Vous êtes-vous levé pour prier le Fajr à l\'heure aujourd\'hui ?'},
  'daily_quran': {'ar': 'هل قرأت وِردك من القرآن اليوم؟', 'en': 'Did you read your Qur\'an portion today?', 'fr': 'Avez-vous lu votre portion du Coran aujourd\'hui ?'},
  'adhkar': {'ar': 'هل حصّنت يومك بأذكار الصباح والمساء؟', 'en': 'Did you fortify your day with the morning and evening adhkar?', 'fr': 'Avez-vous protégé votre journée par les adhkar du matin et du soir ?'},
  'voluntary_fasting': {'ar': 'هل التزمت بخطة صيامك لهذا اليوم؟', 'en': 'Did you keep to your fasting plan for today?', 'fr': 'Avez-vous respecté votre programme de jeûne pour aujourd\'hui ?'},
  'qiyam': {'ar': 'هل قمت الليلة الماضية ولو بركعتين؟', 'en': 'Did you pray qiyam last night, even two rak\'ahs?', 'fr': 'Avez-vous prié la nuit dernière, ne serait-ce que deux rak\'ahs ?'},
  'keeping_ties': {'ar': 'هل وصلت اليوم أحداً من أرحامك؟', 'en': 'Did you connect with a relative today?', 'fr': 'Avez-vous contacté un proche parent aujourd\'hui ?'},
  'daily_charity': {'ar': 'هل تصدقت اليوم ولو بالقليل؟', 'en': 'Did you give charity today, even a little?', 'fr': 'Avez-vous donné une aumône aujourd\'hui, même modeste ?'},
  'istighfar': {'ar': 'هل حافظت على ورد الاستغفار اليوم؟', 'en': 'Did you keep up your istighfar today?', 'fr': 'Avez-vous maintenu votre istighfar aujourd\'hui ?'},
  'exercise': {'ar': 'هل مارست الرياضة اليوم؟', 'en': 'Did you exercise today?', 'fr': 'Avez-vous fait du sport aujourd\'hui ?'},
  'drink_water': {'ar': 'هل شربت ماءً كافياً اليوم؟', 'en': 'Did you drink enough water today?', 'fr': 'Avez-vous bu assez d\'eau aujourd\'hui ?'},
  'read_books': {'ar': 'هل قرأت اليوم؟', 'en': 'Did you read today?', 'fr': 'Avez-vous lu aujourd\'hui ?'},
  'sleep_early': {'ar': 'هل نمت مبكراً الليلة الماضية؟', 'en': 'Did you go to bed early last night?', 'fr': 'Vous êtes-vous couché tôt hier soir ?'},
  'gratitude': {'ar': 'هل حمدت الله على نعمه اليوم؟', 'en': 'Did you praise Allah for His blessings today?', 'fr': 'Avez-vous loué Dieu pour Ses bienfaits aujourd\'hui ?'},
  'learn_skill': {'ar': 'هل تقدّمت في مهارتك اليوم؟', 'en': 'Did you make progress on your skill today?', 'fr': 'Avez-vous progressé dans votre compétence aujourd\'hui ?'},
  'salawat': {'ar': 'هل صلّيت على النبي اليوم؟', 'en': 'Did you send salawat on the Prophet today?', 'fr': 'Avez-vous prié sur le Prophète aujourd\'hui ?'},
  'honor_parents': {'ar': 'هل بررت والديك اليوم؟', 'en': 'Did you honor your parents today?', 'fr': 'Avez-vous honoré vos parents aujourd\'hui ?'},
  'dua': {'ar': 'هل دعوت الله بحاجتك اليوم؟', 'en': 'Did you raise your needs to Allah today?', 'fr': 'Avez-vous présenté vos besoins à Dieu aujourd\'hui ?'},
};

const Map<String, HabitMetrics> kHabitMetricsOverrides = {
  'quit_smoking': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'عدد السجائر اليوم', 'en': 'Cigarettes today', 'fr': 'Cigarettes aujourd\'hui'}, low: {'ar': 'لا شيء', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'عشر فأكثر', 'en': 'Ten or more', 'fr': 'Dix ou plus'}),
    secondary: HabitMetric(label: {'ar': 'الصمود أمام الرغبة', 'en': 'Craving control', 'fr': 'Contrôle des envies'}, low: {'ar': 'استسلمت سريعاً', 'en': 'Gave in fast', 'fr': 'Cédé vite'}, high: {'ar': 'تجاوزتها كلها', 'en': 'Beat them all', 'fr': 'Toutes surmontées'}),
  ),
  'quit_vaping': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'استخدام الفيب اليوم', 'en': 'Vape use today', 'fr': 'Vapotage aujourd\'hui'}, low: {'ar': 'لم أستخدمه', 'en': 'Not at all', 'fr': 'Pas du tout'}, high: {'ar': 'استخدام كثير', 'en': 'Heavy use', 'fr': 'Usage intensif'}),
    secondary: HabitMetric(label: {'ar': 'الاستعانة بالبدائل', 'en': 'Using substitutes', 'fr': 'Recours aux substituts'}, low: {'ar': 'أبداً', 'en': 'Never', 'fr': 'Jamais'}, high: {'ar': 'عند كل رغبة', 'en': 'Every urge', 'fr': 'À chaque envie'}),
  ),
  'nail_biting': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مرات القضم اليوم', 'en': 'Biting episodes today', 'fr': 'Épisodes de rongement'}, low: {'ar': 'لم يحدث', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'مرات كثيرة', 'en': 'Many times', 'fr': 'Très nombreux'}),
    secondary: HabitMetric(label: {'ar': 'الانتباه المبكر ليدك', 'en': 'Catching your hand early', 'fr': 'Main remarquée à temps'}, low: {'ar': 'لم أنتبه', 'en': 'Never noticed', 'fr': 'Jamais remarquée'}, high: {'ar': 'أوقفتها فوراً', 'en': 'Stopped it instantly', 'fr': 'Arrêtée aussitôt'}),
  ),
  'hair_pulling': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مرات النتف اليوم', 'en': 'Pulling episodes today', 'fr': 'Épisodes d\'arrachage'}, low: {'ar': 'لم يحدث', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'مرات كثيرة', 'en': 'Many times', 'fr': 'Très nombreux'}),
    secondary: HabitMetric(label: {'ar': 'استخدام القبضة البديلة', 'en': 'Using your fist clench', 'fr': 'Recours au poing serré'}, low: {'ar': 'لم أستخدمها', 'en': 'Not used', 'fr': 'Jamais'}, high: {'ar': 'عند كل رغبة', 'en': 'Every urge', 'fr': 'À chaque envie'}),
  ),
  'skin_picking': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مرات نتش الجلد اليوم', 'en': 'Picking episodes today', 'fr': 'Épisodes de grattage'}, low: {'ar': 'لم يحدث', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'مرات كثيرة', 'en': 'Many times', 'fr': 'Très nombreux'}),
    secondary: HabitMetric(label: {'ar': 'إشغال يديك عند الرغبة', 'en': 'Keeping hands busy', 'fr': 'Mains occupées'}, low: {'ar': 'أبداً', 'en': 'Never', 'fr': 'Jamais'}, high: {'ar': 'في كل مرة', 'en': 'Every time', 'fr': 'À chaque fois'}),
  ),
  'secret_habit': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'التعرّض للمثيرات اليوم', 'en': 'Trigger exposure today', 'fr': 'Exposition aux déclencheurs'}, low: {'ar': 'لا تعرّض', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'تعرّض كثير', 'en': 'Very high', 'fr': 'Très forte'}),
    secondary: HabitMetric(label: {'ar': 'سرعة الابتعاد عن المثير', 'en': 'Speed of turning away', 'fr': 'Rapidité à se détourner'}, low: {'ar': 'بطيئة', 'en': 'Slow', 'fr': 'Lente'}, high: {'ar': 'فورية', 'en': 'Immediate', 'fr': 'Immédiate'}),
  ),
  'phone_addiction': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'التصفح بلا وعي', 'en': 'Mindless scrolling', 'fr': 'Défilement machinal'}, low: {'ar': 'قليل جداً', 'en': 'Barely any', 'fr': 'Très peu'}, high: {'ar': 'معظم اليوم', 'en': 'Most of the day', 'fr': 'Presque toute la journée'}),
    secondary: HabitMetric(label: {'ar': 'الاستخدام الواعي', 'en': 'Intentional use', 'fr': 'Usage intentionnel'}, low: {'ar': 'عشوائي', 'en': 'Random', 'fr': 'Aléatoire'}, high: {'ar': 'منضبط ومقصود', 'en': 'Fully intentional', 'fr': 'Pleinement maîtrisé'}),
  ),
  'excessive_gaming': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'وقت اللعب اليوم', 'en': 'Gaming time today', 'fr': 'Temps de jeu aujourd\'hui'}, low: {'ar': 'لم ألعب', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'ساعات طويلة', 'en': 'Many hours', 'fr': 'De longues heures'}),
    secondary: HabitMetric(label: {'ar': 'الالتزام بالحد المسموح', 'en': 'Sticking to your limit', 'fr': 'Respect de la limite'}, low: {'ar': 'تجاوزته كثيراً', 'en': 'Far over it', 'fr': 'Très dépassée'}, high: {'ar': 'التزمت تماماً', 'en': 'Fully kept', 'fr': 'Pleinement respectée'}),
  ),
  'procrastination': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'إغراء التأجيل', 'en': 'Urge to postpone', 'fr': 'Envie de reporter'}, low: {'ar': 'ضعيف', 'en': 'Weak', 'fr': 'Faible'}, high: {'ar': 'شديد جداً', 'en': 'Overwhelming', 'fr': 'Écrasante'}),
    secondary: HabitMetric(label: {'ar': 'البدء الفوري بالمهام', 'en': 'Starting promptly', 'fr': 'Passage à l\'action'}, low: {'ar': 'لم أبدأ', 'en': 'Never started', 'fr': 'Jamais commencé'}, high: {'ar': 'بدأت فوراً', 'en': 'Started right away', 'fr': 'Commencé aussitôt'}),
  ),
  'junk_food': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'اشتهاء الأكل غير الصحي', 'en': 'Junk cravings', 'fr': 'Envies de malbouffe'}, low: {'ar': 'لا اشتهاء', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'شديد جداً', 'en': 'Very strong', 'fr': 'Très fortes'}),
    secondary: HabitMetric(label: {'ar': 'جودة وجباتك اليوم', 'en': 'Meal quality today', 'fr': 'Qualité des repas'}, low: {'ar': 'سيئة', 'en': 'Poor', 'fr': 'Mauvaise'}, high: {'ar': 'صحية متوازنة', 'en': 'Healthy and balanced', 'fr': 'Saine et équilibrée'}),
  ),
  'oversleeping': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'الرغبة في مواصلة النوم', 'en': 'Pull to keep sleeping', 'fr': 'Envie de rester au lit'}, low: {'ar': 'ضعيفة', 'en': 'Weak', 'fr': 'Faible'}, high: {'ar': 'قاهرة', 'en': 'Overwhelming', 'fr': 'Écrasante'}),
    secondary: HabitMetric(label: {'ar': 'النهوض بنشاط', 'en': 'Getting up with energy', 'fr': 'Lever énergique'}, low: {'ar': 'عدت إلى النوم', 'en': 'Went back to sleep', 'fr': 'Rendormi'}, high: {'ar': 'نهضت فوراً بنشاط', 'en': 'Up at once, energized', 'fr': 'Levé aussitôt, en forme'}),
  ),
  'gossip': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'إغراء الغيبة', 'en': 'Temptation to gossip', 'fr': 'Tentation de médire'}, low: {'ar': 'ضعيف', 'en': 'Weak', 'fr': 'Faible'}, high: {'ar': 'شديد جداً', 'en': 'Very strong', 'fr': 'Très forte'}),
    secondary: HabitMetric(label: {'ar': 'حفظ اللسان اليوم', 'en': 'Guarding your tongue', 'fr': 'Maîtrise de la langue'}, low: {'ar': 'ضعيف', 'en': 'Weak', 'fr': 'Faible'}, high: {'ar': 'تام', 'en': 'Complete', 'fr': 'Totale'}),
  ),
  'bad_language': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'دافع الألفاظ السيئة', 'en': 'Urge to swear', 'fr': 'Envie de jurer'}, low: {'ar': 'لا دافع', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'شديد جداً', 'en': 'Very strong', 'fr': 'Très forte'}),
    secondary: HabitMetric(label: {'ar': 'طيب كلامك اليوم', 'en': 'Speech kindness', 'fr': 'Douceur du langage'}, low: {'ar': 'جارح', 'en': 'Harsh', 'fr': 'Blessant'}, high: {'ar': 'طيّب ونظيف', 'en': 'Kind and clean', 'fr': 'Doux et respectueux'}),
  ),
  'impulse_buying': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'شدة إغراء الشراء', 'en': 'Buying temptation', 'fr': 'Tentation d\'achat'}, low: {'ar': 'لا إغراء', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'شديد جداً', 'en': 'Very strong', 'fr': 'Très forte'}),
    secondary: HabitMetric(label: {'ar': 'ضبط الإنفاق', 'en': 'Spending control', 'fr': 'Contrôle des dépenses'}, low: {'ar': 'منفلت', 'en': 'Loose', 'fr': 'Relâché'}, high: {'ar': 'التزمت بقائمتي', 'en': 'Stuck to my list', 'fr': 'Fidèle à ma liste'}),
  ),
  'caffeine_excess': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'كمية الكافيين اليوم', 'en': 'Today\'s caffeine', 'fr': 'Caféine aujourd\'hui'}, low: {'ar': 'قليلة', 'en': 'Low', 'fr': 'Faible'}, high: {'ar': 'مفرطة جداً', 'en': 'Way too much', 'fr': 'Bien trop'}),
    secondary: HabitMetric(label: {'ar': 'اختيار البدائل الصحية', 'en': 'Healthy swaps', 'fr': 'Substituts sains'}, low: {'ar': 'أبداً', 'en': 'Never', 'fr': 'Jamais'}, high: {'ar': 'في كل مرة', 'en': 'Every time', 'fr': 'À chaque fois'}),
  ),
  'late_nights': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'تأخر موعد النوم', 'en': 'Bedtime lateness', 'fr': 'Retard du coucher'}, low: {'ar': 'نمت مبكراً', 'en': 'Slept early', 'fr': 'Couché tôt'}, high: {'ar': 'سهرت حتى الفجر', 'en': 'Up till dawn', 'fr': 'Jusqu\'à l\'aube'}),
    secondary: HabitMetric(label: {'ar': 'تهيئة النوم', 'en': 'Wind-down quality', 'fr': 'Rituel du coucher'}, low: {'ar': 'بلا تهيئة', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'شاشات مطفأة وأذكار', 'en': 'Screens off + adhkar', 'fr': 'Écrans éteints + adhkar'}),
  ),
  'binge_watching': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'ساعات المشاهدة اليوم', 'en': 'Watch time today', 'fr': 'Temps de visionnage'}, low: {'ar': 'لا شيء تقريباً', 'en': 'Almost none', 'fr': 'Presque rien'}, high: {'ar': 'ساعات متواصلة', 'en': 'Hours nonstop', 'fr': 'Des heures d\'affilée'}),
    secondary: HabitMetric(label: {'ar': 'التوقف عند الحد', 'en': 'Stopping on time', 'fr': 'Arrêt à l\'heure'}, low: {'ar': 'انجرفت', 'en': 'Got pulled in', 'fr': 'Emporté'}, high: {'ar': 'توقفت بسهولة', 'en': 'Stopped easily', 'fr': 'Arrêt facile'}),
  ),
  'anger': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'شدة المواقف المستفزة', 'en': 'Trigger intensity', 'fr': 'Intensité des déclencheurs'}, low: {'ar': 'يوم هادئ', 'en': 'Calm day', 'fr': 'Journée calme'}, high: {'ar': 'استفزاز شديد', 'en': 'Intense provocation', 'fr': 'Provocation intense'}),
    secondary: HabitMetric(label: {'ar': 'تمالك النفس', 'en': 'Self-control', 'fr': 'Maîtrise de soi'}, low: {'ar': 'انفعلت سريعاً', 'en': 'Snapped quickly', 'fr': 'Vite emporté'}, high: {'ar': 'ملكت نفسي', 'en': 'Fully composed', 'fr': 'Pleine maîtrise'}),
  ),
  'wake_fajr': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'تأخر القيام عن أذان الفجر', 'en': 'Wake-up delay after adhan', 'fr': 'Retard du réveil après l\'adhan'}, low: {'ar': 'قمت مع الأذان', 'en': 'Up with the adhan', 'fr': 'Levé à l\'adhan'}, high: {'ar': 'بعد طلوع الشمس', 'en': 'After sunrise', 'fr': 'Après le lever du soleil'}),
    secondary: HabitMetric(label: {'ar': 'سنّة الفجر وأذكار الصباح', 'en': 'Fajr sunnah + morning adhkar', 'fr': 'Sunna du Fajr + adhkar du matin'}, low: {'ar': 'لم أؤدّ شيئاً', 'en': 'None', 'fr': 'Rien'}, high: {'ar': 'أدّيتهما كاملتين', 'en': 'All done', 'fr': 'Tout accompli'}),
  ),
  'daily_quran': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'إنجاز الوِرد اليوم', 'en': 'Today\'s portion', 'fr': 'Portion du jour'}, low: {'ar': 'لم أقرأ', 'en': 'Nothing read', 'fr': 'Rien lu'}, high: {'ar': 'وِردي كاملاً وزيادة', 'en': 'Full portion or more', 'fr': 'Portion complète ou plus'}),
    secondary: HabitMetric(label: {'ar': 'التدبر وحضور القلب', 'en': 'Reflection (tadabbur)', 'fr': 'Méditation (tadabbur)'}, low: {'ar': 'قراءة عابرة', 'en': 'Rushed reading', 'fr': 'Lecture hâtive'}, high: {'ar': 'بتدبر وخشوع', 'en': 'Deep and attentive', 'fr': 'Attentive et méditative'}),
  ),
  'adhkar': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'أذكار الصباح', 'en': 'Morning adhkar', 'fr': 'Adhkar du matin'}, low: {'ar': 'فاتتني', 'en': 'Missed', 'fr': 'Manqués'}, high: {'ar': 'كاملة', 'en': 'Complete', 'fr': 'Complets'}),
    secondary: HabitMetric(label: {'ar': 'أذكار المساء', 'en': 'Evening adhkar', 'fr': 'Adhkar du soir'}, low: {'ar': 'فاتتني', 'en': 'Missed', 'fr': 'Manqués'}, high: {'ar': 'كاملة', 'en': 'Complete', 'fr': 'Complets'}),
  ),
  'voluntary_fasting': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'الالتزام بخطة الصيام اليوم', 'en': 'Keeping today\'s fasting plan', 'fr': 'Respect du programme de jeûne'}, low: {'ar': 'لم ألتزم', 'en': 'Not kept', 'fr': 'Non respecté'}, high: {'ar': 'التزمت كاملاً', 'en': 'Fully kept', 'fr': 'Pleinement respecté'}),
    secondary: HabitMetric(label: {'ar': 'حفظ الصيام من اللغو', 'en': 'Guarding the fast', 'fr': 'Préserver le jeûne'}, low: {'ar': 'غفلت كثيراً', 'en': 'Slipped often', 'fr': 'Souvent négligé'}, high: {'ar': 'حفظت لساني وجوارحي', 'en': 'Fully guarded', 'fr': 'Bien préservé'}),
  ),
  'qiyam': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مقدار قيام الليل', 'en': 'Qiyam amount', 'fr': 'Quantité de qiyam'}, low: {'ar': 'لم أقم', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'قمت طويلاً وأوترت', 'en': 'Long qiyam + witr', 'fr': 'Long qiyam + witr'}),
    secondary: HabitMetric(label: {'ar': 'الخشوع وحضور القلب', 'en': 'Focus (khushu)', 'fr': 'Recueillement'}, low: {'ar': 'ضعيف', 'en': 'Low', 'fr': 'Faible'}, high: {'ar': 'قلب حاضر خاشع', 'en': 'Deeply present', 'fr': 'Cœur présent'}),
  ),
  'keeping_ties': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'تواصلك مع أرحامك اليوم', 'en': 'Family contact today', 'fr': 'Contact familial du jour'}, low: {'ar': 'لم أتواصل', 'en': 'No contact', 'fr': 'Aucun contact'}, high: {'ar': 'زيارة أو مكالمة', 'en': 'Visit or a call', 'fr': 'Visite ou appel'}),
    secondary: HabitMetric(label: {'ar': 'دفء الصلة وعمقها', 'en': 'Warmth of the bond', 'fr': 'Chaleur du lien'}, low: {'ar': 'عابر وسريع', 'en': 'Brief and rushed', 'fr': 'Bref et expéditif'}, high: {'ar': 'قلبي وعميق', 'en': 'Heartfelt and deep', 'fr': 'Sincère et profond'}),
  ),
  'daily_charity': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'عطاؤك اليوم', 'en': 'Today\'s giving', 'fr': 'Don du jour'}, low: {'ar': 'لم أتصدق', 'en': 'Nothing given', 'fr': 'Rien donné'}, high: {'ar': 'أكثر من صدقة', 'en': 'More than one act', 'fr': 'Plusieurs actes'}),
    secondary: HabitMetric(label: {'ar': 'إخلاص العطاء وستره', 'en': 'Sincerity and discretion', 'fr': 'Sincérité et discrétion'}, low: {'ar': 'ضعيف', 'en': 'Weak', 'fr': 'Faible'}, high: {'ar': 'خالص ومستور', 'en': 'Pure and hidden', 'fr': 'Pur et discret'}),
  ),
  'istighfar': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مقدار استغفارك اليوم', 'en': 'Istighfar count today', 'fr': 'Istighfar du jour'}, low: {'ar': 'لم أستغفر', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'مئة أو أكثر', 'en': 'A hundred or more', 'fr': 'Cent ou plus'}),
    secondary: HabitMetric(label: {'ar': 'حضور القلب', 'en': 'Heart presence', 'fr': 'Présence du cœur'}, low: {'ar': 'باللسان فقط', 'en': 'Tongue only', 'fr': 'Langue seulement'}, high: {'ar': 'بقلب خاشع حاضر', 'en': 'Fully present heart', 'fr': 'Cœur pleinement présent'}),
  ),
  'exercise': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'حركتك اليوم', 'en': 'Today\'s movement', 'fr': 'Activité du jour'}, low: {'ar': 'لم أتحرك', 'en': 'No movement', 'fr': 'Aucune activité'}, high: {'ar': 'ثلاثون دقيقة أو أكثر', 'en': '30 minutes or more', 'fr': '30 minutes ou plus'}),
    secondary: HabitMetric(label: {'ar': 'الجهد المبذول', 'en': 'Effort level', 'fr': 'Niveau d\'effort'}, low: {'ar': 'خفيف جداً', 'en': 'Very light', 'fr': 'Très léger'}, high: {'ar': 'قوي ومركز', 'en': 'Strong and focused', 'fr': 'Soutenu et concentré'}),
  ),
  'read_books': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'قراءتك اليوم', 'en': 'Today\'s reading', 'fr': 'Lecture du jour'}, low: {'ar': 'لم أقرأ', 'en': 'Nothing read', 'fr': 'Rien lu'}, high: {'ar': 'عشر صفحات أو أكثر', 'en': '10 pages or more', 'fr': '10 pages ou plus'}),
    secondary: HabitMetric(label: {'ar': 'التركيز والفهم', 'en': 'Focus and understanding', 'fr': 'Concentration et compréhension'}, low: {'ar': 'مشتت', 'en': 'Distracted', 'fr': 'Distrait'}, high: {'ar': 'تركيز عميق', 'en': 'Deep focus', 'fr': 'Concentration profonde'}),
  ),
  'sleep_early': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'التأخر عن موعد النوم', 'en': 'Bedtime lateness', 'fr': 'Retard au coucher'}, low: {'ar': 'نمت في وقتي', 'en': 'On time', 'fr': 'À l\'heure'}, high: {'ar': 'تأخرت كثيراً', 'en': 'Very late', 'fr': 'Très tard'}),
    secondary: HabitMetric(label: {'ar': 'جودة التهيئة للنوم', 'en': 'Wind-down quality', 'fr': 'Qualité du rituel du soir'}, low: {'ar': 'بلا تهيئة', 'en': 'None', 'fr': 'Aucun'}, high: {'ar': 'هادئة متقنة', 'en': 'Calm and complete', 'fr': 'Calme et complet'}),
  ),
  'gratitude': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'استحضار نعم الله اليوم', 'en': 'Noticing blessings today', 'fr': 'Conscience des bienfaits'}, low: {'ar': 'غفلة', 'en': 'Heedless', 'fr': 'Inattention'}, high: {'ar': 'استحضار دائم', 'en': 'All day long', 'fr': 'Toute la journée'}),
    secondary: HabitMetric(label: {'ar': 'حضور القلب في الحمد والشكر', 'en': 'Heart presence', 'fr': 'Présence du cœur'}, low: {'ar': 'باللسان فقط', 'en': 'Words only', 'fr': 'Paroles seulement'}, high: {'ar': 'بقلب خاشع', 'en': 'Deeply felt', 'fr': 'Profondément ressenti'}),
  ),
  'learn_skill': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'وقت التعلّم اليوم', 'en': 'Learning time today', 'fr': 'Temps d\'apprentissage du jour'}, low: {'ar': 'لا شيء', 'en': 'None', 'fr': 'Rien'}, high: {'ar': 'جلسة كاملة', 'en': 'Full session', 'fr': 'Séance complète'}),
    secondary: HabitMetric(label: {'ar': 'عمق التركيز', 'en': 'Focus depth', 'fr': 'Profondeur de concentration'}, low: {'ar': 'مشتّت', 'en': 'Distracted', 'fr': 'Distrait'}, high: {'ar': 'تركيز عميق', 'en': 'Deep focus', 'fr': 'Concentration profonde'}),
  ),
  'salawat': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'مقدار الصلاة على النبي اليوم', 'en': 'Salawat amount today', 'fr': 'Quantité de salawat du jour'}, low: {'ar': 'لا شيء', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'كثير جداً', 'en': 'Abundant', 'fr': 'Abondante'}),
    secondary: HabitMetric(label: {'ar': 'الانتظام خلال اليوم', 'en': 'Spread over the day', 'fr': 'Répartition sur la journée'}, low: {'ar': 'مرة واحدة', 'en': 'One burst', 'fr': 'Une seule fois'}, high: {'ar': 'موزّعة طوال اليوم', 'en': 'Throughout the day', 'fr': 'Toute la journée'}),
  ),
  'honor_parents': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'برّك بوالديك اليوم', 'en': 'Kindness to your parents today', 'fr': 'Bonté envers vos parents'}, low: {'ar': 'لم أتواصل', 'en': 'No contact', 'fr': 'Aucun contact'}, high: {'ar': 'كلمة وخدمة ودعاء', 'en': 'Word, service, and du\'a', 'fr': 'Parole, service et invocation'}),
    secondary: HabitMetric(label: {'ar': 'لين الكلام معهما', 'en': 'Gentleness of speech', 'fr': 'Douceur des paroles'}, low: {'ar': 'جافّ', 'en': 'Curt', 'fr': 'Sec'}, high: {'ar': 'ليّن رحيم', 'en': 'Soft and kind', 'fr': 'Doux et bienveillant'}),
  ),
  'dua': HabitMetrics(
    primary: HabitMetric(label: {'ar': 'نصيبك من الدعاء اليوم', 'en': 'Today\'s du\'a portion', 'fr': 'Part d\'invocation du jour'}, low: {'ar': 'لم أدعُ', 'en': 'None', 'fr': 'Aucune'}, high: {'ar': 'ورد كامل', 'en': 'Full portion', 'fr': 'Portion complète'}),
    secondary: HabitMetric(label: {'ar': 'حضور القلب واليقين', 'en': 'Presence and certainty', 'fr': 'Présence et certitude'}, low: {'ar': 'بلسان غافل', 'en': 'Absent-minded', 'fr': 'Distrait'}, high: {'ar': 'بقلب موقن', 'en': 'Certain of the answer', 'fr': 'Cœur convaincu'}),
  ),
};

const Map<String, List<Map<String, String>>> kExtraCompeting = {
  'pray_on_time': [
    {'ar': 'توضأ فور سماع الأذان قبل أي انشغال.', 'en': 'Make wudu the moment you hear the adhan, before anything else.', 'fr': 'Faites les ablutions dès l\'appel, avant toute occupation.'},
    {'ar': 'أغلق شاشتك عند الأذان وقم إلى الصلاة مباشرة.', 'en': 'Close your screen at the adhan and get up to pray.', 'fr': 'Éteignez votre écran à l\'adhan et levez-vous pour prier.'},
    {'ar': 'صلِّ الفريضة أول وقتها ثم عد إلى عملك.', 'en': 'Pray at the start of its time, then return to your work.', 'fr': 'Priez dès l\'entrée du temps, puis reprenez votre travail.'},
    {'ar': 'صلِّ في جماعة كلما استطعت فهي أثبت لك.', 'en': 'Pray in congregation whenever you can; it keeps you steady.', 'fr': 'Priez en groupe quand vous le pouvez, cela vous affermit.'},
    {'ar': 'حافظ على السنن الرواتب لتثبيت عادة التبكير.', 'en': 'Keep the sunnah prayers to anchor praying early.', 'fr': 'Maintenez les prières surérogatoires pour ancrer la ponctualité.'},
  ],
  'wake_fajr': [
    {'ar': 'نم مبكراً واعقد النية للقيام للفجر.', 'en': 'Sleep early with a firm intention to rise for Fajr.', 'fr': 'Couchez-vous tôt avec l\'intention ferme de vous lever pour le Fajr.'},
    {'ar': 'اقرأ أذكار النوم قبل أن تغمض عينيك.', 'en': 'Recite the bedtime adhkar before you close your eyes.', 'fr': 'Récitez les adhkar du coucher avant de fermer les yeux.'},
    {'ar': 'اجلس فور المنبه وقل: الحمد لله الذي أحيانا.', 'en': 'Sit up at the alarm and say the waking du\'a.', 'fr': 'Asseyez-vous dès l\'alarme et dites l\'invocation du réveil.'},
    {'ar': 'اغسل وجهك بماء بارد فور نهوضك.', 'en': 'Splash cold water on your face as soon as you rise.', 'fr': 'Passez de l\'eau froide sur votre visage dès le lever.'},
    {'ar': 'توضأ مباشرة فالحركة والوضوء يطردان النعاس.', 'en': 'Make wudu right away; movement and water push sleep away.', 'fr': 'Faites aussitôt les ablutions, l\'eau chasse la somnolence.'},
  ],
  'daily_quran': [
    {'ar': 'ابدأ بخمس آيات فقط فقليل دائم خير من منقطع.', 'en': 'Start with just five verses; small and steady wins.', 'fr': 'Commencez par cinq versets, peu mais chaque jour.'},
    {'ar': 'اقرأ وِردك بعد صلاة الفجر مباشرة قبل الانشغال.', 'en': 'Read right after Fajr prayer, before the day starts.', 'fr': 'Lisez juste après la prière du Fajr, avant toute chose.'},
    {'ar': 'حدد مقدارك بصفحات معلومة لا بمزاج اليوم.', 'en': 'Fix a set number of pages, not today\'s mood.', 'fr': 'Fixez un nombre précis de pages, pas selon l\'humeur.'},
    {'ar': 'ضع علامة عند توقفك لتبدأ غداً بلا تردد.', 'en': 'Mark where you stop so tomorrow starts without friction.', 'fr': 'Marquez votre page pour reprendre demain sans hésiter.'},
    {'ar': 'إن ضاق وقتك فاستمع لوِردك في الطريق.', 'en': 'If time is tight, listen to your portion on the go.', 'fr': 'Si le temps manque, écoutez votre portion en route.'},
  ],
  'adhkar': [
    {'ar': 'ابدأ بالأذكار القصيرة الثابتة ثم زد تدريجياً.', 'en': 'Start with the short core adhkar, then add gradually.', 'fr': 'Commencez par les adhkar courts, puis ajoutez peu à peu.'},
    {'ar': 'اقرأ أذكار الصباح بعد الفجر قبل فتح هاتفك.', 'en': 'Say the morning adhkar after Fajr, before opening your phone.', 'fr': 'Récitez les adhkar du matin après le Fajr, avant le téléphone.'},
    {'ar': 'اربط أذكار المساء بصلاة العصر أو المغرب.', 'en': 'Stack the evening adhkar onto Asr or Maghrib prayer.', 'fr': 'Liez les adhkar du soir à la prière d\'Asr ou du Maghrib.'},
    {'ar': 'ردّدها بتمهل واستحضر معانيها ولا تسرع.', 'en': 'Recite slowly, feeling the meanings, without rushing.', 'fr': 'Récitez lentement, en méditant le sens, sans hâte.'},
    {'ar': 'إن فاتك الوقت فاقرأها متى تذكرت ولا تتركها.', 'en': 'If you miss the time, say them when you remember.', 'fr': 'Si l\'heure passe, récitez-les dès que vous y pensez.'},
  ],
  'voluntary_fasting': [
    {'ar': 'ابدأ بيوم واحد في الأسبوع ثم زد بتدرج.', 'en': 'Start with one day a week, then build up.', 'fr': 'Commencez par un jour par semaine, puis progressez.'},
    {'ar': 'اعقد نية الصيام من الليل واضبط منبه السحور.', 'en': 'Set your intention at night and an alarm for suhur.', 'fr': 'Formulez l\'intention la veille et réglez l\'alarme du souhour.'},
    {'ar': 'تسحّر ولو بتمرات وماء ففي السحور بركة.', 'en': 'Take suhur, even dates and water; it carries blessing.', 'fr': 'Prenez le souhour, même dattes et eau, il est béni.'},
    {'ar': 'اجعل الاثنين والخميس موعدك الثابت للصيام.', 'en': 'Make Monday and Thursday your fixed fasting days.', 'fr': 'Faites du lundi et du jeudi vos jours fixes de jeûne.'},
    {'ar': 'عند الجوع اشغل نفسك بذكر أو عمل نافع.', 'en': 'When hunger bites, busy yourself with dhikr or useful work.', 'fr': 'Quand la faim monte, occupez-vous par le dhikr ou une tâche.'},
  ],
  'qiyam': [
    {'ar': 'ابدأ بركعتين خفيفتين قبل نومك ثم زد بتدرج.', 'en': 'Start with two light rak\'ahs before bed, then build up.', 'fr': 'Commencez par deux rak\'ahs légères avant de dormir, puis progressez.'},
    {'ar': 'أوتر قبل النوم إن خفت ألا تستيقظ.', 'en': 'Pray witr before sleeping if you fear not waking.', 'fr': 'Priez le witr avant de dormir si vous craignez de ne pas vous réveiller.'},
    {'ar': 'نم مبكراً وخذ قيلولة قصيرة إن استطعت.', 'en': 'Sleep early and take a short nap when you can.', 'fr': 'Couchez-vous tôt et faites une courte sieste si possible.'},
    {'ar': 'انوِ القيام قبل نومك فالنية الصادقة تعين.', 'en': 'Intend qiyam before you sleep; sincere intent helps you rise.', 'fr': 'Formulez l\'intention du qiyam avant de dormir, elle vous aidera.'},
    {'ar': 'اقرأ في قيامك ما تحفظ ولا تشق على نفسك.', 'en': 'Recite what you know by heart; do not overburden yourself.', 'fr': 'Récitez ce que vous connaissez, sans vous surcharger.'},
  ],
  'keeping_ties': [
    {'ar': 'اتصل اليوم بقريب واحد ولو لدقيقتين.', 'en': 'Call one relative today, even for two minutes.', 'fr': 'Appelez un proche aujourd\'hui, même deux minutes.'},
    {'ar': 'أرسل رسالة سلام ودعاء لقريب لم تكلمه منذ مدة.', 'en': 'Send a greeting and a du\'a to a relative you have not spoken to in a while.', 'fr': 'Envoyez un salut et une invocation à un proche perdu de vue.'},
    {'ar': 'اربط الصلة بعادة ثابتة: بعد العشاء كلم قريباً أو راسله.', 'en': 'Anchor it to a cue: after Isha, call or message one relative.', 'fr': 'Ancrez-le à un repère : après l\'Icha, appelez ou écrivez à un proche.'},
    {'ar': 'حدد يوماً ثابتاً في أسبوعك لزيارة الأهل.', 'en': 'Set a fixed weekly day to visit family.', 'fr': 'Réservez un jour fixe par semaine pour visiter la famille.'},
    {'ar': 'صل من قطعك، فذلك أعظم الصلة أجراً.', 'en': 'Reach out to those who cut you off; that tie has the greatest reward.', 'fr': 'Renouez avec qui vous a délaissé, c\'est le lien le mieux récompensé.'},
  ],
  'daily_charity': [
    {'ar': 'تصدق كل صباح بمبلغ يسير مهما صغر.', 'en': 'Give a small amount every morning, however tiny.', 'fr': 'Donnez chaque matin une petite somme, même minime.'},
    {'ar': 'اجعل صدقتك بعد صلاة الفجر مباشرة كل يوم.', 'en': 'Give right after Fajr prayer every day.', 'fr': 'Donnez juste après la prière du Fajr chaque jour.'},
    {'ar': 'تصدق بابتسامة أو مساعدة أو كلمة طيبة إن لم تجد مالاً.', 'en': 'No money today? Smile, help, or say a kind word.', 'fr': 'Sans argent, offrez un sourire, une aide ou un mot gentil.'},
    {'ar': 'أطعم محتاجاً أو اسق ماءً عند أول فرصة.', 'en': 'Feed someone in need or offer water at the first chance.', 'fr': 'Nourrissez un nécessiteux ou offrez de l\'eau dès que possible.'},
    {'ar': 'أخف صدقتك ما استطعت، فالسر أقرب إلى الإخلاص.', 'en': 'Keep your charity hidden when you can; secrecy guards sincerity.', 'fr': 'Gardez votre aumône discrète, le secret nourrit la sincérité.'},
  ],
  'istighfar': [
    {'ar': 'استغفر عشر مرات بعد كل صلاة مفروضة.', 'en': 'Say istighfar ten times after each obligatory prayer.', 'fr': 'Faites l\'istighfar dix fois après chaque prière obligatoire.'},
    {'ar': 'املأ أوقات الانتظار والطريق بالاستغفار.', 'en': 'Fill waiting times and commutes with istighfar.', 'fr': 'Remplissez les attentes et les trajets d\'istighfar.'},
    {'ar': 'اجعل هدفك الاستغفار مئة مرة موزعة على يومك.', 'en': 'Aim for a hundred istighfar spread across your day.', 'fr': 'Visez cent istighfar répartis sur la journée.'},
    {'ar': 'احفظ سيد الاستغفار وردده صباحاً ومساءً.', 'en': 'Memorize sayyid al-istighfar; say it morning and evening.', 'fr': 'Mémorisez le sayyid al-istighfar, récitez-le matin et soir.'},
    {'ar': 'استحضر معنى الاستغفار ولا تردده بلسانك وحده.', 'en': 'Feel the meaning of istighfar; not with the tongue alone.', 'fr': 'Ressentez le sens de l\'istighfar, pas seulement les mots.'},
  ],
  'exercise': [
    {'ar': 'البس حذاء الرياضة فور عزمك، فاللبس نصف البداية.', 'en': 'Put on your workout shoes at once; that is half the start.', 'fr': 'Enfilez vos chaussures de sport aussitôt, c\'est la moitié du départ.'},
    {'ar': 'ابدأ بعشر دقائق مشي فقط ثم زد تدريجياً.', 'en': 'Start with just ten minutes of walking, then build up.', 'fr': 'Commencez par dix minutes de marche, puis augmentez.'},
    {'ar': 'اربط تمرينك بعادة ثابتة: بعد صلاة العصر تحرك.', 'en': 'Anchor it to a cue: move right after Asr prayer.', 'fr': 'Ancrez-le à un repère : bougez après la prière du Asr.'},
    {'ar': 'حدد من الليلة وقت تمرين الغد ومكانه.', 'en': 'Decide tonight when and where you will train tomorrow.', 'fr': 'Fixez ce soir l\'heure et le lieu de la séance de demain.'},
    {'ar': 'تمرن مع صديق يشجعك ويسألك عن التزامك.', 'en': 'Train with a friend who encourages and checks on you.', 'fr': 'Entraînez-vous avec un ami qui vous encourage et vous suit.'},
  ],
  'drink_water': [
    {'ar': 'اشرب كوب ماء فور استيقاظك قبل كل شيء.', 'en': 'Drink a glass of water first thing after waking.', 'fr': 'Buvez un verre d\'eau dès le réveil, avant tout.'},
    {'ar': 'اشرب كوباً قبل كل صلاة من الصلوات الخمس.', 'en': 'Drink a cup before each of the five prayers.', 'fr': 'Buvez un verre avant chacune des cinq prières.'},
    {'ar': 'اشرب كوباً قبل كل وجبة.', 'en': 'Drink a glass before every meal.', 'fr': 'Buvez un verre avant chaque repas.'},
    {'ar': 'اختر الماء بدل المشروبات الغازية عند العطش.', 'en': 'Choose water over soda whenever you feel thirsty.', 'fr': 'Choisissez l\'eau plutôt que le soda quand vous avez soif.'},
    {'ar': 'اجلس واشرب على دفعات اتباعاً للسنة.', 'en': 'Sit and sip in stages, following the sunnah.', 'fr': 'Asseyez-vous et buvez par gorgées, selon la sunna.'},
  ],
  'read_books': [
    {'ar': 'اقرأ صفحتين فقط كل يوم، فقليل دائم خير.', 'en': 'Read just two pages a day; small and steady wins.', 'fr': 'Lisez deux pages par jour, peu mais constant.'},
    {'ar': 'اربط قراءتك بقهوة الصباح أو بما بعد الفجر.', 'en': 'Pair reading with morning coffee or after Fajr.', 'fr': 'Associez la lecture au café du matin ou après le Fajr.'},
    {'ar': 'حدد موعد قراءتك ومكانها من الليلة.', 'en': 'Decide tonight when and where you will read.', 'fr': 'Fixez ce soir l\'heure et le lieu de votre lecture.'},
    {'ar': 'افتح كتابك بدل هاتفك في أوقات الانتظار.', 'en': 'Open your book instead of your phone while waiting.', 'fr': 'Ouvrez votre livre au lieu du téléphone en attendant.'},
    {'ar': 'دون سطراً واحداً مما فهمت بعد كل قراءة.', 'en': 'Write one line of what you understood after each read.', 'fr': 'Notez une ligne de ce que vous avez compris après chaque lecture.'},
  ],
  'sleep_early': [
    {'ar': 'حدّد موعداً ثابتاً للنوم والتزم به كل ليلة', 'en': 'Set a fixed bedtime and keep it every night', 'fr': 'Fixez une heure de coucher constante chaque soir'},
    {'ar': 'اضبط منبّه تهيئة قبل موعد نومك بنصف ساعة', 'en': 'Set a wind-down alarm thirty minutes before bedtime', 'fr': 'Réglez une alarme trente minutes avant le coucher'},
    {'ar': 'عند المنبّه أطفئ الشاشات وخفّف الإضاءة', 'en': 'At the alarm, switch off screens and dim the lights', 'fr': 'À l\'alarme, éteignez les écrans et tamisez la lumière'},
    {'ar': 'توضأ واقرأ أذكار النوم ثم استلقِ في فراشك', 'en': 'Make wudu, recite the sleep adhkar, then lie down', 'fr': 'Faites les ablutions, récitez les adhkar, puis couchez-vous'},
    {'ar': 'استيقظ لصلاة الفجر في وقت ثابت كل يوم', 'en': 'Wake for Fajr at the same time every day', 'fr': 'Levez-vous pour Fajr à heure fixe chaque jour'},
  ],
  'gratitude': [
    {'ar': 'اذكر ثلاث نعم جديدة بعد أذكار الصباح', 'en': 'Name three new blessings after your morning adhkar', 'fr': 'Citez trois bienfaits après les adhkar du matin'},
    {'ar': 'قل الحمد لله عند كل نعمة تلاحظها', 'en': 'Say alhamdulillah at every blessing you notice', 'fr': 'Dites alhamdulillah à chaque bienfait remarqué'},
    {'ar': 'اكتب نعمة واحدة في دفترك قبل النوم', 'en': 'Write one blessing in your notebook before sleep', 'fr': 'Notez un bienfait dans votre carnet avant de dormir'},
    {'ar': 'ادعُ الله بحاجة قلبك بعد كل صلاة', 'en': 'Ask Allah for your heart\'s need after each prayer', 'fr': 'Présentez à Dieu le besoin de votre cœur après chaque prière'},
    {'ar': 'اشكر شخصاً أحسن إليك بكلمة صادقة اليوم', 'en': 'Thank someone sincerely for a kindness today', 'fr': 'Remerciez sincèrement une personne aujourd\'hui'},
  ],
  'learn_skill': [
    {'ar': 'اختر مهارة واحدة وحدّد هدفاً صغيراً واضحاً', 'en': 'Pick one skill and set a small clear goal', 'fr': 'Choisissez une compétence et un petit objectif clair'},
    {'ar': 'تعلّم عشر دقائق يومياً في وقت ثابت', 'en': 'Practice ten minutes daily at a fixed time', 'fr': 'Pratiquez dix minutes par jour à heure fixe'},
    {'ar': 'اربط جلستك بعادة ثابتة كقهوة الصباح', 'en': 'Stack the session onto a fixed habit like morning coffee', 'fr': 'Associez la séance à une habitude fixe comme le café du matin'},
    {'ar': 'ابدأ بأسهل تمرين حتى يسهل عليك الشروع', 'en': 'Start with the easiest exercise so starting feels effortless', 'fr': 'Commencez par l\'exercice le plus facile pour démarrer sans effort'},
    {'ar': 'سجّل ما تعلّمته اليوم في سطر واحد', 'en': 'Log today\'s learning in a single line', 'fr': 'Notez l\'acquis du jour en une ligne'},
  ],
  'salawat': [
    {'ar': 'ابدأ بورد صغير: عشر صلوات بعد الفجر', 'en': 'Start small: ten salawat after Fajr', 'fr': 'Commencez petit : dix salawat après Fajr'},
    {'ar': 'صلِّ على النبي كلما سمعت الأذان', 'en': 'Send salawat whenever you hear the adhan', 'fr': 'Priez sur le Prophète à chaque adhan'},
    {'ar': 'ردّدها في الانتظار والطريق بدلاً من تصفح الهاتف', 'en': 'Repeat them while waiting or traveling instead of scrolling', 'fr': 'Répétez-les dans l\'attente et en chemin au lieu du téléphone'},
    {'ar': 'زد وردك تدريجياً كل أسبوع بما تطيق', 'en': 'Raise your portion gradually each week as you can', 'fr': 'Augmentez votre part progressivement chaque semaine'},
    {'ar': 'أكثر منها يوم الجمعة واجعل لها وقتاً خاصاً', 'en': 'Increase on Friday and give it a set time', 'fr': 'Multipliez-les le vendredi et réservez-leur un moment dédié'},
  ],
  'honor_parents': [
    {'ar': 'ابدأ يومك بالسلام على والديك أو الاتصال بهما', 'en': 'Start your day greeting or calling your parents', 'fr': 'Commencez la journée en saluant ou appelant vos parents'},
    {'ar': 'قدّم لهما خدمة صغيرة واحدة كل يوم', 'en': 'Do one small service for them every day', 'fr': 'Rendez-leur un petit service chaque jour'},
    {'ar': 'اسألهما عن حاجتهما قبل أن يطلبا', 'en': 'Ask about their needs before they have to ask', 'fr': 'Demandez leurs besoins avant qu\'ils ne demandent'},
    {'ar': 'أنصت لحديثهما دون مقاطعة ولا تأفف', 'en': 'Listen fully, without interrupting or sighing', 'fr': 'Écoutez-les sans interrompre ni soupirer'},
    {'ar': 'ادعُ لهما بعد كل صلاة: ربِّ ارحمهما', 'en': 'Pray for them after every prayer: My Lord, have mercy on them', 'fr': 'Invoquez pour eux après chaque prière : Seigneur, fais-leur miséricorde'},
  ],
  'dua': [
    {'ar': 'اكتب ثلاث حاجات تسأل الله إياها كل يوم', 'en': 'Write three needs to ask Allah for each day', 'fr': 'Écrivez trois besoins à demander chaque jour'},
    {'ar': 'اجعل لك دعاءً ثابتاً بعد كل صلاة مفروضة', 'en': 'Fix a du\'a moment after every obligatory prayer', 'fr': 'Fixez une invocation après chaque prière obligatoire'},
    {'ar': 'ابدأ بحمد الله والصلاة على النبي ثم اسأل', 'en': 'Open with praise and salawat, then ask', 'fr': 'Commencez par la louange et les salawat, puis demandez'},
    {'ar': 'تحرَّ أوقات الإجابة كالسجود وآخر الليل', 'en': 'Seek the times of acceptance, like sujud and late night', 'fr': 'Visez les moments d\'exaucement : prosternation et fin de nuit'},
    {'ar': 'ادعُ لوالديك وإخوانك مع حاجاتك', 'en': 'Pray for your parents and others alongside your needs', 'fr': 'Incluez vos parents et les autres dans vos demandes'},
  ],
};

const Map<String, List<Map<String, String>>> kExtraEnvironment = {
  'pray_on_time': [
    {'ar': 'ثبّت تطبيق أذان وفعّل تنبيهاً لكل فريضة.', 'en': 'Install an adhan app and enable an alert for each prayer.', 'fr': 'Installez une application d\'adhan avec une alerte par prière.'},
    {'ar': 'افرش سجادتك في مكان ظاهر تراه دائماً.', 'en': 'Keep your prayer rug visible where you always see it.', 'fr': 'Laissez votre tapis de prière visible en permanence.'},
    {'ar': 'رتّب مواعيدك واجتماعاتك حول أوقات الصلاة.', 'en': 'Schedule your meetings and tasks around prayer times.', 'fr': 'Organisez vos rendez-vous autour des heures de prière.'},
    {'ar': 'اتفق مع زميل أو قريب يذكّرك عند كل صلاة.', 'en': 'Pair up with a colleague or relative who reminds you at each prayer.', 'fr': 'Convenez d\'un proche qui vous rappelle chaque prière.'},
  ],
  'wake_fajr': [
    {'ar': 'ضع المنبه بعيداً عن سريرك حتى تقوم لإطفائه.', 'en': 'Place the alarm far from your bed so you must stand up.', 'fr': 'Placez le réveil loin du lit pour devoir vous lever.'},
    {'ar': 'اترك هاتفك بعيداً عن فراشك ليلاً.', 'en': 'Keep your phone out of reach of your bed at night.', 'fr': 'Gardez le téléphone loin de votre lit la nuit.'},
    {'ar': 'جهّز ملابسك وسجادتك ومكان وضوئك قبل النوم.', 'en': 'Prepare your clothes, rug, and wudu spot before sleeping.', 'fr': 'Préparez vêtements, tapis et ablutions avant de dormir.'},
    {'ar': 'اتفق مع صاحب على إيقاظ بعضكما للفجر.', 'en': 'Agree with a friend to wake each other for Fajr.', 'fr': 'Convenez avec un ami de vous réveiller mutuellement pour le Fajr.'},
  ],
  'daily_quran': [
    {'ar': 'ضع المصحف ظاهراً في مكان جلوسك المعتاد.', 'en': 'Keep the mushaf visible where you usually sit.', 'fr': 'Laissez le mushaf visible à votre place habituelle.'},
    {'ar': 'ثبّت تطبيق القرآن في واجهة هاتفك الأولى.', 'en': 'Put a Qur\'an app on your phone\'s first screen.', 'fr': 'Placez une application Coran sur le premier écran.'},
    {'ar': 'خصص ركناً هادئاً للقراءة بعيداً عن الضجيج.', 'en': 'Set up a quiet reading corner away from noise.', 'fr': 'Aménagez un coin de lecture calme, loin du bruit.'},
    {'ar': 'فعّل تذكيراً يومياً في وقت وِردك الثابت.', 'en': 'Set a daily reminder at your fixed reading time.', 'fr': 'Activez un rappel quotidien à l\'heure de votre lecture.'},
  ],
  'adhkar': [
    {'ar': 'ضع كتيب الأذكار قرب سجادتك أو سريرك.', 'en': 'Keep an adhkar booklet by your rug or bed.', 'fr': 'Gardez un livret d\'adhkar près du tapis ou du lit.'},
    {'ar': 'فعّل تذكيري الصباح والمساء في هذا التطبيق.', 'en': 'Turn on the morning and evening reminders in this app.', 'fr': 'Activez les rappels du matin et du soir dans l\'application.'},
    {'ar': 'اجعل تطبيق الأذكار في واجهة هاتفك الأولى.', 'en': 'Put your adhkar app on the phone\'s first screen.', 'fr': 'Placez l\'application d\'adhkar sur le premier écran.'},
    {'ar': 'علّق بطاقة أذكار في مكان تراه كل يوم.', 'en': 'Hang an adhkar card somewhere you see every day.', 'fr': 'Affichez une carte d\'adhkar bien en vue chaque jour.'},
  ],
  'voluntary_fasting': [
    {'ar': 'علّم أيام الصيام والأيام البيض في تقويمك.', 'en': 'Mark fasting days and the white days on your calendar.', 'fr': 'Marquez les jours de jeûne et les jours blancs au calendrier.'},
    {'ar': 'جهّز التمر والماء لسحورك وإفطارك مسبقاً.', 'en': 'Prepare dates and water for suhur and iftar in advance.', 'fr': 'Préparez à l\'avance dattes et eau pour souhour et iftar.'},
    {'ar': 'أخبر أهلك بصيامك ليعينوك ويذكّروك.', 'en': 'Tell your family you are fasting so they support you.', 'fr': 'Informez votre famille de votre jeûne pour qu\'elle vous soutienne.'},
    {'ar': 'رتّب مواعيد طعامك واجتماعاتك بعيداً عن أيام صيامك.', 'en': 'Plan meals and lunch meetings away from your fasting days.', 'fr': 'Planifiez repas et déjeuners hors de vos jours de jeûne.'},
  ],
  'qiyam': [
    {'ar': 'اضبط منبهاً هادئاً قبل أذان الفجر بنصف ساعة.', 'en': 'Set a gentle alarm half an hour before Fajr.', 'fr': 'Réglez une alarme douce une demi-heure avant le Fajr.'},
    {'ar': 'جهّز سجادتك ومكان وضوئك قبل أن تنام.', 'en': 'Prepare your rug and wudu spot before sleeping.', 'fr': 'Préparez votre tapis et vos ablutions avant de dormir.'},
    {'ar': 'نم على وضوء ليخف عليك القيام.', 'en': 'Sleep with wudu so rising for prayer feels lighter.', 'fr': 'Dormez en état d\'ablutions pour vous lever plus facilement.'},
    {'ar': 'اتفق مع صاحب يوقظك أو يقوم معك.', 'en': 'Team up with a friend to wake or pray together.', 'fr': 'Convenez avec un ami de vous réveiller ou prier ensemble.'},
  ],
  'keeping_ties': [
    {'ar': 'اكتب قائمة بأسماء أقاربك واحفظها في هاتفك.', 'en': 'List your relatives\' names and keep it on your phone.', 'fr': 'Notez la liste de vos proches dans votre téléphone.'},
    {'ar': 'اضبط تذكيراً أسبوعياً يحمل اسم قريب مختلف.', 'en': 'Set a weekly reminder naming a different relative each time.', 'fr': 'Programmez un rappel hebdomadaire nommant un proche différent.'},
    {'ar': 'ثبت أرقام أهلك في قائمة المفضلة بهاتفك.', 'en': 'Pin your family\'s numbers in your favorites list.', 'fr': 'Épinglez les numéros de la famille dans vos favoris.'},
    {'ar': 'انضم إلى مجموعة العائلة وفعل إشعاراتها.', 'en': 'Join the family group chat and turn on its notifications.', 'fr': 'Rejoignez le groupe familial et activez ses notifications.'},
  ],
  'daily_charity': [
    {'ar': 'خصص حصالة للصدقة في مكان بارز من بيتك.', 'en': 'Keep a charity jar in a visible spot at home.', 'fr': 'Placez une tirelire d\'aumône bien en vue chez vous.'},
    {'ar': 'فعل تبرعاً تلقائياً شهرياً ولو بمبلغ يسير.', 'en': 'Set up a small automatic monthly donation.', 'fr': 'Programmez un petit don mensuel automatique.'},
    {'ar': 'احتفظ بمبالغ يسيرة في جيبك وسيارتك للمحتاجين.', 'en': 'Keep small cash in your pocket and car for those in need.', 'fr': 'Gardez de la petite monnaie en poche et en voiture pour les nécessiteux.'},
    {'ar': 'ثبت تطبيق جمعية موثوقة ليسهل عطاؤك بلمسة.', 'en': 'Install a trusted charity app so giving takes one tap.', 'fr': 'Installez l\'appli d\'une association fiable pour donner en un geste.'},
  ],
  'istighfar': [
    {'ar': 'اضبط ثلاثة تذكيرات يومية قصيرة للاستغفار.', 'en': 'Set three short daily istighfar reminders.', 'fr': 'Programmez trois brefs rappels d\'istighfar par jour.'},
    {'ar': 'ضع مسبحة في جيبك وأخرى على مكتبك.', 'en': 'Keep prayer beads in your pocket and on your desk.', 'fr': 'Gardez un chapelet en poche et un autre au bureau.'},
    {'ar': 'اجعل خلفية هاتفك تذكرك بالاستغفار.', 'en': 'Make your phone wallpaper an istighfar reminder.', 'fr': 'Mettez un rappel d\'istighfar en fond d\'écran.'},
    {'ar': 'استخدم عداد ذكر لمتابعة وردك اليومي.', 'en': 'Use a dhikr counter to track your daily portion.', 'fr': 'Utilisez un compteur de dhikr pour suivre votre portion quotidienne.'},
  ],
  'exercise': [
    {'ar': 'جهز ملابس الرياضة من الليل وضعها ظاهرة.', 'en': 'Lay out your workout clothes the night before, in sight.', 'fr': 'Préparez vos affaires de sport la veille, bien visibles.'},
    {'ar': 'افرش سجادة التمارين في مكان تمر به يومياً.', 'en': 'Keep an exercise mat unrolled where you pass daily.', 'fr': 'Laissez un tapis d\'exercice déroulé sur votre passage.'},
    {'ar': 'ضع تطبيق التمرين في الصفحة الأولى من هاتفك.', 'en': 'Put your workout app on your phone\'s first screen.', 'fr': 'Placez l\'appli de sport sur le premier écran du téléphone.'},
    {'ar': 'اختر مساراً للمشي أو نادياً قريباً من بيتك.', 'en': 'Pick a walking route or gym close to home.', 'fr': 'Choisissez un parcours de marche ou une salle près de chez vous.'},
  ],
  'drink_water': [
    {'ar': 'احمل قارورة ماء معك أينما ذهبت.', 'en': 'Carry a water bottle with you everywhere.', 'fr': 'Emportez une gourde d\'eau partout avec vous.'},
    {'ar': 'ضع كوب ماء على مكتبك وقرب سريرك.', 'en': 'Keep a glass of water on your desk and by your bed.', 'fr': 'Gardez un verre d\'eau au bureau et près du lit.'},
    {'ar': 'فعل تذكيرات الشرب على مدار يومك.', 'en': 'Turn on water reminders spread across your day.', 'fr': 'Activez des rappels d\'hydratation tout au long du jour.'},
    {'ar': 'ضع الماء في مقدمة الثلاجة وأبعد المشروبات الغازية.', 'en': 'Put water at the front of the fridge; hide the sodas.', 'fr': 'Placez l\'eau à l\'avant du réfrigérateur, éloignez les sodas.'},
  ],
  'read_books': [
    {'ar': 'ضع كتابك الحالي على وسادتك أو مكتبك ظاهراً.', 'en': 'Leave your current book visible on your pillow or desk.', 'fr': 'Laissez votre livre en vue sur l\'oreiller ou le bureau.'},
    {'ar': 'احمل كتاباً ورقياً أو إلكترونياً معك دائماً.', 'en': 'Always carry a paper or digital book with you.', 'fr': 'Ayez toujours un livre papier ou numérique sur vous.'},
    {'ar': 'أبعد هاتفك عن متناول يدك وقت القراءة.', 'en': 'Keep your phone out of reach while reading.', 'fr': 'Éloignez le téléphone pendant la lecture.'},
    {'ar': 'هيئ ركن قراءة مريحاً بإضاءة جيدة في بيتك.', 'en': 'Set up a cozy, well-lit reading corner at home.', 'fr': 'Aménagez un coin lecture confortable et bien éclairé.'},
  ],
  'sleep_early': [
    {'ar': 'اشحن هاتفك خارج غرفة النوم', 'en': 'Charge your phone outside the bedroom', 'fr': 'Chargez le téléphone hors de la chambre'},
    {'ar': 'اجعل غرفتك باردة ومظلمة وهادئة', 'en': 'Keep your bedroom cool, dark, and quiet', 'fr': 'Gardez la chambre fraîche, sombre et calme'},
    {'ar': 'تجنّب الكافيين بعد العصر لتنام بسهولة', 'en': 'Skip caffeine after mid-afternoon so sleep comes easier', 'fr': 'Évitez la caféine dès la mi-après-midi pour mieux dormir'},
    {'ar': 'رتّب فراشك مبكراً ليدعوك إلى النوم', 'en': 'Make your bed early so it invites you in', 'fr': 'Préparez votre lit tôt pour qu\'il vous invite'},
  ],
  'gratitude': [
    {'ar': 'ضع دفتر الشكر على وسادتك ليذكّرك', 'en': 'Keep the gratitude notebook on your pillow', 'fr': 'Gardez le carnet de gratitude sur l\'oreiller'},
    {'ar': 'اجعل خلفية هاتفك آية عن الشكر', 'en': 'Set a gratitude verse as your phone wallpaper', 'fr': 'Mettez un verset de gratitude en fond d\'écran'},
    {'ar': 'اضبط تذكيرين للحمد في الصباح والمساء', 'en': 'Set two praise reminders, morning and evening', 'fr': 'Réglez deux rappels, matin et soir'},
    {'ar': 'علّق ورقة بنعمك على المرآة لتراها يومياً', 'en': 'Stick a blessings note on your mirror', 'fr': 'Collez une note de bienfaits sur le miroir'},
  ],
  'learn_skill': [
    {'ar': 'جهّز أدوات التعلّم مفتوحة قبل الجلسة', 'en': 'Leave your materials open and ready before the session', 'fr': 'Préparez vos outils ouverts avant la séance'},
    {'ar': 'ثبّت تطبيق التعلّم في شاشة هاتفك الرئيسية', 'en': 'Pin the learning app to your home screen', 'fr': 'Épinglez l\'appli d\'apprentissage sur l\'écran d\'accueil'},
    {'ar': 'أغلق الإشعارات طوال جلسة التعلّم', 'en': 'Silence notifications for the whole session', 'fr': 'Coupez les notifications pendant toute la séance'},
    {'ar': 'خصّص ركناً ثابتاً للتعلّم في بيتك', 'en': 'Dedicate one fixed learning corner at home', 'fr': 'Réservez un coin d\'apprentissage fixe chez vous'},
  ],
  'salawat': [
    {'ar': 'احمل مسبحة صغيرة في جيبك دائماً', 'en': 'Always carry small prayer beads in your pocket', 'fr': 'Gardez un petit chapelet toujours en poche'},
    {'ar': 'اضبط تذكيراً يومياً ثابتاً للصلاة على النبي', 'en': 'Set a fixed daily salawat reminder', 'fr': 'Réglez un rappel quotidien fixe pour les salawat'},
    {'ar': 'ثبّت عدّاد ذكر في شاشة هاتفك الرئيسية', 'en': 'Keep a dhikr counter on your home screen', 'fr': 'Mettez un compteur de dhikr sur l\'écran d\'accueil'},
    {'ar': 'علّق بطاقة عن فضل الصلاة على النبي حيث تجلس', 'en': 'Hang a card on the virtue of salawat where you sit', 'fr': 'Affichez une carte sur la vertu des salawat bien en vue'},
  ],
  'honor_parents': [
    {'ar': 'اضبط تذكيراً يومياً للاتصال بهما أو زيارتهما', 'en': 'Set a daily reminder to call or visit them', 'fr': 'Réglez un rappel quotidien pour appeler ou visiter'},
    {'ar': 'ثبّت محادثتهما في أعلى تطبيق الرسائل', 'en': 'Pin their chat to the top of your messages', 'fr': 'Épinglez leur conversation en haut de la messagerie'},
    {'ar': 'اجعل دعاء الوالدين خلفية شاشة هاتفك', 'en': 'Set the parents\' du\'a as your phone wallpaper', 'fr': 'Mettez l\'invocation pour les parents en fond d\'écran'},
    {'ar': 'خصّص وقتاً أسبوعياً ثابتاً لزيارتهما أو خدمتهما', 'en': 'Block a fixed weekly time to visit or serve them', 'fr': 'Réservez un créneau hebdomadaire fixe pour eux'},
  ],
  'dua': [
    {'ar': 'علّق قائمة حاجاتك قرب مصلاك', 'en': 'Hang your du\'a list beside your prayer spot', 'fr': 'Affichez votre liste près du lieu de prière'},
    {'ar': 'اترك سجادتك ظاهرة تدعوك للركعتين والدعاء', 'en': 'Leave the prayer mat visible, inviting prayer and du\'a', 'fr': 'Laissez le tapis visible pour prier et invoquer'},
    {'ar': 'أبقِ كتيّب الأدعية في متناول يدك', 'en': 'Keep a du\'a booklet within easy reach', 'fr': 'Gardez un livret d\'invocations à portée de main'},
    {'ar': 'اضبط تذكيراً يومياً في وقت هادئ للدعاء', 'en': 'Set a daily reminder at a quiet time', 'fr': 'Réglez un rappel quotidien à un moment calme'},
  ],
};

/// Localized generated-checklist labels, or empty when the habit has none.
List<String> extraChecklistLabels(String? key, String group, String locale) {
  if (key == null) return const [];
  final list = group == 'competing_response'
      ? kExtraCompeting[key]
      : kExtraEnvironment[key];
  if (list == null) return const [];
  return list.map((m) => m[locale] ?? m['ar'] ?? '').toList();
}
