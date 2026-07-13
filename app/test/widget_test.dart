import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/catalog/badge_catalog.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/features/home/month_heatmap.dart';
import 'package:awwad/core/platform/usage_stats.dart';
import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/catalog/motivation.dart';

// Lightweight unit tests for the offline core logic (no widgets needed yet).
// Streak / badge logic is the riskiest engineering in P1, so it is tested here.

DailyEntry _entry(String date, {bool slip = false}) => DailyEntry(
      id: date,
      habitId: 'h',
      date: date,
      urge: 5,
      resistance: 5,
      didSlip: slip,
      createdAt: DateTime.parse('$date 12:00:00'),
    );

void main() {
  group('badge evaluator', () {
    test('first log awards first_log badge', () {
      final earned =
          evaluateBadges(currentStreak: 1, daysLogged: 1, hasComeback: false);
      expect(earned, contains('first_log'));
      expect(earned.contains('streak_30_silver'), isFalse);
    });

    test('30-day streak awards silver shield', () {
      final earned =
          evaluateBadges(currentStreak: 30, daysLogged: 30, hasComeback: false);
      expect(earned, contains('streak_30_silver'));
      expect(earned, contains('streak_7'));
    });

    test('90-day streak awards diamond', () {
      final earned =
          evaluateBadges(currentStreak: 90, daysLogged: 90, hasComeback: false);
      expect(earned, contains('streak_90_diamond'));
    });
  });

  group('badge catalog', () {
    test('every badge key resolves', () {
      for (final b in kBadges) {
        expect(badgeByKey(b.key), isNotNull);
        expect(b.t('ar'), isNotEmpty);
        expect(b.t('en'), isNotEmpty);
        expect(b.t('fr'), isNotEmpty);
      }
    });
  });

  group('entry json roundtrip', () {
    test('serializes and deserializes', () {
      final e = _entry('2026-06-27', slip: true);
      final back = DailyEntry.fromJson(e.toJson());
      expect(back.date, e.date);
      expect(back.didSlip, true);
    });
  });

  group('multi-habit scoping', () {
    Habit habit(String id, String track) =>
        Habit(id: id, track: track, title: id, createdAt: DateTime(2026, 1, 1));
    DailyEntry entryFor(String habitId, String date, {bool slip = false}) =>
        DailyEntry(
            id: '$habitId-$date',
            habitId: habitId,
            date: date,
            urge: 5,
            resistance: 5,
            didSlip: slip,
            createdAt: DateTime.parse('$date 12:00:00'));

    test('stats are computed only for the active habit', () {
      // Relative dates: streaks are calendar-aware (a gap to today breaks
      // the CURRENT streak), so fixed old dates would read as broken.
      String k(int daysAgo) =>
          dayKey(DateTime.now().subtract(Duration(days: daysAgo)));
      final state = AppState(
        settings: const AppSettings(activeHabitId: 'a'),
        habits: [habit('a', 'break'), habit('b', 'build')],
        entries: [
          entryFor('a', k(0)),
          entryFor('a', k(1)),
          entryFor('b', k(0), slip: true),
        ],
      );
      expect(state.daysLogged, 2); // only habit a
      expect(state.currentStreak, 2);
      expect(state.activeEntries.every((e) => e.habitId == 'a'), isTrue);
    });

    test('per-track cap (max 3) is enforced', () {
      final three = [
        habit('a', 'break'),
        habit('b', 'break'),
        habit('c', 'break'),
      ];
      final state = AppState(
          settings: const AppSettings(), habits: three);
      expect(state.trackCount('break'), 3);
      expect(state.canAddTrack('break'), isFalse);
      expect(state.canAddTrack('build'), isTrue);
    });

    test('owned catalog keys are exposed for de-duping the picker', () {
      final state = AppState(
        settings: const AppSettings(),
        habits: [
          Habit(
              id: 'a',
              track: 'break',
              catalogKey: 'secret_habit',
              title: 'x',
              createdAt: DateTime(2026, 1, 1)),
        ],
      );
      expect(state.ownedCatalogKeys, contains('secret_habit'));
    });
  });

  group('month heatmap math', () {
    test('leading offset for Arabic week (Saturday start)', () {
      // July 2026 starts on Wednesday (weekday=3 -> Sun0-based 3).
      // Saturday-start week (firstDow=6): Sat,Sun,Mon,Tue lead -> 4 blanks.
      expect(leadingOffset(DateTime(2026, 7, 1), 6), 4);
      // A month starting exactly on Saturday has no blanks.
      expect(leadingOffset(DateTime(2026, 8, 1), 6), 0); // 1 Aug 2026 = Sat
    });

    test('leading offset for Monday/Sunday starts', () {
      // 1 July 2026 = Wednesday. Monday-start (firstDow=1) -> 2 blanks.
      expect(leadingOffset(DateTime(2026, 7, 1), 1), 2);
      // Sunday-start (firstDow=0) -> 3 blanks.
      expect(leadingOffset(DateTime(2026, 7, 1), 0), 3);
    });

    test('daysInMonth handles lengths and leap years', () {
      expect(daysInMonth(DateTime(2026, 7, 1)), 31);
      expect(daysInMonth(DateTime(2026, 2, 1)), 28);
      expect(daysInMonth(DateTime(2028, 2, 1)), 29); // leap year
      expect(daysInMonth(DateTime(2026, 12, 1)), 31);
      expect(daysInMonth(DateTime(2026, 4, 1)), 30);
    });

    test('skip days pass through; slips and GAPS break streaks', () {
      // Dates relative to the real clock: streaks are calendar-aware now.
      String k(int daysAgo) =>
          dayKey(DateTime.now().subtract(Duration(days: daysAgo)));
      AppState stateWith(List<DailyEntry> entries) => AppState(
            settings: const AppSettings(activeHabitId: 'h'),
            habits: [
              Habit(
                  id: 'h',
                  track: 'break',
                  title: 'x',
                  createdAt: DateTime(2026, 1, 1)),
            ],
            entries: entries,
          );
      DailyEntry skip(String date) => DailyEntry(
          id: 's$date', habitId: 'h', date: date, urge: 0, resistance: 0,
          didSlip: false, entryType: 'skip', createdAt: DateTime(2026, 1, 2));

      // clean(today), SKIP(-1), clean(-2), slip(-3): skip passes, slip breaks.
      final a = stateWith(
          [_entry(k(0)), skip(k(1)), _entry(k(2)), _entry(k(3), slip: true)]);
      expect(a.currentStreak, 2);
      expect(a.cleanDays, 2);
      expect(a.daysLogged, 3);
      expect(a.longestStreak, 2);

      // clean(today), clean(-3): the unexcused GAP breaks the streak.
      final b = stateWith([_entry(k(0)), _entry(k(3))]);
      expect(b.currentStreak, 1);
      expect(b.longestStreak, 1);

      // clean(-1), clean(-2), nothing today yet: pending today must not break.
      final c = stateWith([_entry(k(1)), _entry(k(2))]);
      expect(c.currentStreak, 2);
      expect(c.longestStreak, 2);
    });

    test('ranks resolve from streak with correct next rank', () {
      expect(rankForStreak(0).name['ar'], 'بذرة العزم');
      expect(rankForStreak(8).name['ar'], 'راسخ الأسبوع');
      expect(rankForStreak(90).name['ar'], 'قلب من ماس');
      expect(nextRank(8)!.minStreak, 14);
      expect(nextRank(500), isNull);
    });

    test('resolveMetrics priority: custom beats override beats default', () {
      // Custom labels win when BOTH are set.
      final custom = resolveMetrics(
          track: 'build',
          customPrimary: 'صفحات القراءة',
          customSecondary: 'التركيز',
          generatedOverride: kBreakMetrics);
      expect(custom.primary.l('ar'), 'صفحات القراءة');
      expect(custom.secondary.l('en'), 'التركيز');
      // One empty custom label -> falls back to the override.
      final override = resolveMetrics(
          track: 'build',
          customPrimary: 'x',
          customSecondary: '',
          generatedOverride: kBreakMetrics);
      expect(override.primary.l('ar'), kBreakMetrics.primary.l('ar'));
      // Nothing set -> track default.
      final def = resolveMetrics(track: 'build');
      expect(def.primary.l('ar'), kBuildMetrics.primary.l('ar'));
    });

    test('splitMinutes formats hours and minutes', () {
      expect(splitMinutes(0), (hours: 0, minutes: 0));
      expect(splitMinutes(59), (hours: 0, minutes: 59));
      expect(splitMinutes(60), (hours: 1, minutes: 0));
      expect(splitMinutes(145), (hours: 2, minutes: 25));
    });

    test('grid row count fits the month', () {
      // 4 leading blanks + 31 days = 35 cells -> exactly 5 rows.
      final leading = leadingOffset(DateTime(2026, 7, 1), 6);
      final rows = (leading + daysInMonth(DateTime(2026, 7, 1)) + 6) ~/ 7;
      expect(rows, 5);
      // Worst case: 31-day month starting on the last column -> 6 rows.
      // 1 Nov 2026 = Sunday; Monday-start week -> leading 6; 6+30=36 -> 6 rows.
      final l2 = leadingOffset(DateTime(2026, 11, 1), 1);
      expect(l2, 6);
      expect((l2 + daysInMonth(DateTime(2026, 11, 1)) + 6) ~/ 7, 6);
    });
  });
}
