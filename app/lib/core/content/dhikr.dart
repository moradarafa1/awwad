// The daily morning dhikr carried by the Ibrahimic-prayer notification.
//
// Text is the الصلاة الإبراهيمية exactly as narrated in Sahih Muslim 405
// (Abu Mas'ud al-Ansari). Verified word-for-word against sunnah.com/muslim:405
// and corroborating sources. The body stays Arabic in every locale (it is a
// dhikr, not UI copy); only the title localizes.

const String kIbrahimicPrayer =
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى آلِ إِبْرَاهِيمَ، '
    'وَبَارِكْ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى آلِ إِبْرَاهِيمَ '
    'فِي الْعَالَمِينَ، إِنَّكَ حَمِيدٌ مَجِيدٌ';

/// Source attribution for the dhikr (shown in Settings).
const String kIbrahimicPrayerSource = 'صحيح مسلم';

const Map<String, String> kDhikrTitle = {
  'ar': 'ذكرٌ يبدأ به يومك 🤍',
  'en': 'A dhikr to start your day 🤍',
  'fr': 'Un dhikr pour commencer la journée 🤍',
};
