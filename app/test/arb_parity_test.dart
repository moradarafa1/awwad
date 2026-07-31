// Language audit lock (owner report 2026-07-31): every official translation
// file must carry EXACTLY the same key set, or a missing key silently falls
// back to the template language and the UI mixes languages. This reads the
// real .arb files from disk, so adding a key to one file only fails here.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ar/en/fr .arb files are key-identical', () {
    Set<String> keysOf(String name) {
      final raw = File('lib/l10n/$name').readAsStringSync();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.keys.where((k) => !k.startsWith('@')).toSet();
    }

    final ar = keysOf('app_ar.arb');
    final en = keysOf('app_en.arb');
    final fr = keysOf('app_fr.arb');
    expect(en.difference(ar), isEmpty, reason: 'en has keys ar lacks');
    expect(ar.difference(en), isEmpty, reason: 'en is missing keys');
    expect(fr.difference(ar), isEmpty, reason: 'fr has keys ar lacks');
    expect(ar.difference(fr), isEmpty, reason: 'fr is missing keys');
    expect(ar, isNotEmpty);
  });

  test('no widget reads the DEVICE locale for UI text', () {
    // Localizations.localeOf(context) is the app language; the device locale
    // (platformDispatcher.locale) ignores the in-app language switch and was
    // one of the real mixing sources (permissions_primer, fixed 2026-07-31).
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      // Comment lines don't count: the fix site documents WHY the device
      // locale is banned, and that prose must not trip its own guard.
      final code = f
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      if (code.contains('platformDispatcher.locale')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'UI text must follow the APP locale, not the device locale');
  });
}
