// Progressive stage framework tied to the user's streak and the shield
// milestones (silver 30 / gold 60 / diamond 90).
//
// BREAK habits follow the Habit Reversal Training arc + CBT relapse
// prevention: awareness -> competing response -> environment control ->
// maintenance & relapse prevention.
// BUILD habits follow habit-formation science (tiny habits, cue design,
// "never miss twice", identity-based habits): foundation -> consistency ->
// consolidation -> established habit.
//
// The daily log shows the current stage (name + focus + tips) and reorders
// its checklist groups to emphasize what matters at this stage.

class HabitStage {
  /// Inclusive current-streak threshold at which this stage begins.
  final int minDays;
  final Map<String, String> name; // ar/en/fr
  final Map<String, String> focus; // one-line coaching focus
  final List<Map<String, String>> tips; // 3 short stage tips

  const HabitStage({
    required this.minDays,
    required this.name,
    required this.focus,
    required this.tips,
  });

  String n(String l) => name[l] ?? name['ar'] ?? '';
  String f(String l) => focus[l] ?? focus['ar'] ?? '';
  List<String> t(String l) => tips.map((m) => m[l] ?? m['ar'] ?? '').toList();
}

const List<HabitStage> kBreakStages = [
  HabitStage(
    minDays: 0,
    name: {'ar': 'الوعي', 'en': 'Awareness', 'fr': 'Prise de conscience'},
    focus: {
      'ar': 'مهمتك هذا الأسبوع أن تعرف عادتك: متى تحدث، وأين، وما الذي يسبقها.',
      'en': 'This week your job is to know your habit: when it happens, where, and what comes right before it.',
      'fr': "Cette semaine, apprenez à connaître votre habitude : quand, où, et ce qui la précède."
    },
    tips: [
      {'ar': 'سجّل كل رغبة بصدق، فالملاحظة وحدها تُضعف العادة.', 'en': 'Log every urge honestly; observation alone weakens the habit.', 'fr': "Notez chaque envie honnêtement ; l'observation seule affaiblit l'habitude."},
      {'ar': 'حدّد أقوى ثلاثة محفزات لديك واكتبها في الملاحظات.', 'en': 'Identify your three strongest triggers and write them in the notes.', 'fr': 'Identifiez vos trois plus forts déclencheurs et notez-les.'},
      {'ar': 'لا تلم نفسك عند الزلل، راقب وتعلّم فقط في هذه المرحلة.', 'en': 'No self-blame after a slip; at this stage just observe and learn.', 'fr': "Pas de culpabilité après un écart ; observez et apprenez seulement."},
    ],
  ),
  HabitStage(
    minDays: 7,
    name: {'ar': 'الاستجابة البديلة', 'en': 'Competing response', 'fr': 'Réponse concurrente'},
    focus: {
      'ar': 'صار عندك وعي بالمحفزات، فالآن درّب البديل: عند كل رغبة نفّذ فعلاً معاكساً فوراً.',
      'en': 'You know your triggers now; train the replacement: at every urge, do the competing action immediately.',
      'fr': "Vous connaissez vos déclencheurs ; entraînez le remplacement : à chaque envie, faites l'action concurrente immédiatement."
    },
    tips: [
      {'ar': 'اختر بديلاً واحداً ثابتاً من القائمة والتزم به عند كل رغبة.', 'en': 'Pick one fixed competing response from the checklist and use it at every urge.', 'fr': "Choisissez une réponse concurrente fixe dans la liste et utilisez-la à chaque envie."},
      {'ar': 'الرغبة موجة تصعد ثم تنكسر، قاومها دقيقتين فقط وستمر.', 'en': 'An urge is a wave: it rises then breaks. Ride it out for two minutes and it passes.', 'fr': "L'envie est une vague : elle monte puis retombe. Tenez deux minutes et elle passera."},
      {'ar': 'كافئ نفسك مكافأة صغيرة حلالاً كلما نجح البديل.', 'en': 'Give yourself a small reward every time the replacement works.', 'fr': 'Offrez-vous une petite récompense chaque fois que le remplacement fonctionne.'},
    ],
  ),
  HabitStage(
    minDays: 30,
    name: {'ar': 'ضبط البيئة', 'en': 'Environment control', 'fr': "Contrôle de l'environnement"},
    focus: {
      'ar': 'درعك الفضي معك، والآن أعد تصميم محيطك حتى تقل المحفزات من أساسها.',
      'en': 'Silver shield earned. Now redesign your surroundings so triggers rarely appear at all.',
      'fr': "Bouclier d'argent obtenu. Réaménagez votre environnement pour faire disparaître les déclencheurs."
    },
    tips: [
      {'ar': 'نفّذ بنداً واحداً من قائمة البيئة كل يومين حتى تكملها.', 'en': 'Apply one environment item every two days until the list is done.', 'fr': "Appliquez un élément d'environnement tous les deux jours jusqu'à finir la liste."},
      {'ar': 'أخبر من حولك بتقدمك واطلب منهم إعانتك على البعد عن المحفزات.', 'en': 'Tell people around you about your progress and ask them to help keep triggers away.', 'fr': 'Parlez de vos progrès à votre entourage et demandez leur aide contre les déclencheurs.'},
      {'ar': 'لاحظ المواقف التي ما زالت تستفزك ودوّنها لمعالجتها.', 'en': 'Notice the situations that still provoke you and write them down to address.', 'fr': 'Repérez les situations qui vous provoquent encore et notez-les pour les traiter.'},
    ],
  ),
  HabitStage(
    minDays: 60,
    name: {'ar': 'التثبيت والوقاية', 'en': 'Maintenance & relapse prevention', 'fr': 'Maintien et prévention'},
    focus: {
      'ar': 'ما بقي هو حماية مكسبك: جهّز خطة للمواقف الخطرة، واجعل الزلة إن وقعت درساً لا سقوطاً.',
      'en': 'Protect the gain: prepare a plan for risky situations, and if a lapse happens make it a lesson, not a collapse.',
      'fr': "Protégez vos acquis : préparez un plan pour les situations à risque ; un écart doit rester une leçon, pas une rechute."
    },
    tips: [
      {'ar': 'اكتب خطة «إذا حدث كذا فسأفعل كذا» لأخطر ثلاثة مواقف.', 'en': 'Write an "if X happens, I will do Y" plan for your three riskiest situations.', 'fr': 'Écrivez un plan « si X arrive, je fais Y » pour vos trois situations les plus risquées.'},
      {'ar': 'زلة يوم واحد لا تلغي شهوراً من التقدم، عُد فوراً في اليوم التالي.', 'en': 'One slip does not erase months of progress; return immediately the next day.', 'fr': "Un écart n'efface pas des mois de progrès ; reprenez dès le lendemain."},
      {'ar': 'ساعد شخصاً يحاول ترك العادة نفسها، فتعليم الغير يثبّتك.', 'en': 'Help someone trying to quit the same habit; teaching cements your own change.', 'fr': "Aidez quelqu'un qui essaie d'arrêter la même habitude ; enseigner consolide votre changement."},
    ],
  ),
];

const List<HabitStage> kBuildStages = [
  HabitStage(
    minDays: 0,
    name: {'ar': 'التأسيس', 'en': 'Foundation', 'fr': 'Fondation'},
    focus: {
      'ar': 'ابدأ صغيراً جداً واربط العادة بموعد أو فعل ثابت في يومك.',
      'en': 'Start tiny, and anchor the habit to a fixed time or existing routine in your day.',
      'fr': "Commencez tout petit et ancrez l'habitude à un moment ou un geste fixe de votre journée."
    },
    tips: [
      {'ar': 'اجعل أول خطوة أصغر من أن تُرفض: دقيقتان تكفيان الآن.', 'en': 'Make the first step too small to refuse: two minutes is enough for now.', 'fr': 'Rendez le premier pas trop petit pour être refusé : deux minutes suffisent.'},
      {'ar': 'اربطها بعادة قائمة: «بعد صلاة الفجر أفعل كذا».', 'en': 'Stack it on an existing habit: "right after Fajr prayer, I do X".', 'fr': "Empilez-la sur une habitude existante : « juste après la prière du Fajr, je fais X »."},
      {'ar': 'جهّز أدواتك من الليلة السابقة حتى يسهل البدء.', 'en': 'Prepare your tools the night before so starting is effortless.', 'fr': 'Préparez vos affaires la veille pour que démarrer soit sans effort.'},
    ],
  ),
  HabitStage(
    minDays: 7,
    name: {'ar': 'الانتظام', 'en': 'Consistency', 'fr': 'Régularité'},
    focus: {
      'ar': 'العبرة الآن بالمواظبة لا بالكمية: لا تفوّت يومين متتاليين أبداً.',
      'en': 'What counts now is showing up, not volume: never miss two days in a row.',
      'fr': "Ce qui compte maintenant, c'est la constance : ne manquez jamais deux jours de suite."
    },
    tips: [
      {'ar': 'إن فاتك يوم فعوّضه في اليوم التالي مهما صغُر الأداء.', 'en': 'If you miss a day, return the very next day, however small the effort.', 'fr': 'Si vous manquez un jour, revenez dès le lendemain, même a minima.'},
      {'ar': 'ثبّت وقت التذكير الأنسب لك من صفحة العادات.', 'en': 'Tune your reminder times from the Habits page to what truly fits your day.', 'fr': "Ajustez vos rappels depuis la page Habitudes selon votre journée."},
      {'ar': 'تتبّع سلسلتك يومياً، فرؤية التتابع دافع قوي.', 'en': 'Watch your streak daily; seeing the chain grow is powerful motivation.', 'fr': 'Suivez votre série chaque jour ; voir la chaîne grandir motive énormément.'},
    ],
  ),
  HabitStage(
    minDays: 30,
    name: {'ar': 'الترسيخ', 'en': 'Consolidation', 'fr': 'Consolidation'},
    focus: {
      'ar': 'درعك الفضي معك، فارفع الجرعة بلطف: جودة أعلى أو مدة أطول قليلاً.',
      'en': 'Silver shield earned. Gently raise the dose: a bit more quality or a bit more time.',
      'fr': "Bouclier d'argent obtenu. Augmentez doucement : un peu plus de qualité ou de durée."
    },
    tips: [
      {'ar': 'زد الأداء زيادة لا تتجاوز عُشر ما اعتدته كل أسبوع.', 'en': 'Increase by no more than ten percent of your usual amount each week.', 'fr': "N'augmentez pas de plus de dix pour cent par semaine."},
      {'ar': 'حسّن الجودة: خشوع أعمق، قراءة أوعى، أداء أتقن.', 'en': 'Refine quality: deeper presence, more mindful reading, better form.', 'fr': 'Améliorez la qualité : plus de présence, de conscience, de précision.'},
      {'ar': 'راجع إحصاءاتك أسبوعياً ولاحظ أثر العادة في يومك.', 'en': 'Review your stats weekly and notice the habit\'s effect on your day.', 'fr': "Consultez vos statistiques chaque semaine et observez l'effet de l'habitude."},
    ],
  ),
  HabitStage(
    minDays: 60,
    name: {'ar': 'عادة راسخة', 'en': 'Established habit', 'fr': 'Habitude ancrée'},
    focus: {
      'ar': 'صارت العادة جزءاً من هويتك، فاحمها من الفتور وأعن غيرك عليها.',
      'en': 'The habit is part of your identity now; protect it from plateaus and help others build it.',
      'fr': "L'habitude fait partie de votre identité ; protégez-la de la lassitude et aidez les autres."
    },
    tips: [
      {'ar': 'قل «أنا صاحب هذه العادة» فالهوية أقوى من الحماس.', 'en': 'Say "I am the kind of person who does this"; identity outlasts motivation.', 'fr': "Dites « je suis ce genre de personne » ; l'identité dure plus que la motivation."},
      {'ar': 'جدّد العادة بصورة أعمق أو رفقة صالحة تعينك عليها.', 'en': 'Renew the habit with more depth, or good company that keeps you at it.', 'fr': "Renouvelez l'habitude en profondeur ou avec une bonne compagnie."},
      {'ar': 'ادعُ غيرك إليها، فالدال على الخير كفاعله.', 'en': 'Invite others to it; guiding someone to good is like doing it yourself.', 'fr': 'Invitez les autres ; guider vers le bien équivaut à le faire.'},
    ],
  ),
];

/// The stage the user is in right now for a habit of [track] with [streak].
HabitStage stageForStreak(String track, int streak) {
  final stages = track == 'break' ? kBreakStages : kBuildStages;
  HabitStage current = stages.first;
  for (final s in stages) {
    if (streak >= s.minDays) current = s;
  }
  return current;
}

/// 1-based index of the current stage (for "المرحلة 2 من 4").
int stageIndexForStreak(String track, int streak) {
  final stages = track == 'break' ? kBreakStages : kBuildStages;
  var idx = 1;
  for (var i = 0; i < stages.length; i++) {
    if (streak >= stages[i].minDays) idx = i + 1;
  }
  return idx;
}

/// The streak day at which the NEXT stage begins, or null if at the last stage.
int? nextStageAt(String track, int streak) {
  final stages = track == 'break' ? kBreakStages : kBuildStages;
  for (final s in stages) {
    if (streak < s.minDays) return s.minDays;
  }
  return null;
}
