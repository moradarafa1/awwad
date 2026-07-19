import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/state/app_state.dart';

// MANDATE_PLAN CU9: habit strength is an EWMA over the last ~8 weeks, so one
// bad day dents it instead of erasing everything (the streak already covers
// "unbroken run"; strength covers resilience).

Future<AppState> _state(List<DailyEntry> entries, {int? ageDays}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  final habit = Habit(
    id: 'h1',
    track: 'build',
    catalogKey: 'daily_quran',
    title: 'ورد',
    // The habit cannot predate itself: days before creation are out of
    // scope, days after it with no entry are real misses.
    createdAt: DateTime.now()
        .subtract(Duration(days: ageDays ?? (entries.length - 1))),
  );
  await store.saveHabits([habit]);
  await store.saveEntries(entries);
  final c = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)]);
  addTearDown(c.dispose);
  return c.read(appControllerProvider);
}

DailyEntry _e(DateTime d, {bool slip = false, bool skip = false}) => DailyEntry(
      id: 'e${d.millisecondsSinceEpoch}',
      habitId: 'h1',
      date: dayKey(d),
      urge: 8,
      resistance: 8,
      didSlip: slip,
      entryType: skip ? 'skip' : 'log',
      createdAt: d,
    );

List<DailyEntry> _run(int days, {Set<int> slipsOn = const {}}) {
  final now = DateTime.now();
  return [
    for (var i = 0; i < days; i++)
      _e(now.subtract(Duration(days: i)), slip: slipsOn.contains(i)),
  ];
}

void main() {
  test('no entries means no score', () async {
    final s = await _state([]);
    expect(s.habitStrength, 0);
  });

  test('a spotless month scores 100', () async {
    final s = await _state(_run(30));
    expect(s.habitStrength, 100);
  });

  test('one slip dents the score instead of erasing it', () async {
    // Same 30 logged days, but today was a slip.
    final s = await _state(_run(30, slipsOn: {0}));
    expect(s.currentStreak, 0); // the streak IS zero: that is its job
    expect(s.habitStrength, greaterThan(50)); // strength survives
    expect(s.habitStrength, lessThan(100));
  });

  test('recent days weigh more than old ones', () async {
    final now = DateTime.now();
    // Slipped a month ago vs slipped yesterday: same count, different recency.
    final old = await _state([
      for (var i = 0; i < 40; i++)
        _e(now.subtract(Duration(days: i)), slip: i == 35),
    ]);
    final recent = await _state([
      for (var i = 0; i < 40; i++)
        _e(now.subtract(Duration(days: i)), slip: i == 1),
    ]);
    expect(recent.habitStrength, lessThan(old.habitStrength));
  });

  test('excused skips are transparent, not penalties', () async {
    final now = DateTime.now();
    final withSkip = await _state([
      for (var i = 0; i < 20; i++)
        _e(now.subtract(Duration(days: i)), skip: i == 3),
    ]);
    expect(withSkip.habitStrength, 100);
  });

  test('an unlogged today does not drag the score down yet', () async {
    final now = DateTime.now();
    // Clean run through yesterday; today not logged.
    final s = await _state([
      for (var i = 1; i <= 20; i++) _e(now.subtract(Duration(days: i))),
    ]);
    expect(s.habitStrength, 100);
  });

  test('the score always stays inside 0..100', () async {
    for (final days in [1, 7, 60, 120]) {
      final s = await _state(_run(days, slipsOn: {0, 2, 5}));
      expect(s.habitStrength, inInclusiveRange(0, 100));
    }
  });
}
