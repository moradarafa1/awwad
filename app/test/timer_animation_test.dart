import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/app/theme.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/l10n/app_localizations.dart';
import 'package:awwad/features/pomodoro/pomodoro_screen.dart';
import 'package:awwad/features/sos/sos_screen.dart';

// The two timers must feel ALIVE while they run: the Pomodoro ring sweeps
// continuously (not a once-per-second jump) with a breathing glow and a head
// dot, and the SOS «هُدنة» screen breathes with expanding urge-wave rings.
// These tests prove the animation actually advances, and that Pomodoro goes
// perfectly still when paused (no battery drain on an idle screen).

Widget _wrap(Widget child, LocalStore store) => ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        locale: const Locale('ar'),
        theme: buildAwwadTheme(dark: true),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

double _ringValue(WidgetTester tester) => tester
    .widgetList<CircularProgressIndicator>(find.byType(CircularProgressIndicator))
    .first
    .value!;

void main() {
  group('pomodoro dial animation', () {
    testWidgets('idle dial is completely still', (tester) async {
      await tester.pumpWidget(_wrap(const PomodoroScreen(), await _store()));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0,
          reason: 'an idle timer must not schedule frames');
    });

    testWidgets('running dial animates, and the ring sweeps between seconds',
        (tester) async {
      await tester.pumpWidget(_wrap(const PomodoroScreen(), await _store()));
      await tester.tap(find.byType(FilledButton)); // start
      await tester.pump();

      expect(tester.binding.transientCallbackCount, greaterThan(0),
          reason: 'the glow + sweep must be animating while running');

      // Sub-second progress: let real time pass, then compare two frames.
      final before = _ringValue(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();
      final after = _ringValue(tester);
      expect(after, greaterThan(before),
          reason: 'the ring must move WITHIN a second, not step once per tick');
      expect(after - before, lessThan(0.05),
          reason: 'and it must creep, not jump');
    });

    testWidgets('pausing stops every animation', (tester) async {
      await tester.pumpWidget(_wrap(const PomodoroScreen(), await _store()));
      await tester.tap(find.byType(FilledButton)); // start
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.tap(find.byType(FilledButton)); // pause
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0,
          reason: 'a paused timer must go still');
    });
  });

  group('sos (هُدنة) animation', () {
    testWidgets('breathes and rides the urge wave from the moment it opens',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const SosScreen(habitId: 'none'), await _store()));
      await tester.pump();

      expect(tester.binding.transientCallbackCount, greaterThan(0),
          reason: 'breathing circle + ripple rings must animate on open');

      // The 5-minute wave ring fills smoothly (sub-second), like the dial.
      final before = _ringValue(tester);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();
      expect(_ringValue(tester), greaterThan(before),
          reason: 'the wave ring must creep forward, not tick');
    });
  });
}
