// GENERATED per-habit content: tailored HRT checklists + scholar-video search
// queries. Sourced from a research workflow (see PROJECT_STATE changelog).
// Each label is a trilingual map {ar,en,fr}. videoQuery feeds a YouTube search.

class HabitChecklists {
  final List<Map<String, String>> competingResponses;
  final List<Map<String, String>> environment;
  const HabitChecklists(
      {this.competingResponses = const [], this.environment = const []});
}

/// Localized checklist labels for a habit's group, or empty if the habit has no
/// tailored content (caller then falls back to the generic seeded fields).
/// [group] is 'competing_response' or 'environment_action'.
List<String> habitChecklistLabels(
    String? catalogKey, String group, String locale) {
  if (catalogKey == null) return const [];
  final c = kHabitChecklists[catalogKey];
  if (c == null) return const [];
  final list =
      group == 'competing_response' ? c.competingResponses : c.environment;
  return list.map((m) => m[locale] ?? m['ar'] ?? '').toList();
}

/// A YouTube search URL for the habit's recommended scholar video, or null.
String? habitVideoSearchUrl(String? catalogKey) {
  if (catalogKey == null) return null;
  final q = kHabitVideoQuery[catalogKey];
  if (q == null) return null;
  return 'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(q)}';
}

const Map<String, HabitChecklists> kHabitChecklists = {
  'quit_smoking': HabitChecklists(
    competingResponses: [
      {'ar': "اشرب كوب ماء بارد ببطء عند اشتداد الرغبة في التدخين", 'en': "Slowly sip a glass of cold water when the craving hits", 'fr': "Bois lentement un verre d'eau fraiche quand l'envie surgit"},
      {'ar': "امضغ علكة خالية من السكر أو عودا من القرفة بدل السيجارة", 'en': "Chew sugar-free gum or a cinnamon stick instead of a cigarette", 'fr': "Mache un chewing-gum sans sucre ou un baton de cannelle"},
      {'ar': "تنفس بعمق عشر مرات مع ترديد الاستغفار حتى تمر الرغبة", 'en': "Take ten deep breaths while repeating istighfar until the urge passes", 'fr': "Respire profondement dix fois en repetant l'istighfar jusqu'a ce que l'envie passe"},
      {'ar': "شغل يديك بمسبحة أو بكتابة سبب إقلاعك على ورقة", 'en': "Keep your hands busy with prayer beads or write down your reason for quitting", 'fr': "Occupe tes mains avec un chapelet ou ecris ta raison d'arreter"},
      {'ar': "اخرج لمشي سريع خمس دقائق فور الإحساس بالرغبة", 'en': "Go for a brisk five-minute walk the moment a craving starts", 'fr': "Fais une marche rapide de cinq minutes des qu'une envie commence"},
    ],
    environment: [
      {'ar': "تخلص من جميع علب السجائر والولاعات والمنافض من البيت والسيارة", 'en': "Throw out all cigarette packs, lighters, and ashtrays from home and car", 'fr': "Jette tous les paquets de cigarettes, briquets et cendriers de la maison et la voiture"},
      {'ar': "تجنب أماكن التدخين كالمقاهي والجلسات التي يكثر فيها الدخان", 'en': "Avoid smoking spots like cafes and gatherings where smoking is common", 'fr': "Evite les lieux de tabac comme les cafes et les rassemblements de fumeurs"},
      {'ar': "اطلب من المحيطين بك عدم التدخين أمامك ولا إهداؤك سيجارة", 'en': "Ask those around you not to smoke near you or offer you a cigarette", 'fr': "Demande a ton entourage de ne pas fumer pres de toi ni t'offrir de cigarette"},
      {'ar': "ضع المال المخصص للسجائر في مكان ظاهر كهدف ادخار", 'en': "Put your cigarette money in a visible jar as a savings goal", 'fr': "Mets l'argent des cigarettes dans un bocal visible comme objectif d'epargne"},
    ],
  ),
  'quit_vaping': HabitChecklists(
    competingResponses: [
      {'ar': "أمسك بشيء صغير في يدك مثل المسبحة أو قلم بدلا من الجهاز", 'en': "Hold a small object like prayer beads or a pen instead of the device", 'fr': "Tenez un petit objet comme un chapelet ou un stylo au lieu de l'appareil"},
      {'ar': "تنفس بعمق عشر مرات ببطء حتى تمر الرغبة", 'en': "Take ten slow deep breaths until the urge passes", 'fr': "Prenez dix respirations lentes et profondes jusqu'à ce que l'envie passe"},
      {'ar': "اشرب جرعة من الماء البارد أو امضغ علكة خالية من السكر", 'en': "Drink a sip of cold water or chew sugar-free gum", 'fr': "Buvez une gorgée d'eau froide ou mâchez un chewing-gum sans sucre"},
      {'ar': "اغسل أسنانك أو استخدم سواكا لتغيير طعم الفم", 'en': "Brush your teeth or use a miswak to change your mouth's taste", 'fr': "Brossez-vous les dents ou utilisez un siwak pour changer le goût de votre bouche"},
      {'ar': "اخرج للمشي خمس دقائق أو توضأ وصل ركعتين", 'en': "Step out for a five-minute walk or perform wudu and pray two rakaat", 'fr': "Sortez marcher cinq minutes ou faites les ablutions et priez deux rakaat"},
    ],
    environment: [
      {'ar': "تخلص من الجهاز وعبوات السائل وأجهزة الشحن من المنزل والسيارة", 'en': "Get rid of the device, e-liquid pods, and chargers from your home and car", 'fr': "Débarrassez-vous de l'appareil, des recharges de liquide et des chargeurs de votre maison et voiture"},
      {'ar': "تجنب الأماكن والأصدقاء المرتبطين بالتدخين في الأسابيع الأولى", 'en': "Avoid places and friends associated with vaping during the first weeks", 'fr': "Évitez les lieux et amis associés au vapotage durant les premières semaines"},
      {'ar': "احتفظ ببدائل صحية في متناول اليد مثل المكسرات والماء والعلكة", 'en': "Keep healthy alternatives within reach like nuts, water, and gum", 'fr': "Gardez des alternatives saines à portée de main comme noix, eau et chewing-gum"},
      {'ar': "أخبر أهلك وأصدقاءك بقرار الإقلاع ليساندوك ويذكروك", 'en': "Tell your family and friends about your decision to quit so they support and remind you", 'fr': "Informez votre famille et vos amis de votre décision d'arrêter pour qu'ils vous soutiennent et vous rappellent"},
    ],
  ),
  'nail_biting': HabitChecklists(
    competingResponses: [
      {'ar': "اقبض يدك بإحكام لعشر ثوانٍ كلما اشتقت إلى القضم", 'en': "Clench your fist tightly for ten seconds whenever the urge hits", 'fr': "Serre le poing pendant dix secondes des que l'envie surgit"},
      {'ar': "امسك بكرة ضغط صغيرة أو سبحة بين أصابعك", 'en': "Hold a small stress ball or prayer beads between your fingers", 'fr': "Tiens une balle anti-stress ou un chapelet entre tes doigts"},
      {'ar': "اجلس وضع يديك تحت فخذيك حتى تزول الرغبة", 'en': "Sit and tuck both hands under your thighs until the urge passes", 'fr': "Assieds-toi et glisse tes mains sous tes cuisses jusqu'a ce que l'envie passe"},
      {'ar': "اشغل يديك بالوضوء أو بترتيب ما حولك", 'en': "Keep your hands busy with wudu or tidying your space", 'fr': "Occupe tes mains par les ablutions ou en rangeant autour de toi"},
      {'ar': "دلّك أطراف أصابعك بزيت وردّد ذكرًا قصيرًا", 'en': "Massage your fingertips with oil while repeating a short dhikr", 'fr': "Masse le bout de tes doigts avec de l'huile en repetant un court dhikr"},
    ],
    environment: [
      {'ar': "قصّ أظافرك قصيرة باستمرار حتى لا يبقى ما تقضمه", 'en': "Keep your nails trimmed short so there is nothing to bite", 'fr': "Garde tes ongles coupes courts pour qu'il n'y ait rien a ronger"},
      {'ar': "ضع لاصقًا أو طلاءً مرّ المذاق على الأظافر", 'en': "Apply a bandage or bitter-tasting polish on your nails", 'fr': "Mets un pansement ou un vernis au gout amer sur tes ongles"},
      {'ar': "احتفظ بمشغل لليدين قريبًا منك في كل مكان", 'en': "Keep a hand-fidget tool within reach everywhere you go", 'fr': "Garde un objet a manipuler a portee de main partout"},
      {'ar': "ضع تذكيرًا مرئيًا على مكتبك وهاتفك يوقفك عند القضم", 'en': "Place a visible reminder on your desk and phone to stop you", 'fr': "Place un rappel visible sur ton bureau et ton telephone pour t'arreter"},
    ],
  ),
  'hair_pulling': HabitChecklists(
    competingResponses: [
      {'ar': "أقبض كفي بقوة وأعد إلى العشرة حتى تزول الرغبة", 'en': "Clench my fist tightly and count to ten until the urge passes", 'fr': "Je serre fortement le poing et compte jusqu'a dix jusqu'a ce que l'envie passe"},
      {'ar': "أمسك بكرة ضغط أو مسبحة لأشغل يدي عن الشعر", 'en': "Hold a stress ball or prayer beads to keep my hands away from my hair", 'fr': "Je tiens une balle anti-stress ou un chapelet pour occuper mes mains loin des cheveux"},
      {'ar': "أضع يدي تحت فخذي أو أجلس عليهما لدقيقتين", 'en': "Place my hands under my thighs or sit on them for two minutes", 'fr': "Je place mes mains sous mes cuisses ou m'assois dessus pendant deux minutes"},
      {'ar': "أتوضأ وأصلي ركعتين عندما تشتد الرغبة", 'en': "Make wudu and pray two rakaat when the urge intensifies", 'fr': "Je fais les ablutions et prie deux rakaat quand l'envie s'intensifie"},
      {'ar': "أدلك فروة رأسي براحة يدي بدلا من شد الشعر", 'en': "Massage my scalp with my palm instead of pulling the hair", 'fr': "Je masse mon cuir chevelu avec la paume au lieu de tirer les cheveux"},
    ],
    environment: [
      {'ar': "أرتدي قبعة خفيفة أو غطاء رأس في أوقات الرغبة الشديدة", 'en': "Wear a light cap or head covering during high-urge times", 'fr': "Je porte une casquette legere ou un couvre-chef pendant les moments de forte envie"},
      {'ar': "أقص أظافري وألبس قفازين عند الجلوس وحدي", 'en': "Trim my nails and wear gloves when sitting alone", 'fr': "Je coupe mes ongles et porte des gants quand je suis assis seul"},
      {'ar': "أبعد المرايا الصغيرة والملاقط التي تشجع على الفحص والنتف", 'en': "Remove small mirrors and tweezers that encourage inspecting and pulling", 'fr': "J'eloigne les petits miroirs et les pinces qui incitent a inspecter et arracher"},
      {'ar': "أضيء الغرفة جيدا وأبقى قرب الناس بدلا من العزلة", 'en': "Keep the room well lit and stay near people instead of isolating", 'fr': "Je garde la piece bien eclairee et reste pres des gens au lieu de m'isoler"},
    ],
  ),
  'skin_picking': HabitChecklists(
    competingResponses: [
      {'ar': "أضع يديّ تحت فخذيّ أو أطبق راحتيّ معا حتى تزول الرغبة.", 'en': "I sit on my hands or clasp my palms together until the urge passes.", 'fr': "Je m'assois sur mes mains ou je serre mes paumes jusqu'a ce que l'envie passe."},
      {'ar': "أمسك كرة ضغط أو خرز التسبيح وأشغل أصابعي بها بدلا من نتش الجلد.", 'en': "I squeeze a stress ball or worry beads to keep my fingers busy instead of picking.", 'fr': "Je presse une balle anti-stress ou un chapelet pour occuper mes doigts au lieu de gratter."},
      {'ar': "أدهن يديّ بمرطب لزج يجعل الجلد أملس ويصعب الإمساك به.", 'en': "I rub on a thick moisturizer that makes my skin smooth and hard to grip.", 'fr': "J'applique une creme epaisse qui rend ma peau lisse et difficile a saisir."},
      {'ar': "أتوضأ وأصلي ركعتين أو أردد ذكرا حتى ينصرف انشغالي عن الجلد.", 'en': "I make wudu and pray two rak'ahs or recite dhikr until my focus leaves my skin.", 'fr': "Je fais les ablutions et prie deux rak'ahs ou recite un dhikr jusqu'a detourner mon attention."},
      {'ar': "أنهض وأغسل يديّ بماء بارد وأشد قبضتي عشر ثوان حتى تهدأ الرغبة.", 'en': "I stand up, rinse my hands in cold water, and clench my fists for ten seconds until the urge calms.", 'fr': "Je me leve, rince mes mains a l'eau froide et serre les poings dix secondes jusqu'au calme."},
    ],
    environment: [
      {'ar': "أقص أظافري قصيرة وأبقيها ناعمة حتى يصعب نتش الجلد.", 'en': "I keep my nails trimmed short and smooth so picking is harder.", 'fr': "Je garde mes ongles courts et lisses pour rendre le grattage difficile."},
      {'ar': "أغطي المناطق التي أنتشها بضمادة أو ملابس بأكمام طويلة.", 'en': "I cover the spots I pick with a bandage or long sleeves.", 'fr': "Je couvre les zones que je gratte avec un pansement ou des manches longues."},
      {'ar': "أبعد المرآة المكبرة والملاقط من متناول يدي.", 'en': "I keep magnifying mirrors and tweezers out of reach.", 'fr': "Je range les miroirs grossissants et les pinces hors de portee."},
      {'ar': "أضيء غرفتي إضاءة خافتة عند الأماكن التي أجلس فيها طويلا حتى لا تظهر تفاصيل الجلد.", 'en': "I dim the lighting where I sit for long periods so skin details are less visible.", 'fr': "Je tamise l'eclairage la ou je reste longtemps pour moins voir les details de la peau."},
    ],
  ),
  'secret_habit': HabitChecklists(
    competingResponses: [
      {'ar': "أتوضأ فورا وأصلي ركعتين عند هجوم الرغبة", 'en': "Make wudu at once and pray two rak'ahs when the urge hits", 'fr': "Faire les ablutions aussitot et prier deux rak'ahs des que l'envie surgit"},
      {'ar': "أغادر السرير والغرفة المغلقة وأخرج إلى مكان مفتوح", 'en': "Leave the bed and the closed room and go to an open space", 'fr': "Quitter le lit et la piece fermee et sortir dans un espace ouvert"},
      {'ar': "أترك الهاتف بعيداً وأشغل يديّ بوضوء بارد أو تمرين سريع", 'en': "Keep both hands busy with cold wudu or quick exercise instead of the phone", 'fr': "Occuper les deux mains avec des ablutions froides ou un exercice rapide au lieu du telephone"},
      {'ar': "أتصل بصديق صالح أو أقرأ ورد القرآن حتى تهدأ الرغبة", 'en': "Call a righteous friend or read a portion of Quran until the urge passes", 'fr': "Appeler un ami pieux ou lire une portion du Coran jusqu'a ce que l'envie passe"},
      {'ar': "أستحضر مراقبة الله وأستغفر عشر مرات وأشرب ماء باردا", 'en': "Recall that Allah sees me, seek forgiveness ten times, and drink cold water", 'fr': "Me rappeler qu'Allah me voit, demander pardon dix fois et boire de l'eau froide"},
      {'ar': "أصوم تطوعاً ما استطعت، فالصيام يكسر حدة الشهوة كما أوصى النبي صلى الله عليه وسلم", 'en': "Fast voluntarily when you can; fasting weakens desire, as the Prophet, peace be upon him, advised", 'fr': "Jeûner volontairement quand possible : le jeûne apaise le désir, comme l'a conseillé le Prophète, paix sur lui"},
    ],
    environment: [
      {'ar': "أخرج الهاتف من غرفة النوم وأشحنه في مكان بعيد ليلا", 'en': "Keep the phone out of the bedroom and charge it far away at night", 'fr': "Garder le telephone hors de la chambre et le charger loin la nuit"},
      {'ar': "أفعّل فلترا يحجب المواقع الإباحية على كل الأجهزة", 'en': "Install a filter that blocks pornographic sites on all devices", 'fr': "Installer un filtre qui bloque les sites pornographiques sur tous les appareils"},
      {'ar': "أتجنب الخلوة الطويلة وأبقي باب الغرفة مفتوحا", 'en': "Avoid long isolation and keep the room door open", 'fr': "Eviter l'isolement prolonge et garder la porte de la chambre ouverte"},
      {'ar': "أنام مبكرا ولا آخذ الهاتف إلى الفراش", 'en': "Sleep early and do not take the phone to bed", 'fr': "Se coucher tot et ne pas emporter le telephone au lit"},
    ],
  ),
  'phone_addiction': HabitChecklists(
    competingResponses: [
      {'ar': "ضع الهاتف في غرفة أخرى وامكث بعيداً عنه عشرين دقيقة.", 'en': "Put the phone in another room and stay away for 20 minutes.", 'fr': "Posez le téléphone dans une autre pièce et restez loin 20 minutes."},
      {'ar': "حوّل الشاشة إلى الوضع الرمادي عند الرغبة في التصفّح.", 'en': "Switch the screen to grayscale when the urge to scroll hits.", 'fr': "Passez l'écran en niveaux de gris quand l'envie de scroller surgit."},
      {'ar': "افتح المصحف واقرأ صفحة بدل فتح التطبيقات.", 'en': "Open the Quran and read one page instead of opening apps.", 'fr': "Ouvrez le Coran et lisez une page au lieu d'ouvrir les applications."},
      {'ar': "قم بوضوء وصلِّ ركعتين عند اشتداد الرغبة في الإمساك بالهاتف.", 'en': "Make wudu and pray two rak'ahs when the urge to grab the phone is strong.", 'fr': "Faites les ablutions et priez deux rak'ahs quand l'envie de saisir le téléphone est forte."},
      {'ar': "اخرج في مشي قصير وأذكار بدل التمرير في الخلاصة.", 'en': "Take a short walk with dhikr instead of scrolling the feed.", 'fr': "Faites une courte marche avec du dhikr au lieu de faire défiler le fil."},
    ],
    environment: [
      {'ar': "احذف تطبيقات التواصل من الشاشة الرئيسية وأخفها في مجلد.", 'en': "Remove social apps from the home screen and hide them in a folder.", 'fr': "Retirez les applis sociales de l'écran d'accueil et cachez-les dans un dossier."},
      {'ar': "أوقف كل الإشعارات غير الضرورية وفعّل وضع التركيز.", 'en': "Turn off all non-essential notifications and enable focus mode.", 'fr': "Désactivez toutes les notifications non essentielles et activez le mode concentration."},
      {'ar': "اشحن الهاتف خارج غرفة النوم ولا تأخذه إلى الفراش.", 'en': "Charge the phone outside the bedroom and don't take it to bed.", 'fr': "Chargez le téléphone hors de la chambre et ne l'emportez pas au lit."},
      {'ar': "اضبط حدّاً زمنياً يومياً للتطبيقات المسببة للإدمان.", 'en': "Set a daily time limit on the addictive apps.", 'fr': "Fixez une limite de temps quotidienne sur les applications addictives."},
    ],
  ),
  'excessive_gaming': HabitChecklists(
    competingResponses: [
      {'ar': "عندما أشتهي تشغيل اللعبة، أتوضأ وأصلي ركعتين أو أقرأ صفحة من المصحف.", 'en': "When I crave starting the game, I make wudu and pray two rakat or read a page of Quran.", 'fr': "Quand l'envie de lancer le jeu surgit, je fais mes ablutions et prie deux rakat ou lis une page du Coran."},
      {'ar': "أضبط مؤقتا لخمس عشرة دقيقة من رياضة أو مشي بدل فتح اللعبة.", 'en': "I set a fifteen-minute timer for exercise or a walk instead of opening the game.", 'fr': "Je règle une minuterie de quinze minutes pour faire du sport ou marcher au lieu d'ouvrir le jeu."},
      {'ar': "أمسك بكتاب أو مهارة جديدة فأشغل عقلي ويدي بشيء نافع.", 'en': "I pick up a book or a new skill, keeping my mind and hands busy with something useful.", 'fr': "Je prends un livre ou une nouvelle compétence pour occuper mon esprit et mes mains utilement."},
      {'ar': "أتصل بأحد الأهل أو الأصدقاء أو أزورهم بدل الجلوس وحيدا أمام الشاشة.", 'en': "I call or visit family or a friend instead of sitting alone in front of the screen.", 'fr': "J'appelle ou rends visite a un proche ou un ami au lieu de rester seul devant l'ecran."},
      {'ar': "أنجز مهمة مؤجلة لخمس دقائق فأحول طاقة اللعب إلى عمل حقيقي.", 'en': "I tackle a postponed task for five minutes, turning the gaming urge into real work.", 'fr': "Je m'attaque a une tache reportee pendant cinq minutes, transformant l'envie de jouer en travail reel."},
    ],
    environment: [
      {'ar': "أحذف الألعاب المسببة للإدمان من الهاتف وأسجل خروجي من حساباتها.", 'en': "I delete the addictive games from my phone and log out of their accounts.", 'fr': "Je supprime les jeux addictifs de mon telephone et me deconnecte de leurs comptes."},
      {'ar': "أنقل جهاز اللعب إلى غرفة مشتركة وأبعده عن غرفة النوم.", 'en': "I move the gaming device to a shared room and keep it out of the bedroom.", 'fr': "Je deplace la console dans une piece commune et la garde hors de la chambre."},
      {'ar': "أضع حدا زمنيا يوميا عبر أدوات التحكم الأبوي ومؤقت الاستخدام.", 'en': "I set a daily time limit using parental-control tools and a usage timer.", 'fr': "Je fixe une limite de temps quotidienne avec le controle parental et un minuteur d'usage."},
      {'ar': "ألغي إشعارات الألعاب وأزيل اختصاراتها من الشاشة الرئيسية.", 'en': "I turn off game notifications and remove their shortcuts from the home screen.", 'fr': "Je desactive les notifications des jeux et retire leurs raccourcis de l'ecran d'accueil."},
    ],
  ),
  'procrastination': HabitChecklists(
    competingResponses: [
      {'ar': "ابدأ بأصغر خطوة لمدة دقيقتين فقط ثم أكمل", 'en': "Start the smallest step for just two minutes, then continue", 'fr': "Commence la plus petite etape pendant deux minutes, puis continue"},
      {'ar': "اكتب المهمة الواحدة الواجبة الآن وأنجزها قبل غيرها", 'en': "Write the single required task now and finish it before anything else", 'fr': "Note la seule tache requise maintenant et termine-la avant tout"},
      {'ar': "قسم العمل الكبير إلى مهمات صغيرة محددة المدة", 'en': "Split the big task into small time-boxed chunks", 'fr': "Decoupe la grande tache en petits blocs limites dans le temps"},
      {'ar': "توضأ وصل ركعتين ثم اشرع في العمل مباشرة", 'en': "Make wudu, pray two rakaat, then start the work immediately", 'fr': "Fais les ablutions, prie deux rakaat, puis commence le travail aussitot"},
      {'ar': "أغلق المشتتات وشغل مؤقتا لمدة خمس وعشرين دقيقة للتركيز", 'en': "Close distractions and run a twenty-five minute focus timer", 'fr': "Ferme les distractions et lance un minuteur de concentration de vingt-cinq minutes"},
    ],
    environment: [
      {'ar': "أعد قائمة مهام اليوم مكتوبة وضعها أمام عينيك", 'en': "Prepare a written to-do list for today and keep it in sight", 'fr': "Prepare une liste de taches ecrite pour aujourdhui et garde-la en vue"},
      {'ar': "أبعد الهاتف ووسائل التواصل عن مكان العمل أثناء الإنجاز", 'en': "Keep the phone and social media away from your workspace while working", 'fr': "Eloigne le telephone et les reseaux sociaux du lieu de travail pendant la tache"},
      {'ar': "هيئ مكانا مرتبا ومخصصا للعمل خاليا من الفوضى", 'en': "Set up a tidy, dedicated work spot free of clutter", 'fr': "Amenage un espace de travail range et dedie, sans desordre"},
      {'ar': "حدد موعدا نهائيا واضحا لكل مهمة وأخبر به من يحاسبك", 'en': "Set a clear deadline for each task and tell an accountability partner", 'fr': "Fixe une echeance claire pour chaque tache et informe un partenaire de responsabilite"},
    ],
  ),
  'junk_food': HabitChecklists(
    competingResponses: [
      {'ar': "شربت كوب ماء كبير وانتظرت عشر دقائق قبل أي قرار بالأكل", 'en': "I drank a big glass of water and waited 10 minutes before deciding to eat", 'fr': "J'ai bu un grand verre d'eau et attendu 10 minutes avant de décider de manger"},
      {'ar': "تناولت بديلاً صحياً جاهزاً كحبة فاكهة أو حفنة مكسرات نيئة", 'en': "I grabbed a ready healthy swap like a fruit or a handful of plain nuts", 'fr': "J'ai pris une alternative saine prête comme un fruit ou des noix nature"},
      {'ar': "نظفت أسناني بالفرشاة فور انتهاء الوجبة لأقطع الرغبة في التحلية", 'en': "I brushed my teeth right after the meal to shut down the craving for sweets", 'fr': "Je me suis brossé les dents juste après le repas pour couper l'envie de sucré"},
      {'ar': "خرجت في مشية قصيرة بدل التوجه إلى المطعم أو التطبيق", 'en': "I took a short walk instead of heading to the restaurant or the delivery app", 'fr': "J'ai fait une courte marche au lieu d'aller au restaurant ou sur l'appli de livraison"},
      {'ar': "قلت بسم الله وذكّرت نفسي بأنه ما ملأ ابن آدم وعاءً شراً من بطنه", 'en': "I said Bismillah and reminded myself that the stomach is the worst vessel to fill", 'fr': "J'ai dit Bismillah en me rappelant que le ventre est le pire récipient à remplir"},
    ],
    environment: [
      {'ar': "أزلت الوجبات السريعة والحلويات من البيت ولم أبقِ في متناول يدي إلا الصحي", 'en': "I cleared junk food and sweets from home and kept only healthy options within reach", 'fr': "J'ai retiré la malbouffe et les sucreries de la maison et n'ai gardé que du sain à portée"},
      {'ar': "حذفت تطبيقات توصيل الطعام وحسابات المطاعم من هاتفي", 'en': "I deleted food delivery apps and restaurant accounts from my phone", 'fr': "J'ai supprimé les applis de livraison et les comptes de restaurants de mon téléphone"},
      {'ar': "حضّرت وجبات صحية مسبقاً ووضعتها في الواجهة داخل الثلاجة", 'en': "I meal prepped healthy food in advance and placed it at the front of the fridge", 'fr': "J'ai préparé des repas sains à l'avance et les ai placés à l'avant du frigo"},
      {'ar': "أكلت في طبق صغير على المائدة فقط وامتنعت عن الأكل أمام الشاشات", 'en': "I ate only at the table from a small plate and avoided eating in front of screens", 'fr': "J'ai mangé uniquement à table dans une petite assiette, jamais devant un écran"},
    ],
  ),
  'oversleeping': HabitChecklists(
    competingResponses: [
      {'ar': "أصلي الفجر في وقته ثم أمشي عشر دقائق بدلا من العودة إلى النوم", 'en': "Pray Fajr on time, then walk for ten minutes instead of going back to sleep", 'fr': "Prier le Fajr a l'heure, puis marcher dix minutes au lieu de me rendormir"},
      {'ar': "أنزل من السرير فورا عند الاستيقاظ وأغسل وجهي بماء بارد", 'en': "Get out of bed immediately on waking and wash my face with cold water", 'fr': "Sortir du lit des le reveil et me laver le visage a l'eau froide"},
      {'ar': "أبدأ يومي بأذكار الصباح وقراءة صفحة من القرآن فور النهوض", 'en': "Start my day with morning remembrance and one page of Quran right after rising", 'fr': "Commencer ma journee par les invocations du matin et une page de Coran des le lever"},
      {'ar': "أؤدي مهمة نافعة في أول عشرين دقيقة من الصباح قبل أي راحة", 'en': "Do one useful task in the first twenty minutes of the morning before any rest", 'fr': "Accomplir une tache utile dans les vingt premieres minutes du matin avant tout repos"},
      {'ar': "عند الرغبة في قيلولة طويلة أكتفي بعشرين دقيقة وأضبط منبها", 'en': "When tempted by a long nap, limit it to twenty minutes and set an alarm", 'fr': "Quand je suis tente par une longue sieste, la limiter a vingt minutes et regler une alarme"},
    ],
    environment: [
      {'ar': "أضبط منبها واحدا بعيدا عن السرير يجبرني على القيام لإيقافه", 'en': "Set a single alarm far from the bed that forces me to stand up to turn it off", 'fr': "Regler une seule alarme loin du lit qui m'oblige a me lever pour l'eteindre"},
      {'ar': "أنام مبكرا وأحدد وقتا ثابتا للنوم لأكفي حاجتي دون إفراط", 'en': "Sleep early and fix a consistent bedtime to get enough rest without excess", 'fr': "Me coucher tot et fixer une heure de sommeil reguliere pour un repos suffisant sans exces"},
      {'ar': "أفتح الستائر وأدخل ضوء النهار إلى الغرفة فور الاستيقاظ", 'en': "Open the curtains and let daylight into the room as soon as I wake", 'fr': "Ouvrir les rideaux et laisser entrer la lumiere du jour des le reveil"},
      {'ar': "أبعد الهاتف عن السرير ليلا حتى لا يؤخر نومي ولا يطيل بقائي فيه", 'en': "Keep the phone away from the bed at night so it neither delays sleep nor keeps me in bed", 'fr': "Eloigner le telephone du lit la nuit pour qu'il ne retarde pas mon sommeil ni ne me retienne au lit"},
    ],
  ),
  'gossip': HabitChecklists(
    competingResponses: [
      {'ar': "أغلقت فمي وقلت في نفسي ذكرا قصيرا حتى يزول الدافع", 'en': "I close my mouth and silently repeat a short dhikr until the urge passes", 'fr': "Je ferme la bouche et repete un court dhikr en silence jusqu'a ce que l'envie passe"},
      {'ar': "حولت الكلام نحو ذكر حسنة في الشخص بدل عيبه", 'en': "I steer the conversation toward something good about the person instead of their fault", 'fr': "Je dirige la conversation vers une qualite de la personne au lieu de son defaut"},
      {'ar': "غيرت موضوع الحديث فورا الى أمر نافع أو سؤال", 'en': "I immediately change the subject to something useful or ask a question", 'fr': "Je change immediatement de sujet vers quelque chose d'utile ou une question"},
      {'ar': "انسحبت من المجلس بأدب أو صمت حتى ينتهي الكلام", 'en': "I politely leave the gathering or stay silent until the talk ends", 'fr': "Je quitte poliment le rassemblement ou je me tais jusqu'a la fin de la discussion"},
      {'ar': "دافعت عن الغائب بكلمة طيبة بدل المشاركة في عيبه", 'en': "I defend the absent person with a kind word instead of joining the criticism", 'fr': "Je defends la personne absente par une parole bienveillante au lieu de participer a la critique"},
    ],
    environment: [
      {'ar': "أبتعد عن المجالس والمجموعات التي يكثر فيها الكلام في الناس", 'en': "I avoid gatherings and group chats where people are often discussed", 'fr': "J'evite les rassemblements et les groupes ou l'on parle souvent des gens"},
      {'ar': "أكتم الإشعارات وأخرج من المحادثات التي تشعل الغيبة", 'en': "I mute notifications and leave chats that spark gossip", 'fr': "Je coupe les notifications et je quitte les conversations qui declenchent les commerages"},
      {'ar': "أرافق أصدقاء يحفظون ألسنتهم ويذكرونني عند الزلل", 'en': "I keep company with friends who guard their tongues and remind me when I slip", 'fr': "Je m'entoure d'amis qui maitrisent leur langue et me reprennent quand je derape"},
      {'ar': "أضع تذكيرا مرئيا بآية أو حديث عن حفظ اللسان أمامي", 'en': "I place a visible reminder of a verse or hadith about guarding the tongue in front of me", 'fr': "Je place devant moi un rappel visible d'un verset ou hadith sur la maitrise de la langue"},
    ],
  ),
  'bad_language': HabitChecklists(
    competingResponses: [
      {'ar': "عند اشتداد الغضب أقول أعوذ بالله من الشيطان الرجيم وأصمت فورا", 'en': "When anger rises, say I seek refuge in Allah from Satan and go silent at once", 'fr': "Quand la colère monte, dire je cherche refuge en Allah contre Satan et se taire aussitôt"},
      {'ar': "أستبدل اللفظ البذيء بكلمة طيبة جاهزة مثل سبحان الله أو لا حول ولا قوة إلا بالله", 'en': "Replace the bad word with a ready good word like SubhanAllah or there is no power except by Allah", 'fr': "Remplacer le gros mot par une bonne parole prête comme SubhanAllah ou nulle force sauf par Allah"},
      {'ar': "أضغط على لساني بأسناني وأشرب جرعة ماء قبل أن أنطق بأي رد", 'en': "Press the tongue between the teeth and sip water before uttering any reply", 'fr': "Serrer la langue entre les dents et boire une gorgée d'eau avant toute réponse"},
      {'ar': "أتوضأ أو أغير مكاني وأجلس إن كنت واقفا حتى يسكن الغضب", 'en': "Make wudu or change your spot and sit down if standing until the anger settles", 'fr': "Faire les ablutions ou changer de place et s'asseoir si debout jusqu'à ce que la colère s'apaise"},
      {'ar': "أعتذر فورا وأستغفر بعد أي زلة لسان لأكسر دافع التكرار", 'en': "Apologize at once and seek forgiveness after any slip to break the urge to repeat", 'fr': "S'excuser aussitôt et demander pardon après tout écart pour briser l'envie de recommencer"},
    ],
    environment: [
      {'ar': "أبتعد عن المجالس والمحادثات التي يكثر فيها السب والكلام البذيء", 'en': "Avoid gatherings and chats where cursing and foul talk are common", 'fr': "Éviter les réunions et discussions où les insultes et le langage grossier sont fréquents"},
      {'ar': "أكتم الحسابات والمقاطع التي تطبع الألفاظ النابية وأتابع محتوى نظيف اللسان", 'en': "Mute accounts and clips that normalize foul words and follow clean spoken content", 'fr': "Couper les comptes et vidéos qui banalisent les gros mots et suivre du contenu au langage propre"},
      {'ar': "أضع تذكيرا مرئيا قرب مكتبي ولوحة هاتفي بفضل حفظ اللسان", 'en': "Place a visible reminder near your desk and phone wallpaper about guarding the tongue", 'fr': "Placer un rappel visible près du bureau et en fond d'écran sur la préservation de la langue"},
      {'ar': "أحدد كلمة بديلة متفقا عليها مع الأهل ينبهونني بها فور بدء أي لفظ سيئ", 'en': "Agree on a code word with family that they say to alert me the moment a bad word starts", 'fr': "Convenir d'un mot code avec la famille qu'ils diront pour m'alerter dès qu'un gros mot commence"},
    ],
  ),
  'impulse_buying': HabitChecklists(
    competingResponses: [
      {'ar': "أؤجل أي شراء أربعا وعشرين ساعة قبل أن أقرره", 'en': "I delay any purchase for 24 hours before deciding", 'fr': "Je reporte tout achat de 24 heures avant de décider"},
      {'ar': "أكتب الحاجة في قائمة واحدة ولا أشتري إلا منها", 'en': "I write the item on a single list and buy only from it", 'fr': "J'écris l'article sur une seule liste et n'achète qu'à partir de celle-ci"},
      {'ar': "أسأل نفسي هل أملك بديلا يكفيني قبل الدفع", 'en': "I ask myself if I already own a sufficient alternative before paying", 'fr': "Je me demande si je possède déjà une alternative suffisante avant de payer"},
      {'ar': "أحول مبلغ الشراء إلى صدقة أو ادخار فورا", 'en': "I move the purchase amount into charity or savings right away", 'fr': "Je transfère aussitôt le montant de l'achat vers une aumône ou une épargne"},
      {'ar': "أردد الاستعاذة وأخرج من المتجر أو أغلق التطبيق", 'en': "I say the isti adha and leave the store or close the app", 'fr': "Je dis l'isti'adha et je quitte le magasin ou ferme l'application"},
    ],
    environment: [
      {'ar': "أحذف تطبيقات التسوق وأزيل بيانات البطاقة المحفوظة", 'en': "I delete shopping apps and remove saved card details", 'fr': "Je supprime les applications d'achat et les coordonnées de carte enregistrées"},
      {'ar': "ألغي الاشتراك في رسائل العروض والتنبيهات الترويجية", 'en': "I unsubscribe from sales emails and promotional alerts", 'fr': "Je me désabonne des courriels de soldes et des alertes promotionnelles"},
      {'ar': "أخرج بميزانية نقدية محددة وأترك البطاقات في البيت", 'en': "I go out with a fixed cash budget and leave cards at home", 'fr': "Je sors avec un budget en espèces fixe et laisse les cartes à la maison"},
      {'ar': "أتجنب الأسواق ومواقع التسوق عند الفراغ أو الضيق", 'en': "I avoid malls and shopping sites when idle or stressed", 'fr': "J'évite les centres commerciaux et sites d'achat quand je m'ennuie ou suis stressé"},
    ],
  ),
  'caffeine_excess': HabitChecklists(
    competingResponses: [
      {'ar': "اشرب كوب ماء أو شاي أعشاب خالٍ من الكافيين عند اشتداد الرغبة.", 'en': "Drink a glass of water or caffeine-free herbal tea when the craving hits.", 'fr': "Bois un verre d'eau ou une tisane sans cafeine des que l'envie surgit."},
      {'ar': "امش دقيقتين أو افعل تمارين تنفس عميق بدل احتساء فنجان جديد.", 'en': "Take a two-minute walk or do deep breathing instead of brewing another cup.", 'fr': "Fais une marche de deux minutes ou respire profondement au lieu de preparer une autre tasse."},
      {'ar': "تناول وجبة خفيفة فيها بروتين لرفع طاقتك بدل الاعتماد على الكافيين.", 'en': "Eat a protein-rich snack to lift your energy instead of relying on caffeine.", 'fr': "Mange une collation riche en proteines pour remonter ton energie au lieu de la cafeine."},
      {'ar': "استبدل القهوة بمشروب دافئ منزوع الكافيين واحتفظ بطقس الفنجان نفسه.", 'en': "Swap the coffee for a warm decaf drink and keep the same cup ritual.", 'fr': "Remplace le cafe par une boisson chaude decafeinee en gardant le meme rituel de la tasse."},
      {'ar': "اذكر الله بتسبيحة قصيرة وانتظر عشر دقائق فقد تزول الرغبة.", 'en': "Say a brief dhikr and wait ten minutes; the urge often passes.", 'fr': "Fais un court dhikr et attends dix minutes; l'envie passe souvent."},
    ],
    environment: [
      {'ar': "احتفظ بزجاجة ماء بارد في متناول يدك على المكتب طوال اليوم.", 'en': "Keep a bottle of cold water within reach on your desk all day.", 'fr': "Garde une bouteille d'eau fraiche a portee de main sur ton bureau toute la journee."},
      {'ar': "لا تحتفظ بحبوب القهوة وكبسولات الكافيين إلا بكمية قليلة في البيت.", 'en': "Keep only a small amount of coffee beans and caffeine pods at home.", 'fr': "Ne garde qu'une petite quantite de grains de cafe et de capsules a la maison."},
      {'ar': "لا تشرب أي كافيين بعد العصر لحماية نومك وتقليل الحاجة إليه.", 'en': "Avoid all caffeine after mid-afternoon to protect your sleep and lower your need for it.", 'fr': "Evite toute cafeine apres le milieu de l'apres-midi pour proteger ton sommeil."},
      {'ar': "تجنّب الطريق المار بالمقهى وأبعد آلة القهوة عن مجال نظرك.", 'en': "Avoid the route that passes the cafe and move the coffee machine out of sight.", 'fr': "Evite le chemin qui passe devant le cafe et range la machine a cafe hors de vue."},
    ],
  ),
  'late_nights': HabitChecklists(
    competingResponses: [
      {'ar': "أطفئ الأنوار وأستلقي في الفراش", 'en': "Turn off the lights and lie down in bed", 'fr': "Éteindre les lumières et m'allonger au lit"},
      {'ar': "أضع الهاتف بعيداً وأقرأ أذكار النوم", 'en': "Put the phone away and read the sleep adhkar", 'fr': "Ranger le téléphone et lire les invocations du coucher"},
      {'ar': "أشرب كوب ماء دافئ وأتنفّس بهدوء", 'en': "Drink a warm glass of water and breathe calmly", 'fr': "Boire un verre d'eau tiède et respirer calmement"},
      {'ar': "أكتب ما يشغل بالي في ورقة لأفرّغ ذهني", 'en': "Write down what's on my mind to clear my head", 'fr': "Noter ce qui m'occupe l'esprit pour me libérer"},
      {'ar': "أتوضأ وأصلّي ركعتين خفيفتين ثم أنام", 'en': "Make wudu, pray two light rak'ahs, then sleep", 'fr': "Faire les ablutions, prier deux rak'ahs, puis dormir"},
    ],
    environment: [
      {'ar': "اضبط منبّهاً لموعد النوم قبله بنصف ساعة", 'en': "Set an alarm half an hour before bedtime", 'fr': "Régler une alarme une demi-heure avant le coucher"},
      {'ar': "اشحن الهاتف خارج غرفة النوم", 'en': "Charge your phone outside the bedroom", 'fr': "Charger le téléphone hors de la chambre"},
      {'ar': "خفّت الإضاءة وأطفئ الشاشات مساءً", 'en': "Dim the lights and switch off screens in the evening", 'fr': "Tamiser les lumières et éteindre les écrans le soir"},
      {'ar': "تجنّب القهوة والمنبّهات بعد العصر", 'en': "Avoid coffee and stimulants after afternoon", 'fr': "Éviter le café et les stimulants après l'après-midi"},
    ],
  ),
  'binge_watching': HabitChecklists(
    competingResponses: [
      {'ar': "أغلق التطبيق وأضع الجهاز في غرفة أخرى", 'en': "Close the app and leave the device in another room", 'fr': "Fermer l'application et laisser l'appareil dans une autre pièce"},
      {'ar': "أقرأ صفحات من كتاب أو وِرد القرآن", 'en': "Read a few pages of a book or my Qur'an portion", 'fr': "Lire quelques pages d'un livre ou ma portion de Coran"},
      {'ar': "أقوم بنزهة قصيرة أو تمرين سريع", 'en': "Take a short walk or do a quick workout", 'fr': "Faire une courte marche ou un exercice rapide"},
      {'ar': "أتواصل مع أهلي أو صديق بدل الشاشة", 'en': "Connect with family or a friend instead of the screen", 'fr': "Échanger avec ma famille ou un ami au lieu de l'écran"},
      {'ar': "أنجز مهمة مؤجّلة لمدة عشر دقائق", 'en': "Spend ten minutes on a postponed task", 'fr': "Consacrer dix minutes à une tâche reportée"},
    ],
    environment: [
      {'ar': "احذف تطبيقات المشاهدة أو سجّل الخروج منها", 'en': "Delete the streaming apps or sign out of them", 'fr': "Supprimer les applications de streaming ou s'en déconnecter"},
      {'ar': "أوقف التشغيل التلقائي للحلقات والمقاطع", 'en': "Turn off autoplay for episodes and clips", 'fr': "Désactiver la lecture automatique des épisodes et clips"},
      {'ar': "حدّد وقتاً ومدّة معلومة للمشاهدة", 'en': "Set a fixed time and limit for watching", 'fr': "Fixer une heure et une durée précises de visionnage"},
      {'ar': "اجعل غرفتك بلا تلفاز أثناء العمل والمذاكرة", 'en': "Keep your room screen-free during work and study", 'fr': "Garder votre pièce sans écran pendant le travail et l'étude"},
    ],
  ),
  'anger': HabitChecklists(
    competingResponses: [
      {'ar': "أقول أعوذ بالله من الشيطان الرجيم", 'en': "Say: I seek refuge in God from Satan", 'fr': "Dire : je cherche refuge en Dieu contre Satan"},
      {'ar': "أتنفّس بعمق وأعدّ إلى العشرة قبل الرد", 'en': "Breathe deeply and count to ten before responding", 'fr': "Respirer profondément et compter jusqu'à dix avant de répondre"},
      {'ar': "أغيّر وضعي: إن كنت قائماً جلست", 'en': "Change my posture: if standing, I sit down", 'fr': "Changer de position : debout, je m'assois"},
      {'ar': "أبتعد عن الموقف وأتوضأ بماء بارد", 'en': "Step away from the situation and make wudu with cool water", 'fr': "M'éloigner de la situation et faire les ablutions à l'eau fraîche"},
      {'ar': "أصمت ولا أتكلم حتى يهدأ غضبي", 'en': "Stay silent and don't speak until my anger settles", 'fr': "Garder le silence jusqu'à ce que ma colère s'apaise"},
    ],
    environment: [
      {'ar': "تجنّب النقاشات الحساسة وأنت متعب أو جائع", 'en': "Avoid sensitive discussions when tired or hungry", 'fr': "Éviter les discussions sensibles quand on est fatigué ou affamé"},
      {'ar': "اتفق مع المقرّبين على إشارة للتهدئة", 'en': "Agree on a calming signal with those close to you", 'fr': "Convenir d'un signal d'apaisement avec vos proches"},
      {'ar': "قلّل المثيرات: ابتعد عن مصادر الاستفزاز", 'en': "Reduce triggers: stay away from provoking sources", 'fr': "Réduire les déclencheurs : s'éloigner des sources de provocation"},
      {'ar': "خذ قسطاً كافياً من النوم لتقليل التوتر", 'en': "Get enough sleep to lower your stress", 'fr': "Dormir suffisamment pour réduire le stress"},
    ],
  ),
};

// Scholar-video search query per break habit (Arabic). Built into a YouTube
// search URL at runtime; shown only when the device is online.
const Map<String, String> kHabitVideoQuery = {
  'quit_smoking': "مصطفى العدوي حكم التدخين والإقلاع عن السجائر",
  'quit_vaping': "مصطفى العدوي حكم السجائر الإلكترونية الفيب والتدخين",
  'nail_biting': "مصطفى العدوي حكم قضم الأظافر",
  'hair_pulling': "عبدالرحمن ذاكر الهاشمي علاج الوسواس القهري والعادات القهرية",
  'skin_picking': "عبدالرحمن ذاكر الهاشمي علاج القلق والتوتر والعادات القهرية",
  'phone_addiction': "مصطفى العدوي حكم إضاعة الوقت في الجوال ووسائل التواصل",
  'excessive_gaming': "مصطفى العدوي حكم إضاعة الوقت في الألعاب الإلكترونية",
  'procrastination': "التسويف وتأخير العمل عبدالرحمن ذاكر الهاشمي",
  'junk_food': "مصطفى العدوي الإسراف في الأكل وكثرة الشبع وذم الشره",
  'oversleeping': "مصطفى العدوي علاج كثرة النوم والكسل عن العبادة",
  'gossip': "مصطفى العدوي التحذير من الغيبة والنميمة وحفظ اللسان",
  'bad_language': "مصطفى العدوي حفظ اللسان والسب والشتم",
  'impulse_buying': "مصطفى العدوي الإسراف والتبذير في الشراء والإنفاق",
  'caffeine_excess': "مصطفى العدوي الاعتدال وعدم الإسراف في الطعام والشراب",
  'late_nights': "مفاسد السهر وأهمية النوم المبكر مصطفى العدوي",
  'binge_watching': "حكم إضاعة الوقت في المشاهدة مصطفى العدوي",
  'anger': "علاج الغضب وكظم الغيظ مصطفى العدوي",
};
