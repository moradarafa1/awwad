import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// AnalyticsService asserts that every event name is in its allow-list. Asserts
// are stripped from release builds, so a missing name is invisible in
// production and crashes only in debug, on whatever screen happens to fire it.
//
// That is exactly what had happened to `sos_slipped`: fired from the SOS
// screen, never allow-listed, and it would have crashed a debug build the
// moment a user tapped «تعثرت». Found on 2026-07-20 by auditing events
// actually fired against the plan.
//
// This test does that audit automatically, by reading the source: every
// `track('...')` in lib/ must appear in the allow-list.
void main() {
  test('every event fired in lib/ is allow-listed', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the app/ directory');

    final allowlistSrc =
        File('lib/core/analytics/analytics.dart').readAsStringSync();
    final allowStart = allowlistSrc.indexOf('_allowed = {');
    expect(allowStart, greaterThan(-1), reason: 'allow-list not found');
    final allowBlock = allowlistSrc.substring(
        allowStart, allowlistSrc.indexOf('};', allowStart));
    final allowed = RegExp("'([a-z_]+)'")
        .allMatches(allowBlock)
        .map((m) => m.group(1)!)
        .toSet();
    expect(allowed, isNotEmpty);

    // `track(` and its name are sometimes split across lines, so match across
    // whitespace rather than line by line.
    final fired = <String, String>{}; // event -> file it is fired from
    final callRe = RegExp(r"track\(\s*'([a-z_]+)'");
    for (final f in libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      for (final m in callRe.allMatches(src)) {
        fired.putIfAbsent(m.group(1)!, () => f.path);
      }
    }
    expect(fired, isNotEmpty, reason: 'no track() calls found at all');

    final missing = fired.entries
        .where((e) => !allowed.contains(e.key))
        .map((e) => '${e.key} (fired from ${e.value})')
        .toList();
    expect(missing, isEmpty,
        reason: 'these events would trip the assert in a debug build: $missing');
  });
}
