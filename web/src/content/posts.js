// Blog posts (SEO engine), trilingual. Each post renders with Article + FAQPage
// JSON-LD. Dates are ISO strings. Keep H1 = the search query for featured snippets.

export const POSTS = [
  {
    slug: 'break-a-bad-habit-hrt',
    date: '2026-06-20',
    category: 'break',
    title: {
      ar: 'إزاي تبطّل عادة سيّئة؟ دليل علمي بمنهج HRT',
      en: 'How to break a bad habit: a science-based HRT guide',
      fr: 'Comment arrêter une mauvaise habitude : guide HRT',
    },
    description: {
      ar: 'خطوات عملية لكسر عادة سيّئة بمنهج Habit Reversal Training: الوعي، الاستجابة البديلة، التحكم في البيئة، والتثبيت.',
      en: 'Practical steps to break a bad habit with Habit Reversal Training: awareness, competing response, environment control, maintenance.',
      fr: 'Étapes concrètes pour arrêter une mauvaise habitude avec le Habit Reversal Training.',
    },
    intro: {
      ar: 'كسر العادة السيّئة مش مسألة "إرادة" بس — فيه منهج علمي اسمه Habit Reversal Training (HRT) أثبت فعاليته. الفكرة باختصار: تبني وعياً بالعادة، تستبدلها بسلوك بديل، تعدّل بيئتك، وتثبّت المكسب.',
      en: 'Breaking a bad habit is not only about willpower — there is an evidence-based method called Habit Reversal Training (HRT). In short: build awareness, replace the habit with a competing response, adjust your environment, and lock in the gains.',
      fr: "Arrêter une mauvaise habitude n'est pas qu'une question de volonté — il existe une méthode éprouvée : le Habit Reversal Training (HRT).",
    },
    sections: {
      ar: [
        { h: '١) ابنِ الوعي أولاً', p: 'سجّل كل مرة بتحصل فيها العادة: الوقت، المكان، الشعور قبلها. الوعي وحده بيقلّل التكرار.' },
        { h: '٢) الاستجابة التنافسية', p: 'اختَر سلوكاً بديلاً يصعب معه تنفيذ العادة (مثلاً تشبيك اليدين دقيقة). طبّقه لحظة الرغبة.' },
        { h: '٣) التحكم في البيئة', p: 'قلّل المحفّزات حولك. لو المحفّز الموبايل قبل النوم، أبعده عن السرير.' },
        { h: '٤) التثبيت', p: 'راجع أسبوعياً ما الذي نفع، وكافئ نفسك على الأيام النظيفة. الاستمرار يبني دائرة عصبية جديدة.' },
        { h: 'الجانب الإيماني', p: 'جدّد النية، استعن بالله مع الأخذ بالأسباب، والصبر مفتاح الفرج. (لأي مسألة شرعية راجع إسلام ويب وأهل العلم.)' },
      ],
      en: [
        { h: '1) Build awareness', p: 'Log every time the habit happens: time, place, and the feeling before it. Awareness alone reduces frequency.' },
        { h: '2) Competing response', p: 'Pick an alternative behavior that blocks the habit, and apply it at the moment of urge.' },
        { h: '3) Environment control', p: 'Reduce triggers around you. If the trigger is the phone before bed, keep it away from your bed.' },
        { h: '4) Maintenance', p: 'Review weekly what worked, and reward your clean days. Consistency rewires the brain.' },
      ],
      fr: [
        { h: '1) Construire la conscience', p: "Notez chaque occurrence : l'heure, le lieu, l'émotion. La conscience seule réduit la fréquence." },
        { h: '2) Réponse alternative', p: "Choisissez un comportement qui bloque l'habitude, au moment de l'envie." },
        { h: '3) Contrôle de l\'environnement', p: 'Réduisez les déclencheurs autour de vous.' },
        { h: '4) Maintien', p: 'Révisez chaque semaine ce qui fonctionne et récompensez vos jours réussis.' },
      ],
    },
    faq: {
      ar: [
        { q: 'قد إيه ياخد وقت أبطّل عادة؟', a: 'يختلف من شخص لآخر، لكن الاستمرار المنتظم لأسابيع (عادة 6–8) يحدث فرقاً واضحاً.' },
        { q: 'لو تعثّرت أعمل إيه؟', a: 'التعثّر طبيعي وجزء من الطريق. ارجع فوراً لليوم التالي بدون جلد للذات.' },
      ],
      en: [
        { q: 'How long does it take to break a habit?', a: 'It varies, but consistent practice over several weeks (often 6–8) makes a clear difference.' },
        { q: 'What if I slip?', a: 'Slips are normal. Get back on track the next day without self-blame.' },
      ],
      fr: [
        { q: "Combien de temps pour arrêter une habitude ?", a: 'Cela varie, mais une pratique régulière sur plusieurs semaines (souvent 6 à 8) fait une nette différence.' },
        { q: 'Et si je rechute ?', a: 'Les rechutes sont normales. Reprenez dès le lendemain, sans culpabiliser.' },
      ],
    },
  },
  {
    slug: 'build-a-new-habit',
    date: '2026-06-22',
    category: 'build',
    title: {
      ar: 'إزاي تبني عادة جديدة وتثبت عليها؟',
      en: 'How to build a new habit that sticks',
      fr: 'Comment bâtir une nouvelle habitude durable',
    },
    description: {
      ar: 'طريقة عملية لبناء عادة جديدة وتثبيتها: نيّة واضحة، بداية صغيرة، سلسلة يومية، وتذكير لطيف.',
      en: 'A practical way to build and keep a new habit: a clear why, a tiny start, a daily streak, and a gentle reminder.',
      fr: 'Une méthode concrète pour bâtir et garder une nouvelle habitude.',
    },
    intro: {
      ar: 'العادة الجديدة بتثبت لما تبقى سهلة، متكرّرة، ومرتبطة بمكافأة. ابدأ صغير جداً، وكرّر يومياً، وخلّي عندك سلسلة (Streak) تحافظ عليها.',
      en: 'A new habit sticks when it is easy, repeated, and tied to a reward. Start tiny, repeat daily, and keep a streak going.',
      fr: "Une nouvelle habitude s'ancre quand elle est facile, répétée et liée à une récompense.",
    },
    sections: {
      ar: [
        { h: 'حدّد "ليه"', p: 'دافعك الواضح هو وقودك في أيام الفتور. اكتبه وراجعه.' },
        { h: 'ابدأ صغير', p: 'صفحة واحدة، دقيقتان ذكر، تمرين قصير. الصغر يقلّل المقاومة.' },
        { h: 'سلسلة يومية', p: 'كل يوم تكمّله يبني سلسلتك. متكسرش السلسلة، ولو كسرتها ارجع فوراً.' },
        { h: 'تذكير وارتباط', p: 'اربط العادة بعادة قائمة (بعد صلاة الفجر، بعد القهوة) وفعّل تذكيراً لطيفاً.' },
      ],
      en: [
        { h: 'Define your why', p: 'A clear motivation is your fuel on low days. Write it and revisit it.' },
        { h: 'Start tiny', p: 'One page, two minutes, a short set. Small lowers resistance.' },
        { h: 'Daily streak', p: 'Each completed day builds your streak. If it breaks, restart immediately.' },
        { h: 'Cue & reminder', p: 'Anchor the habit to an existing one and set a gentle reminder.' },
      ],
      fr: [
        { h: 'Définissez votre pourquoi', p: 'Une motivation claire est votre carburant les jours difficiles.' },
        { h: 'Commencez petit', p: 'Une page, deux minutes. Le petit réduit la résistance.' },
        { h: 'Série quotidienne', p: 'Chaque jour complété construit votre série. Si elle casse, reprenez aussitôt.' },
        { h: 'Déclencheur et rappel', p: 'Ancrez la nouvelle habitude à une habitude existante.' },
      ],
    },
    faq: {
      ar: [
        { q: 'أبدأ بعادة واحدة ولا أكتر؟', a: 'ابدأ بواحدة حتى تثبت، ثم أضف غيرها. التركيز يزيد فرص النجاح.' },
      ],
      en: [
        { q: 'One habit or several?', a: 'Start with one until it sticks, then add more. Focus increases success.' },
      ],
      fr: [
        { q: 'Une habitude ou plusieurs ?', a: 'Commencez par une seule, puis ajoutez-en. La concentration augmente la réussite.' },
      ],
    },
  },
  {
    slug: '21-day-habit-myth',
    date: '2026-06-24',
    category: 'build',
    title: {
      ar: 'خرافة الـ ٢١ يوم لبناء العادة: الحقيقة العلمية',
      en: 'The 21-day habit myth: what science really says',
      fr: 'Le mythe des 21 jours : ce que dit vraiment la science',
    },
    description: {
      ar: 'هل العادة بتتبني في ٢١ يوم فعلاً؟ نراجع الدراسات ونوضّح المدة الواقعية وكيف تتعامل معها.',
      en: 'Do habits really form in 21 days? We review the research and the realistic timeline.',
      fr: 'Les habitudes se forment-elles vraiment en 21 jours ? Nous passons en revue la recherche.',
    },
    intro: {
      ar: 'رقم "٢١ يوم" مشهور لكنه غير دقيق. دراسات حديثة وجدت أن متوسط تكوين العادة أقرب لـ ٦٦ يوماً ويختلف كثيراً حسب صعوبة العادة.',
      en: 'The "21 days" figure is popular but inaccurate. Research found the average is closer to 66 days and varies widely by habit difficulty.',
      fr: "Le chiffre « 21 jours » est populaire mais inexact. La recherche situe la moyenne plutôt vers 66 jours.",
    },
    sections: {
      ar: [
        { h: 'من أين جاء الرقم؟', p: 'من ملاحظة قديمة عن المرضى بعد الجراحة، أُسيء تعميمها على كل العادات.' },
        { h: 'الرقم الواقعي', p: 'المتوسط ~٦٦ يوماً، ويتراوح من أسابيع لشهور. لا تقلق لو أخذت وقتاً أطول.' },
        { h: 'الخلاصة العملية', p: 'ركّز على الاستمرار لا على رقم سحري. كل يوم نظيف مكسب، والتعثّر لا يصفّر تقدّمك.' },
      ],
      en: [
        { h: 'Where the number came from', p: 'From an old observation about post-surgery patients, over-generalized to all habits.' },
        { h: 'The realistic number', p: 'The average is ~66 days, ranging from weeks to months. Do not worry if it takes longer.' },
        { h: 'Practical takeaway', p: 'Focus on consistency, not a magic number. Every clean day counts, and a slip does not reset your progress.' },
      ],
      fr: [
        { h: "D'où vient ce chiffre", p: "D'une vieille observation sur des patients, sur-généralisée." },
        { h: 'Le chiffre réaliste', p: 'La moyenne est de ~66 jours, de quelques semaines à plusieurs mois.' },
        { h: 'À retenir', p: 'Concentrez-vous sur la régularité, pas sur un chiffre magique.' },
      ],
    },
    faq: {
      ar: [
        { q: 'يعني الـ ٢١ يوم غلط تماماً؟', a: 'ليست قاعدة. بعض العادات البسيطة تثبت بسرعة، والأصعب تحتاج أطول.' },
      ],
      en: [
        { q: 'So 21 days is completely wrong?', a: 'It is not a rule. Simple habits may stick fast; harder ones take longer.' },
      ],
      fr: [
        { q: 'Donc 21 jours est faux ?', a: "Ce n'est pas une règle. Les habitudes simples s'ancrent vite ; les difficiles, plus lentement." },
      ],
    },
  },
];

export function postsForLocale() {
  return [...POSTS].sort((a, b) => (a.date < b.date ? 1 : -1));
}
