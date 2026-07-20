import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The audio session existed as a fully written file with ZERO call sites for
// a while: the fix for «الصوت منخفض جداً» was real code that never ran.
// This test asserts the wiring, not the implementation, because the wiring is
// the part that silently rots.
void main() {
  test('every audio player configures the session before playing', () {
    const players = [
      'lib/features/quran/quran_player_screen.dart',
      'lib/features/radio/radio_player_screen.dart',
    ];
    for (final path in players) {
      final src = _read(path);
      expect(src.contains('AwwadAudioSession.ensureConfigured'), isTrue,
          reason: '$path plays audio without requesting audio focus, so it '
              'will come out at notification volume on a real device');
      // Focus must be requested BEFORE the source is set, or the first track
      // of a session is still routed wrongly.
      final focusAt = src.indexOf('AwwadAudioSession.ensureConfigured');
      final sourceAt = src.indexOf('setUrl');
      expect(focusAt, lessThan(sourceAt),
          reason: '$path requests focus after setting the source');
    }
  });
}

String _read(String relative) {
  final file = File('${Directory.current.path}/$relative');
  return file.readAsStringSync();
}
