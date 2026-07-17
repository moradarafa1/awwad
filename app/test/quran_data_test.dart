import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/quran/quran_data.dart';

// The Quran-wird URL builder and surah names must be exact: a wrong URL means
// no audio, and the 114 names must be complete and correctly indexed.

void main() {
  test('114 surah names, correctly indexed', () {
    expect(kSurahNames.length, 114);
    expect(surahName(1), 'الفاتحة');
    expect(surahName(18), 'الكهف');
    expect(surahName(114), 'الناس');
    expect(surahName(0), '0'); // out of range guarded
    expect(surahName(115), '115');
  });

  test('surah URL follows the mp3quran 3-digit convention', () {
    const r = Reciter(112, 'المنشاوي', 'https://server10.mp3quran.net/minsh/',
        'حفص عن عاصم');
    expect(surahUrl(r, 2), 'https://server10.mp3quran.net/minsh/002.mp3');
    expect(surahUrl(r, 18), 'https://server10.mp3quran.net/minsh/018.mp3');
    expect(surahUrl(r, 114), 'https://server10.mp3quran.net/minsh/114.mp3');
  });

  test('reciter server ending with a slash builds the file number cleanly', () {
    expect(surahUrl(const Reciter(1, 'x', 'https://s.net/a/', 'r'), 1),
        'https://s.net/a/001.mp3');
  });
}
