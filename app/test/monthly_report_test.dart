import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/report/monthly_report.dart';

// The monthly report is pure computation over stored entries: the per-habit
// counts, success rate and in-month best streak must be exact, and each habit
// must get a relapse tip in the requested locale.

DailyEntry _e(String habitId, String date,
        {bool slip = false, String type = 'log'}) =>
    DailyEntry(
      id: '$habitId$date',
      habitId: habitId,
      date: date,
      urge: 5,
      resistance: 5,
      didSlip: slip,
      entryType: type,
      createdAt: DateTime.parse('$date 12:00:00'),
    );

void main() {
  final breakHabit = Habit(
      id: 'b',
      track: 'break',
      catalogKey: 'quit_smoking',
      title: 'x',
      createdAt: DateTime(2026, 1, 1));
  final religious = Habit(
      id: 'r',
      track: 'build',
      catalogKey: 'pray_on_time',
      title: 'y',
      createdAt: DateTime(2026, 1, 1));
  final custom = Habit(
      id: 'c',
      track: 'build',
      isCustom: true,
      title: 'z',
      createdAt: DateTime(2026, 1, 1));

  test('counts, success rate and best in-month streak', () {
    final entries = [
      _e('b', '2026-07-01'),
      _e('b', '2026-07-02'),
      _e('b', '2026-07-03', slip: true), // breaks the streak
      _e('b', '2026-07-04'),
      _e('b', '2026-07-05'),
      _e('b', '2026-07-06', type: 'skip'), // excused, ignored
      _e('b', '2026-06-30'), // previous month, excluded
    ];
    final rep = buildMonthlyReport([breakHabit], entries,
        year: 2026, month: 7);
    final r = rep.habits.single;
    expect(r.loggedDays, 5); // skip + other-month excluded
    expect(r.cleanDays, 4);
    expect(r.slipDays, 1);
    expect(r.skipDays, 1);
    expect(r.bestStreak, 2); // 04+05 (01+02 also 2; ties fine)
    expect((r.successRate * 100).round(), 80);
  });

  test('empty month reports isEmpty', () {
    final rep = buildMonthlyReport([breakHabit], const [],
        year: 2026, month: 7);
    expect(rep.isEmpty, true);
  });

  test('relapse tips are locale-correct and per-category', () {
    for (final loc in ['ar', 'en', 'fr']) {
      expect(relapseTip(breakHabit, loc).trim(), isNotEmpty);
      expect(relapseTip(religious, loc).trim(), isNotEmpty);
      expect(relapseTip(custom, loc).trim(), isNotEmpty);
    }
    // Religious habits get the repentance-framed tip (distinct from behavioural).
    expect(relapseTip(religious, 'ar'), isNot(relapseTip(breakHabit, 'ar')));
  });

  test('last-day-of-month detection', () {
    expect(isLastDayOfMonth(DateTime(2026, 7, 31)), true);
    expect(isLastDayOfMonth(DateTime(2026, 7, 30)), false);
    expect(isLastDayOfMonth(DateTime(2026, 2, 28)), true); // 2026 not leap
    expect(isLastDayOfMonth(DateTime(2028, 2, 29)), true); // leap
  });
}
