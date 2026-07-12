import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/catalog/badge_catalog.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/features/home/month_heatmap.dart';
import 'package:awwad/core/platform/usage_stats.dart';

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
      final state = AppState(
        settings: const AppSettings(activeHabitId: 'a'),
        habits: [habit('a', 'break'), habit('b', 'build')],
        entries: [
          entryFor('a', '2026-06-03'),
          entryFor('a', '2026-06-02'),
          entryFor('b', '2026-06-03', slip: true),
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
