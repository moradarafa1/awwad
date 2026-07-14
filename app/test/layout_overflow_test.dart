import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/app/theme.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/l10n/app_localizations.dart';
import 'package:awwad/features/auth/auth_choice_screen.dart';
import 'package:awwad/features/home/add_habit_screen.dart';
import 'package:awwad/features/home/badges_screen.dart';
import 'package:awwad/features/home/daily_log_screen.dart';
import 'package:awwad/features/home/habits_screen.dart';
import 'package:awwad/features/home/profile_screen.dart';
import 'package:awwad/features/home/settings_screen.dart';
import 'package:awwad/features/home/stats_screen.dart';
import 'package:awwad/features/onboarding/onboarding_flow.dart';
import 'package:awwad/features/pomodoro/pomodoro_screen.dart';

// Layout regressions this suite locks down (found by the button-overflow audit,
// 2026-07-14). They only reproduce on a NARROW screen and/or with the OS font
// scaled up, which is exactly what these tests simulate.
//
// The one that shipped broken: the Pomodoro Reset button carried
// `minimumSize: Size.fromHeight(52)` == an INFINITE minimum width, inside a Row
// (which hands non-flex children unbounded width) -> "BoxConstraints forces an
// infinite width" on EVERY frame, in every locale.

Widget _wrap(Widget child,
        {required Locale locale, LocalStore? store}) =>
    ProviderScope(
      overrides: [
        if (store != null) localStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(
        locale: locale,
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

/// Pumps [child] on the narrowest supported phone (320dp) with the OS font
/// scaled up, the combination under which every confirmed overflow appeared.
Future<void> _pumpTight(WidgetTester tester, Widget child,
    {required Locale locale, LocalStore? store, double scale = 1.3}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(320, 640),
        textScaler: TextScaler.linear(scale),
      ),
      child: _wrap(child, locale: locale, store: store),
    ),
  );
  await tester.pump();
}

/// A store holding one habit whose slider labels are the longest a user could
/// type (the add-habit fields cap at 30 characters).
Future<LocalStore> _storeWithLongLabels() async {
  final habit = Habit(
    id: 'h1',
    track: 'build',
    isCustom: true,
    title: 'قراءة كتاب قبل النوم كل ليلة',
    customMetricPrimary: 'عدد الصفحات التي قرأتها اليوم',
    customMetricSecondary: 'جودة التركيز أثناء القراءة',
    createdAt: DateTime(2026, 1, 1),
  );
  SharedPreferences.setMockInitialValues({
    'awwad_habits': jsonEncode([habit.toJson()]),
    'awwad_settings': jsonEncode(const AppSettings(
      locale: 'ar',
      onboardingDone: true,
      authChoiceMade: true,
      activeHabitId: 'h1',
    ).toJson()),
  });
  return LocalStore(await SharedPreferences.getInstance());
}

/// The same habit plus a fortnight of entries (one excused day, some slips, a
/// note and a mood) so Stats renders its charts, cards and history rows.
Future<LocalStore> _storeWithHistory() async {
  final habit = Habit(
    id: 'h1',
    track: 'break',
    catalogKey: 'secret_habit',
    title: 'الإقلاع عن التدخين نهائياً بإذن الله',
    reason: 'صحتي وأسرتي',
    costPerDay: 45,
    createdAt: DateTime(2026, 6, 1),
  );
  String k(int d) => dayKey(DateTime.now().subtract(Duration(days: d)));
  final entries = [
    for (var i = 0; i < 12; i++)
      DailyEntry(
        id: 'e$i',
        habitId: 'h1',
        date: k(i),
        urge: 3 + (i % 6),
        resistance: 4 + (i % 5),
        didSlip: i % 5 == 0,
        entryType: i == 3 ? 'skip' : 'log',
        trigger: i % 5 == 0 ? 'stress' : null,
        moodEmoji: '😌',
        moodLabel: 'هادئ',
        note: 'ملاحظة اليوم عن سبب التعثر وما تعلمته منه',
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ),
  ];
  SharedPreferences.setMockInitialValues({
    'awwad_habits': jsonEncode([habit.toJson()]),
    'awwad_entries': jsonEncode(entries.map((e) => e.toJson()).toList()),
    'awwad_settings': jsonEncode(const AppSettings(
      locale: 'ar',
      onboardingDone: true,
      authChoiceMade: true,
      activeHabitId: 'h1',
    ).toJson()),
  });
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  group('pomodoro layout', () {
    // 320x640 = the narrowest phone we support; 1.3 = a common Android
    // large-text setting. French carries the longest labels.
    for (final locale in const [Locale('ar'), Locale('en'), Locale('fr')]) {
      testWidgets('renders without layout exceptions (${locale.languageCode}, '
          'narrow screen, large text)', (tester) async {
        await _pumpTight(tester, const PomodoroScreen(), locale: locale);
        // Any RenderFlex overflow / infinite-constraint error surfaces here.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reset button declares a finite minimum width', (tester) async {
      await tester.pumpWidget(
          _wrap(const PomodoroScreen(), locale: const Locale('ar')));

      final reset = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final minSize = reset.style?.minimumSize?.resolve({});
      expect(minSize, isNotNull);
      expect(minSize!.width.isFinite, isTrue,
          reason: 'an infinite min width inside a Row breaks the whole screen');
    });
  });

  group('daily log layout', () {
    testWidgets('30-char custom slider labels do not overflow the row',
        (tester) async {
      final store = await _storeWithLongLabels();
      // DailyLogScreen is a tab body: it relies on HomeShell's Scaffold.
      await _pumpTight(tester, const Scaffold(body: DailyLogScreen()),
          locale: const Locale('ar'), store: store);
      expect(tester.takeException(), isNull);
    });
  });

  // Screens the empirical sweep found broken at 320dp / 1.3x (the badge grids
  // and the French section headers were broken even at the default scale).
  group('narrow-screen + large-text sweep', () {
    final screens = <String, Widget>{
      'badges': const Scaffold(body: BadgesScreen()),
      'profile': const ProfileScreen(),
      'habits': const HabitsScreen(),
      'settings': const Scaffold(body: SettingsScreen()),
      'auth choice': const AuthChoiceScreen(),
    };
    for (final entry in screens.entries) {
      for (final locale in const [Locale('ar'), Locale('en'), Locale('fr')]) {
        testWidgets('${entry.key} (${locale.languageCode})', (tester) async {
          final store = await _storeWithLongLabels();
          await _pumpTight(tester, entry.value, locale: locale, store: store);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  // Stats (with its history sub-tab) and the onboarding flow: the history rows
  // and the chart/heatmap legends overflowed in every locale.
  group('stats, history and onboarding', () {
    for (final locale in const [Locale('ar'), Locale('en'), Locale('fr')]) {
      testWidgets('stats + history sub-tab (${locale.languageCode})',
          (tester) async {
        final store = await _storeWithHistory();
        await _pumpTight(tester, const Scaffold(body: StatsScreen()),
            locale: locale, store: store);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
        await tester.pump();
        expect(tester.takeException(), isNull);

        // The history list is a sub-tab of Stats, not its own screen.
        final container =
            ProviderScope.containerOf(tester.element(find.byType(StatsScreen)));
        container.read(statsSubTabProvider.notifier).state = 1;
        await tester.pump();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('onboarding steps (${locale.languageCode})', (tester) async {
        SharedPreferences.setMockInitialValues({
          'awwad_settings': jsonEncode(
              AppSettings(locale: locale.languageCode, authChoiceMade: true)
                  .toJson()),
        });
        final store = LocalStore(await SharedPreferences.getInstance());
        await _pumpTight(tester, const OnboardingFlow(),
            locale: locale, store: store);
        for (var step = 0; step < 3; step++) {
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.first, const Offset(0, -600));
            await tester.pump();
          }
          final next = find.byType(FilledButton);
          if (next.evaluate().isNotEmpty) {
            await tester.tap(next.last, warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 400));
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('add-habit picker layout', () {
    // The catalog carries the longest titles in the app (fr
    // "Trichotillomanie (arrachage des cheveux)"), rendered as pills in a Wrap.
    for (final locale in const [Locale('ar'), Locale('fr')]) {
      testWidgets('catalog pills do not overflow (${locale.languageCode})',
          (tester) async {
        final store = await _storeWithLongLabels();
        await _pumpTight(tester, const AddHabitScreen(),
            locale: locale, store: store);
        // The screen opens with the "focus on one goal" advisory dialog.
        await tester.pumpAndSettle();
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          await tester.tap(find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
          await tester.pumpAndSettle();
        }
        // Land on the picker: pick the break track (the long fr titles live
        // there). The track cards are emoji-labelled and sit below the fold on
        // a 320x640 screen.
        await tester.scrollUntilVisible(find.text('🚭'), 120,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('🚭'));
        await tester.pumpAndSettle();
        expect(find.byType(Wrap), findsWidgets); // the picker is showing
        expect(tester.takeException(), isNull);
      });
    }
  });
}
