import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/report/weekly_insight.dart';

// MANDATE_PLAN CU8: the weekly insight is pure computation over stored
// entries, so it is testable without a widget tree or a clock.

final _now = DateTime(2026, 7, 19); // a Sunday, fixed so tests never drift

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DailyEntry _e(
  int daysAgo, {
  bool slip = false,
  bool skip = false,
  String? trigger,
  int urge = 5,
}) {
  final d = _now.subtract(Duration(days: daysAgo));
  return DailyEntry(
    id: 'e$daysAgo',
    habitId: 'h1',
    date: _key(d),
    urge: urge,
    resistance: 5,
    didSlip: slip,
    entryType: skip ? 'skip' : 'log',
    trigger: trigger,
    createdAt: d,
  );
}

void main() {
  test('too few entries means the card stays hidden', () {
    final i = computeWeeklyInsight([_e(0), _e(1)], 'h1', now: _now);
    expect(i.logged, 2);
    expect(i.hasEnoughData, isFalse);
  });

  test('counts only this habit, this week, excluding skips', () {
    final entries = [
      for (var d = 0; d < 7; d++) _e(d),
      _e(3, skip: true), // excused: transparent
      DailyEntry(
        id: 'other',
        habitId: 'h2', // a different habit must not leak in
        date: _key(_now),
        urge: 9,
        resistance: 1,
        didSlip: true,
        createdAt: _now,
      ),
      _e(20), // outside both windows
    ];
    final i = computeWeeklyInsight(entries, 'h1', now: _now);
    expect(i.logged, 7);
    expect(i.cleanDays, 7);
    expect(i.slipDays, 0);
    expect(i.hasEnoughData, isTrue);
    expect(i.successRate, 1.0);
  });

  test('finds the dominant slip trigger', () {
    final entries = [
      _e(0, slip: true, trigger: 'stress'),
      _e(1, slip: true, trigger: 'stress'),
      _e(2, slip: true, trigger: 'boredom'),
      _e(3),
      _e(4),
    ];
    final i = computeWeeklyInsight(entries, 'h1', now: _now);
    expect(i.topTrigger, 'stress');
    expect(i.topTriggerCount, 2);
    expect(i.slipDays, 3);
    expect(isKnownTrigger(i.topTrigger), isTrue);
    expect(triggerAdvice(i.topTrigger, 'ar'), isNotNull);
  });

  test('no trigger when nothing slipped', () {
    final i = computeWeeklyInsight([for (var d = 0; d < 5; d++) _e(d)], 'h1',
        now: _now);
    expect(i.topTrigger, isNull);
    expect(triggerAdvice(i.topTrigger, 'ar'), isNull);
  });

  test('picks the weekday with the best clean record', () {
    // Clean on the two most recent days, slips earlier.
    final entries = [
      _e(0), // Sunday
      _e(7), // Sunday, previous week (not counted in "this week")
      _e(1, slip: true, trigger: 'phone'),
      _e(2, slip: true, trigger: 'phone'),
      _e(3),
      _e(4),
    ];
    final i = computeWeeklyInsight(entries, 'h1', now: _now);
    expect(i.bestWeekday, isNotNull);
    expect(weekdayName(i.bestWeekday!, 'ar'), isNotEmpty);
    expect(weekdayName(i.bestWeekday!, 'en'), isNotEmpty);
  });

  test('urge delta compares this week with the previous one', () {
    final easing = computeWeeklyInsight([
      for (var d = 0; d < 7; d++) _e(d, urge: 3),
      for (var d = 7; d < 14; d++) _e(d, urge: 8),
    ], 'h1', now: _now);
    expect(easing.urgeDelta, lessThan(0)); // urges eased

    final rising = computeWeeklyInsight([
      for (var d = 0; d < 7; d++) _e(d, urge: 9),
      for (var d = 7; d < 14; d++) _e(d, urge: 4),
    ], 'h1', now: _now);
    expect(rising.urgeDelta, greaterThan(0));
  });

  test('delta is zero when there is no previous week to compare', () {
    final i = computeWeeklyInsight([for (var d = 0; d < 5; d++) _e(d)], 'h1',
        now: _now);
    expect(i.urgeDelta, 0.0);
  });

  test('every trigger advice is trilingual and em-dash free', () {
    for (final entry in kTriggerAdvice.entries) {
      for (final loc in ['ar', 'en', 'fr']) {
        final t = entry.value[loc];
        expect(t, isNotNull, reason: '${entry.key}/$loc');
        expect(t!, isNotEmpty);
        expect(t.contains('—'), isFalse);
      }
    }
  });

  test('an empty entry list is safe', () {
    final i = computeWeeklyInsight(const [], 'h1', now: _now);
    expect(i.logged, 0);
    expect(i.hasEnoughData, isFalse);
    expect(i.successRate, 0);
    expect(i.bestWeekday, isNull);
  });
}
