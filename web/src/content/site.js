// Trilingual content for the Awwad marketing site.
// Aligned with docs/content-values-guideline.md. The Flutter app is the product;
// this static site carries SEO + the store-required legal pages.
// Arabic copy is written in Modern Standard Arabic (fusha). No em-dashes anywhere.

export const LOCALES = ['ar', 'en', 'fr'];
export const DIR = { ar: 'rtl', en: 'ltr', fr: 'ltr' };
export const LANG_NAME = { ar: 'العربية', en: 'English', fr: 'Français' };
export const OG_LOCALE = { ar: 'ar_AR', en: 'en_US', fr: 'fr_FR' };

// Page keys -> URL slug (home = '').
export const PAGES = {
  home: '',
  'break-habit': 'break-habit',
  'build-habit': 'build-habit',
  privacy: 'privacy',
  terms: 'terms',
  'delete-account': 'delete-account',
};

export const CREDIT_URL = 'https://www.facebook.com/MoradArafaOfficial/';
// The web version of the app (same product as the native app).
// When the apex domain is purchased, point this at app.<domain> instead.
export const WEB_APP_URL = 'https://moradarafa1.github.io/app/';
// Recommended help channel for the secret-habit track (واعي on YouTube).
export const WAAI_URL = 'https://www.youtube.com/channel/UCubgpaK2N08IKa1biOQPL1Q';
// App store links. Flip androidLive/iosLive to true once each app is PUBLISHED
// (and fill the real iOS id). While false, download CTAs route to the web app
// with a "coming soon" label so visitors never hit a dead store page.
export const STORE = {
  android: 'https://play.google.com/store/apps/details?id=com.awwad.awwad',
  androidLive: false,
  ios: 'https://apps.apple.com/app/awwad/id000000000',
  iosLive: false,
};

export const t = {
  ar: {
    brand: 'عوّاد',
    slogan: 'رفيقُ مَن زانَ عُمرَهُ، وحَسُنَ عملُهُ',
    nav: { home: 'الرئيسية', break: 'كسر عادة', build: 'بناء عادة', privacy: 'الخصوصية', terms: 'الشروط', login: 'تسجيل الدخول', account: 'حسابي' },
    footer_rights: 'جميع الحقوق محفوظة',
    footer_disclaimer: 'عوّاد أداة دعمٍ سلوكيٍّ ومتابعة، وليس بديلاً عن الاستشارة الطبية أو النفسية المتخصّصة.',
    footer_volunteer: 'هذا الموقع جهدٌ ذاتيٌّ تطوّعيّ، غير هادفٍ للرّبح.',
    cta_download: 'حمِّل التطبيق',
    cta_or: 'أو',
    cta_webversion: 'جرِّب إصدار الويب',
    dl_choose: 'اختر نظام هاتفك',
    dl_android: 'أندرويد',
    dl_ios: 'آيفون (iOS)',
    dl_soon: 'قريباً على المتاجر، استخدم إصدار الويب الآن',
    pages: {
      home: {
        title: 'عوّاد | تخلَّص من عادةٍ سيّئة أو ابنِ عادةً جديدة',
        description: 'تطبيقٌ عربيّ يساعدك على التخلُّص من عادةٍ سيّئة أو بناء عادةٍ جديدة، بمنهجٍ علميّ (HRT) وروحٍ داعمةٍ متوافقةٍ مع قيمك. مجّانيّ، يحفظ خصوصيّتك، ويعمل دون اتصال بالإنترنت.',
        h1: 'لليوم فقط، خطوة واحدة لنتغير',
        sub: 'رفيقك اليوميّ لتغيير العادات: خطوةٌ واحدةٌ كلّ يوم، بمنهجٍ علميٍّ وروحٍ داعمة.',
        tracks: [
          { icon: '🚭', title: 'كسر عادة', desc: 'التدخين، قضم الأظافر، التسويف، الهاتف، السهر، الغضب... نتعامل معها بوعيٍ وبمنهج التدريب على عكس العادة (HRT).', href: 'break-habit' },
          { icon: '🌱', title: 'بناء عادة جديدة', desc: 'الصلاة في وقتها، وِرد القرآن، الصلاة على النبي، بر الوالدين، الرياضة، القراءة... نثبِّت العادة الحسنة بالسلاسل والتحفيز.', href: 'build-habit' },
        ],
        features: [
          { icon: '🔒', h: 'خصوصيّةٌ كاملة', p: 'ملفّك خاصٌّ بك وحدك، لا يراه أحد. التسجيل بالاسم والبريد وكلمة المرور فقط.' },
          { icon: '🏅', h: 'دروعٌ وتحفيز', p: 'كلّما أكملت أياماً كسبت درعاً: فضّيٌّ عند ثلاثين يوماً، وذهبيٌّ عند ستّين، وماسيٌّ عند تسعين.' },
          { icon: '🌙', h: 'متوافقٌ مع قيمك', p: 'محتوًى يحثّ على الخير، مع قوالب عاداتٍ إسلاميةٍ اختيارية.' },
          { icon: '📶', h: 'يعمل دون اتصال', p: 'سجِّل يومك في أيِّ وقت، ويتزامن عند عودة الاتصال.' },
        ],
        sectionTitle: 'مساران، والطريق طريقك أنت',
        featuresTitle: 'مصمَّمٌ كي تنجح',
      },
      'break-habit': {
        title: 'كسر عادةٍ سيّئة بمنهج HRT | عوّاد',
        description: 'تخلَّص من عادةٍ سيّئة (التدخين، قضم الأظافر، متلازمة نتف الشعر، إدمان الهاتف، العادة السرية) بمنهج التدريب على عكس العادة: وعيٌ ثمّ استجابةٌ بديلة ثمّ تحكُّمٌ في البيئة ثمّ تثبيت.',
        h1: 'تخلَّص من العادة السيّئة بمنهجٍ علميّ',
        intro: 'التدريب على عكس العادة (Habit Reversal Training) منهجٌ معتمدٌ لتغيير العادات القهرية، ويطبّقه عوّاد معك على أربع مراحل واضحة، ويدعم عاداتٍ متعدّدة في وقتٍ واحد (حتّى ثلاث عاداتٍ للكسر وثلاثٍ للبناء) مع إمكانية التنقّل بينها.',
        blocks: [
          { h: 'أوّلاً: الوعي', p: 'ترصد وتسجّل متى وأين ولماذا تحدث العادة، وهي الخطوة الأولى وأهمّها.' },
          { h: 'ثانياً: الاستجابة التنافسية', p: 'تتدرّب على سلوكٍ بديلٍ يمنع العادة في لحظة الرغبة.' },
          { h: 'ثالثاً: التحكُّم في البيئة', p: 'تعدّل محيطك كي تقلِّل المحفّزات.' },
          { h: 'رابعاً: التثبيت', p: 'تراجع وتثبّت ما ينفع، وتحافظ على تقدّمك.' },
        ],
        resource: {
          h: 'دعمٌ خاصٌّ لمن يكسر العادة السرية',
          p: 'لمن اختار التخلّص من العادة السرية، نوصي عند اشتداد الرغبة بقضاء نحو خمس عشرة دقيقة على قناة واعي على يوتيوب بدلاً من الاستسلام، فهي محتوًى توعويٌّ يعينك على الفهم والثبات. والتطبيق يتابع تقدّمك بستر، ويقترح بدائل عملية لكلّ لحظة رغبة.',
          cta: 'افتح قناة واعي على يوتيوب',
          url: WAAI_URL,
        },
      },
      'build-habit': {
        title: 'بناء عادةٍ جديدة وتثبيتها | عوّاد',
        description: 'ابنِ عادةً جديدة (الصلاة، القرآن، الرياضة، القراءة) وثبّتها بنظام السلاسل (Streak) والتذكير اليوميّ والتحفيز، مع قوالب عاداتٍ إسلاميةٍ اختيارية.',
        h1: 'ابنِ عادتك الجديدة وثبّتها',
        intro: 'تترسّخ العادة الجديدة بالتكرار والتشجيع، ويساعدك عوّاد على الحفاظ على سلسلتك يوماً بعد يوم.',
        blocks: [
          { h: 'حدِّد نيّتك ودافعك', p: 'اكتب لماذا تريد هذه العادة، فذلك يُذكّرك في أوقات الفتور.' },
          { h: 'سلسلةٌ يومية (Streak)', p: 'كلُّ يومٍ تُكمله يبني سلسلتك ويقرّبك من الدرع التالي.' },
          { h: 'تذكيرٌ لطيف', p: 'تذكيرٌ يوميٌّ في وقتٍ تختاره، يراعي أوقات الصلاة.' },
          { h: 'قوالب جاهزة', p: 'الصلاة في وقتها، ووِرد القرآن، والأذكار، والرياضة، والقراءة... أو عادتك الخاصة.' },
        ],
      },
      privacy: {
        title: 'سياسة الخصوصية | عوّاد',
        description: 'سياسة خصوصية عوّاد: ما الذي نجمعه، وكيف نستخدمه، وحقوقك في بياناتك.',
        h1: 'سياسة الخصوصية',
        blocks: [
          { h: 'البيانات التي نجمعها', p: 'بيانات الحساب (الاسم، والبريد، وكلمة مرورٍ مشفّرة)، وبيانات متابعتك للعادة التي تُدخلها بنفسك، وبيانات استخدامٍ مجهّلة لتحسين التجربة. والاستبيان في بداية الاستخدام اختياريٌّ بالكامل.' },
          { h: 'كيف نستخدمها', p: 'لتشغيل حسابك ومزامنة بياناتك عبر أجهزتك، ولفهم التجربة وتحسينها. لا نبيع بياناتك ولا نشاركها لأغراضٍ إعلانية.' },
          { h: 'بيانات البحث الاختيارية', p: 'إذا وافقت على الاستبيان، فقد يراجع فريقنا إجاباتك (بشكلٍ مجمّعٍ أو فرديّ) لأغراض البحث وتحسين المنتج. ويمكنك تجاوز الاستبيان دون أيِّ تأثيرٍ على استخدامك.' },
          { h: 'مزوّدو الخدمة', p: 'نستخدم Supabase لتخزين البيانات والمصادقة، وFirebase Cloud Messaging للإشعارات. وتخضع هذه الخدمات لسياساتها الخاصة، ونقتصر على الحدّ اللازم.' },
          { h: 'حقوقك', p: 'يمكنك تصدير بياناتك أو حذف حسابك وكلّ بياناتك في أيِّ وقت، من داخل التطبيق أو عبر صفحة حذف الحساب.' },
          { h: 'تواصل', p: 'لأيِّ استفسارٍ حول الخصوصية: moradarafa600@gmail.com' },
        ],
      },
      terms: {
        title: 'الشروط والأحكام | عوّاد',
        description: 'شروط استخدام تطبيق عوّاد.',
        h1: 'الشروط والأحكام',
        blocks: [
          { h: 'طبيعة الخدمة', p: 'عوّاد أداة دعمٍ سلوكيٍّ ومتابعةٍ ذاتية، وليس خدمةً طبيةً أو نفسية، ولا يُعدّ بديلاً عن استشارة المختصّ.' },
          { h: 'الاستخدام', p: 'أنت مسؤولٌ عن سرّية حسابك ودقّة بياناتك، ويُمنع إساءة استخدام الخدمة.' },
          { h: 'مجّانيٌّ الآن', p: 'الخدمة مجّانيةٌ حالياً وغير هادفةٍ للرّبح. وقد نُضيف باقات اشتراكٍ اختياريةً مستقبلاً، وسنُعلمك قبل أيِّ تغيير.' },
          { h: 'المحتوى الديني', p: 'المحتوى التحفيزيّ للتذكير فقط. وأيُّ إشارةٍ إلى مسألةٍ شرعيةٍ مصدرها موقع إسلام ويب، والرجوع إلى أهل العلم للفتوى.' },
          { h: 'إخلاء المسؤولية', p: 'نقدّم الخدمة كما هي دون ضمانات، ولا نتحمّل مسؤولية أيِّ قرارٍ تتّخذه بناءً على التطبيق.' },
        ],
      },
      'delete-account': {
        title: 'حذف الحساب | عوّاد',
        description: 'كيفية حذف حسابك وبياناتك في عوّاد نهائياً.',
        h1: 'حذف الحساب والبيانات',
        blocks: [
          { h: 'من داخل التطبيق', p: 'افتح: الإعدادات ثمّ الحساب ثمّ حذف الحساب. وسيُحذف حسابك وكلّ بياناتك (العادات، والتسجيلات، والدروع) نهائياً دون إمكانية التراجع.' },
          { h: 'دون تسجيل دخول', p: 'إن لم تعد تستطيع الدخول، فأرسل طلباً من بريدك المسجّل إلى moradarafa600@gmail.com بعنوان «حذف حساب»، وسنتحقّق من هويتك عبر بريدك ثمّ نحذف كلّ بياناتك خلال مدّةٍ قصيرة.' },
          { h: 'ما الذي يُحذف', p: 'كلّ بياناتك الشخصية، وبيانات المتابعة، والأجهزة الموثوقة، وسجلّات الاستخدام المرتبطة بك.' },
        ],
      },
    },
  },

  en: {
    brand: 'Awwad',
    slogan: 'Awwad: always for the better.',
    nav: { home: 'Home', break: 'Break a habit', build: 'Build a habit', privacy: 'Privacy', terms: 'Terms', login: 'Sign in', account: 'My account' },
    footer_rights: 'All rights reserved',
    footer_disclaimer: 'Awwad is a behavioral support and tracking tool, not a substitute for professional medical or psychological advice.',
    footer_volunteer: 'This site is a self-funded, volunteer effort, not for profit.',
    cta_download: 'Get the app',
    cta_or: 'or',
    cta_webversion: 'Try the web version',
    dl_choose: 'Choose your platform',
    dl_android: 'Android',
    dl_ios: 'iPhone (iOS)',
    dl_soon: 'Coming soon to the stores, use the web version for now',
    pages: {
      home: {
        title: 'Awwad | Break a bad habit or build a new one',
        description: 'An app that helps you break a bad habit or build a new one with an evidence-based method (HRT) and a supportive, values-aligned tone. Free, private, works offline.',
        h1: 'Just for today, one step to change',
        sub: 'Your daily companion for changing habits: one step a day, with a proven method and a supportive spirit.',
        tracks: [
          { icon: '🚭', title: 'Break a habit', desc: 'Smoking, nail-biting, procrastination, phone, late nights, anger... handled with awareness and Habit Reversal Training.', href: 'break-habit' },
          { icon: '🌱', title: 'Build a new habit', desc: 'Prayer on time, daily Qur\'an, salawat, honoring parents, exercise, reading... make the good habit stick with streaks and motivation.', href: 'build-habit' },
        ],
        features: [
          { icon: '🔒', h: 'Fully private', p: 'Your profile is yours alone. Sign up with just name, email and password.' },
          { icon: '🏅', h: 'Badges & motivation', p: 'Earn shields as you progress: silver at 30, gold at 60, diamond at 90 days.' },
          { icon: '🌙', h: 'Values-aligned', p: 'Encouraging content, with optional faith-based habit templates.' },
          { icon: '📶', h: 'Works offline', p: 'Log your day anytime; it syncs when you reconnect.' },
        ],
        sectionTitle: 'Two tracks, your path',
        featuresTitle: 'Built so you succeed',
      },
      'break-habit': {
        title: 'Break a bad habit: the HRT method | Awwad',
        description: 'Break a bad habit (smoking, nail-biting, trichotillomania, phone addiction, compulsive masturbation) with Habit Reversal Training: awareness, competing response, environment control, then maintenance.',
        h1: 'Break the habit with a proven method',
        intro: 'Habit Reversal Training is an evidence-based method for changing compulsive habits. Awwad walks you through 4 clear phases, and supports several habits at once (up to 3 to break and 3 to build) that you can switch between.',
        blocks: [
          { h: '1) Awareness', p: 'Notice and log when, where and why the habit happens, the first and most important step.' },
          { h: '2) Competing response', p: 'Practice an alternative behavior that blocks the habit at the moment of urge.' },
          { h: '3) Environment control', p: 'Adjust your surroundings to reduce triggers.' },
          { h: '4) Maintenance', p: 'Review, keep what works, and protect your progress.' },
        ],
        resource: {
          h: 'Extra support for compulsive masturbation',
          p: 'If you chose to break this habit, when the urge hits we recommend spending about 15 minutes on the Waai YouTube channel instead of giving in. It is awareness content that helps you understand and stay firm. The app tracks your progress discreetly and suggests practical alternatives for each urge.',
          cta: 'Open the Waai channel on YouTube',
          url: WAAI_URL,
        },
      },
      'build-habit': {
        title: 'Build a new habit that sticks | Awwad',
        description: 'Build a new habit (prayer, reading, exercise) and make it stick with streaks, daily reminders and motivation, plus optional faith-based templates.',
        h1: 'Build your new habit and make it stick',
        intro: 'New habits stick through repetition and encouragement. Awwad helps you protect your streak day after day.',
        blocks: [
          { h: 'Set your why', p: 'Write down why you want this habit; it reminds you when motivation dips.' },
          { h: 'Daily streak', p: 'Each completed day builds your streak and brings the next badge closer.' },
          { h: 'Gentle reminder', p: 'A daily reminder at a time you choose, mindful of prayer times.' },
          { h: 'Ready templates', p: 'Prayer, reading, exercise, dhikr... or your own custom habit.' },
        ],
      },
      privacy: {
        title: 'Privacy Policy | Awwad',
        description: 'Awwad privacy policy: what we collect, how we use it, and your rights.',
        h1: 'Privacy Policy',
        blocks: [
          { h: 'Data we collect', p: 'Account data (name, email, hashed password), the habit-tracking data you enter, and anonymized usage data to improve the experience. The optional onboarding survey is entirely voluntary.' },
          { h: 'How we use it', p: 'To run your account and sync data across devices, and to understand and improve the experience. We never sell your data or share it for advertising.' },
          { h: 'Optional research data', p: 'If you consent to the survey, our team may review your answers (aggregated or individually) for research and product improvement. You can skip the survey with no impact on your use.' },
          { h: 'Service providers', p: 'We use Supabase for storage and authentication, and Firebase Cloud Messaging for notifications, limited to what is necessary.' },
          { h: 'Your rights', p: 'You can export your data or delete your account and all data at any time, from the app or via the account-deletion page.' },
          { h: 'Contact', p: 'For privacy questions: moradarafa600@gmail.com' },
        ],
      },
      terms: {
        title: 'Terms of Service | Awwad',
        description: 'Terms of use for the Awwad app.',
        h1: 'Terms of Service',
        blocks: [
          { h: 'Nature of the service', p: 'Awwad is a behavioral self-help and tracking tool, not a medical or psychological service, and not a substitute for a professional.' },
          { h: 'Use', p: 'You are responsible for the confidentiality of your account and the accuracy of your data. Misuse is prohibited.' },
          { h: 'Free for now', p: 'The service is currently free and not-for-profit. Optional subscriptions may be added later; we will notify you before any change.' },
          { h: 'Religious content', p: 'Motivational content is for reminder only. Any reference to a religious ruling is sourced from IslamWeb; consult qualified scholars for fatwa.' },
          { h: 'Disclaimer', p: 'The service is provided as is, without warranty. We are not liable for decisions you make based on the app.' },
        ],
      },
      'delete-account': {
        title: 'Delete your account | Awwad',
        description: 'How to permanently delete your Awwad account and data.',
        h1: 'Delete account and data',
        blocks: [
          { h: 'From inside the app', p: 'Open: Settings, then Account, then Delete account. Your account and all data (habits, logs, badges) are permanently deleted and cannot be recovered.' },
          { h: 'Without signing in', p: 'If you can no longer sign in, email a request from your registered address to moradarafa600@gmail.com with subject "Delete account". We verify you via your email, then delete all your data shortly after.' },
          { h: 'What is deleted', p: 'All your personal data, tracking data, trusted devices, and usage records linked to you.' },
        ],
      },
    },
  },

  fr: {
    brand: 'Awwad',
    slogan: 'Awwad : toujours pour le meilleur.',
    nav: { home: 'Accueil', break: 'Arrêter une habitude', build: 'Bâtir une habitude', privacy: 'Confidentialité', terms: 'Conditions', login: 'Se connecter', account: 'Mon compte' },
    footer_rights: 'Tous droits réservés',
    footer_disclaimer: "Awwad est un outil de soutien comportemental et de suivi, et non un substitut à un avis médical ou psychologique professionnel.",
    footer_volunteer: 'Ce site est un effort bénévole et personnel, à but non lucratif.',
    cta_download: "Obtenir l'app",
    cta_or: 'ou',
    cta_webversion: 'Essayer la version web',
    dl_choose: 'Choisissez votre plateforme',
    dl_android: 'Android',
    dl_ios: 'iPhone (iOS)',
    dl_soon: 'Bientôt sur les stores, utilisez la version web en attendant',
    pages: {
      home: {
        title: 'Awwad | Arrêtez une mauvaise habitude ou bâtissez-en une nouvelle',
        description: "Une app qui vous aide à arrêter une mauvaise habitude ou à en bâtir une nouvelle avec une méthode éprouvée (HRT) et un ton bienveillant aligné sur vos valeurs. Gratuit, privé, hors ligne.",
        h1: "Juste pour aujourd'hui, un pas pour changer",
        sub: "Votre compagnon quotidien pour changer vos habitudes : un pas par jour, avec une méthode éprouvée.",
        tracks: [
          { icon: '🚭', title: 'Arrêter une habitude', desc: 'Tabac, ongles rongés, procrastination, téléphone, veilles tardives, colère... avec la méthode Habit Reversal Training.', href: 'break-habit' },
          { icon: '🌱', title: 'Bâtir une habitude', desc: 'Prière à l\'heure, lecture, salawat, piété filiale, sport... ancrez la bonne habitude avec des séries et de la motivation.', href: 'build-habit' },
        ],
        features: [
          { icon: '🔒', h: 'Totalement privé', p: 'Votre profil n\'appartient qu\'à vous. Inscription avec nom, e-mail et mot de passe.' },
          { icon: '🏅', h: 'Badges & motivation', p: 'Gagnez des boucliers : argent à 30, or à 60, diamant à 90 jours.' },
          { icon: '🌙', h: 'Aligné sur vos valeurs', p: 'Un contenu encourageant, avec des modèles d\'habitudes religieuses optionnels.' },
          { icon: '📶', h: 'Fonctionne hors ligne', p: 'Enregistrez votre journée à tout moment ; synchronisation au retour du réseau.' },
        ],
        sectionTitle: 'Deux parcours, votre chemin',
        featuresTitle: 'Conçu pour votre réussite',
      },
      'break-habit': {
        title: 'Arrêter une mauvaise habitude : méthode HRT | Awwad',
        description: "Arrêtez une mauvaise habitude (tabac, ongles, trichotillomanie, téléphone, masturbation compulsive) avec la méthode Habit Reversal Training : prise de conscience, réponse alternative, contrôle de l'environnement, puis maintien.",
        h1: 'Arrêtez l\'habitude avec une méthode éprouvée',
        intro: "Le Habit Reversal Training est une méthode reconnue pour changer les habitudes compulsives. Awwad vous guide en 4 phases claires, et gère plusieurs habitudes à la fois (jusqu'à 3 à arrêter et 3 à bâtir) entre lesquelles vous pouvez basculer.",
        blocks: [
          { h: '1) Prise de conscience', p: 'Repérez et notez quand, où et pourquoi l\'habitude survient, l\'étape la plus importante.' },
          { h: '2) Réponse alternative', p: 'Entraînez un comportement de remplacement au moment de l\'envie.' },
          { h: '3) Contrôle de l\'environnement', p: 'Ajustez votre entourage pour réduire les déclencheurs.' },
          { h: '4) Maintien', p: 'Révisez, gardez ce qui marche et protégez vos progrès.' },
        ],
        resource: {
          h: 'Soutien dédié pour la masturbation compulsive',
          p: "Si vous avez choisi d'arrêter cette habitude, lorsque l'envie surgit nous recommandons de passer environ 15 minutes sur la chaîne YouTube Waai au lieu de céder. C'est un contenu de sensibilisation qui aide à comprendre et à tenir. L'app suit vos progrès avec discrétion et propose des alternatives concrètes à chaque envie.",
          cta: 'Ouvrir la chaîne Waai sur YouTube',
          url: WAAI_URL,
        },
      },
      'build-habit': {
        title: 'Bâtir une nouvelle habitude durable | Awwad',
        description: "Bâtissez une nouvelle habitude (prière, lecture, sport) et ancrez-la avec des séries, des rappels quotidiens et de la motivation, avec des modèles religieux optionnels.",
        h1: 'Bâtissez votre nouvelle habitude',
        intro: "Les nouvelles habitudes s'ancrent par la répétition et l'encouragement. Awwad vous aide à protéger votre série jour après jour.",
        blocks: [
          { h: 'Définissez votre pourquoi', p: 'Écrivez pourquoi vous voulez cette habitude ; un rappel dans les moments de baisse.' },
          { h: 'Série quotidienne', p: 'Chaque jour complété construit votre série et rapproche le prochain badge.' },
          { h: 'Rappel bienveillant', p: 'Un rappel quotidien à l\'heure de votre choix, respectueux des heures de prière.' },
          { h: 'Modèles prêts', p: 'Prière, lecture, sport, dhikr... ou votre habitude personnalisée.' },
        ],
      },
      privacy: {
        title: 'Politique de confidentialité | Awwad',
        description: 'Politique de confidentialité d\'Awwad : ce que nous collectons, comment nous l\'utilisons et vos droits.',
        h1: 'Politique de confidentialité',
        blocks: [
          { h: 'Données collectées', p: 'Données de compte (nom, e-mail, mot de passe haché), vos données de suivi que vous saisissez, et des données d\'usage anonymisées. Le questionnaire initial est entièrement facultatif.' },
          { h: 'Utilisation', p: 'Pour faire fonctionner votre compte et synchroniser vos données, et pour améliorer l\'expérience. Nous ne vendons jamais vos données et ne les partageons pas à des fins publicitaires.' },
          { h: 'Données de recherche optionnelles', p: 'Si vous consentez au questionnaire, notre équipe peut consulter vos réponses (agrégées ou individuelles) à des fins de recherche et d\'amélioration. Vous pouvez le passer sans conséquence.' },
          { h: 'Prestataires', p: 'Nous utilisons Supabase (stockage et authentification) et Firebase Cloud Messaging (notifications), au strict nécessaire.' },
          { h: 'Vos droits', p: 'Vous pouvez exporter vos données ou supprimer votre compte et toutes vos données à tout moment, depuis l\'app ou la page de suppression de compte.' },
          { h: 'Contact', p: 'Pour toute question : moradarafa600@gmail.com' },
        ],
      },
      terms: {
        title: 'Conditions d\'utilisation | Awwad',
        description: 'Conditions d\'utilisation de l\'application Awwad.',
        h1: 'Conditions d\'utilisation',
        blocks: [
          { h: 'Nature du service', p: 'Awwad est un outil d\'auto-assistance comportementale et de suivi, ni un service médical ni psychologique, et non un substitut à un professionnel.' },
          { h: 'Utilisation', p: 'Vous êtes responsable de la confidentialité de votre compte et de l\'exactitude de vos données. Tout usage abusif est interdit.' },
          { h: 'Gratuit pour l\'instant', p: 'Le service est actuellement gratuit et sans but lucratif. Des abonnements optionnels pourront être ajoutés ; vous serez prévenu avant tout changement.' },
          { h: 'Contenu religieux', p: 'Le contenu motivant est un simple rappel. Toute référence à une règle religieuse provient d\'IslamWeb ; consultez des savants qualifiés pour une fatwa.' },
          { h: 'Avis de non-responsabilité', p: 'Le service est fourni tel quel, sans garantie. Nous ne sommes pas responsables des décisions prises sur la base de l\'app.' },
        ],
      },
      'delete-account': {
        title: 'Supprimer votre compte | Awwad',
        description: 'Comment supprimer définitivement votre compte et vos données Awwad.',
        h1: 'Supprimer le compte et les données',
        blocks: [
          { h: 'Depuis l\'application', p: 'Ouvrez : Réglages, puis Compte, puis Supprimer le compte. Votre compte et toutes vos données (habitudes, journaux, badges) sont supprimés définitivement et irréversiblement.' },
          { h: 'Sans connexion', p: 'Si vous ne pouvez plus vous connecter, envoyez une demande depuis votre adresse enregistrée à moradarafa600@gmail.com avec l\'objet « Supprimer le compte ». Nous vous vérifions par e-mail, puis supprimons vos données.' },
          { h: 'Ce qui est supprimé', p: 'Toutes vos données personnelles, de suivi, vos appareils de confiance et les journaux d\'usage liés à vous.' },
        ],
      },
    },
  },
};
