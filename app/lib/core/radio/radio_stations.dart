// Live Islamic radio stations for the listening habits (hadith + Quran). These
// are PLAY-ONLY live streams (a tuner, not a download): public broadcasts from
// the Saudi Broadcasting Authority via the qurango.net / radiojar CDNs, the
// same feeds behind قناة/إذاعة السنة النبوية. No audio is bundled or
// redistributed. URLs verified live 2026-07-18.

class RadioStation {
  final String id;
  final Map<String, String> name;
  final String url;
  final String category; // 'hadith' | 'quran'
  const RadioStation(this.id, this.name, this.url, this.category);

  String t(String loc) => name[loc] ?? name['ar'] ?? id;
}

const List<RadioStation> kRadioStations = [
  // ----- Hadith / Sunnah (the قناة السنة النبوية experience) -----
  RadioStation(
    'bukhari',
    {'ar': 'صحيح البخاري', 'en': 'Sahih al-Bukhari', 'fr': 'Sahih al-Bukhari'},
    'https://backup.qurango.net/radio/saheh-bokharee',
    'hadith',
  ),
  RadioStation(
    'muslim',
    {'ar': 'صحيح مسلم', 'en': 'Sahih Muslim', 'fr': 'Sahih Muslim'},
    'https://backup.qurango.net/radio/saheh-muslim',
    'hadith',
  ),
  RadioStation(
    'riyad',
    {
      'ar': 'رياض الصالحين',
      'en': 'Riyad as-Salihin',
      'fr': 'Riyad as-Salihin'
    },
    'https://backup.qurango.net/radio/riyad',
    'hadith',
  ),
  RadioStation(
    'seerah',
    {
      'ar': 'في ظلال السيرة النبوية',
      'en': 'The Prophetic Biography',
      'fr': 'La biographie prophétique'
    },
    'https://backup.qurango.net/radio/fi_zilal_alsiyra',
    'hadith',
  ),
  // ----- Quran radio -----
  RadioStation(
    'quran_ksa',
    {
      'ar': 'إذاعة القرآن الكريم - السعودية',
      'en': 'Holy Quran Radio (KSA)',
      'fr': 'Radio du Saint Coran (KSA)'
    },
    'https://stream.radiojar.com/0tpy1h0kxtzuv',
    'quran',
  ),
  RadioStation(
    'khashaa',
    {
      'ar': 'تلاوات خاشعة',
      'en': 'Humble recitations',
      'fr': 'Récitations recueillies'
    },
    'https://backup.qurango.net/radio/salma',
    'quran',
  ),
  RadioStation(
    'tafseer',
    {
      'ar': 'تفسير القرآن الكريم',
      'en': 'Quran tafsir',
      'fr': 'Exégèse du Coran'
    },
    'https://backup.qurango.net/radio/tafseer',
    'quran',
  ),
];

List<RadioStation> radioByCategory(String category) =>
    kRadioStations.where((s) => s.category == category).toList();
