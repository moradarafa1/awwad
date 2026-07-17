// Quran listening-wird data (TODO 0d Phase B). Reciters come from the bundled
// assets/data/reciters.json (mp3quran.net servers, 50 qaris); the 114 surah
// names are inline. Audio files follow mp3quran's convention:
//   {reciter.server}/{surahNumber padded to 3}.mp3   e.g. .../minsh/002.mp3
// Pure data + URL builder so it is unit-testable without any audio plugin.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Reciter {
  final int id;
  final String nameAr;
  final String server; // ends with '/'
  final String rewaya;
  const Reciter(this.id, this.nameAr, this.server, this.rewaya);
}

List<Reciter>? _reciters;

Future<List<Reciter>> loadReciters() async {
  if (_reciters != null) return _reciters!;
  final raw = await rootBundle.loadString('assets/data/reciters.json');
  final list = jsonDecode(raw) as List<dynamic>;
  _reciters = [
    for (final r in list.cast<Map<String, dynamic>>())
      Reciter(
        (r['id'] as num).toInt(),
        r['name_ar'] as String,
        (r['server'] as String).endsWith('/')
            ? r['server'] as String
            : '${r['server']}/',
        r['rewaya'] as String? ?? '',
      ),
  ];
  return _reciters!;
}

/// The streaming URL for [surah] (1..114) by [reciter].
String surahUrl(Reciter reciter, int surah) {
  final n = surah.toString().padLeft(3, '0');
  return '${reciter.server}$n.mp3';
}

/// Arabic surah names, index 0 = Al-Fatiha (surah 1).
const List<String> kSurahNames = [
  'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
  'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
  'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
  'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان',
  'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
  'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
  'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة',
  'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون',
  'التغابن', 'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح',
  'الجن', 'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ',
  'النازعات', 'عبس', 'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج',
  'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى',
  'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
  'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون',
  'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس',
];

String surahName(int surah) =>
    (surah >= 1 && surah <= 114) ? kSurahNames[surah - 1] : '$surah';
