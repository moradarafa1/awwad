import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/state/app_state.dart';

// MANDATE_PLAN CU1: surah_kahf is measured PER WEEK (Friday), so every other
// weekday must be transparent to the streak engine. Before this, an honest
// weekly reader showed a permanently broken 1-day streak.

DateTime _lastFriday([DateTime? from]) {
  var d = from ?? DateTime.now();
  d = DateTime(d.year, d.month, d.day);
  while (d.weekday != DateTime.friday) {
    d = d.subtract(const Duration(days: 1));
  }
  return d;
}

Future<AppController> _controller(Habit habit, List<DailyEntry> entries) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  await store.saveHabits([habit]);
  await store.saveEntries(entries);
  final container = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)]);
  addTearDown(container.dispose);
  return container.read(appControllerProvider.notifier);
}

Habit _kahf() => Habit(
      id: 'k1',
      track: 'build',
      catalogKey: 'surah_kahf',
      title: 'الكهف',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    );

DailyEntry _entry(DateTime d, {bool slip = false}) => DailyEntry(
      id: 'e${d.millisecondsSinceEpoch}',
      habitId: 'k1',
      date: dayKey(d),
      urge: 8,
      resistance: 8,
      didSlip: slip,
      createdAt: d,
    );

void main() {
  test('surah_kahf is registered as a weekly (Friday) habit', () {
    expect(weeklyWeekdayFor('surah_kahf'), DateTime.friday);
    expect(weeklyWeekdayFor('daily_quran'), isNull);
    expect(weeklyWeekdayFor(null), isNull);
  });

  test('three consecutive Fridays count as a 3-week streak', () async {
    final f0 = _lastFriday();
    final ctrl = await _controller(_kahf(), [
      _entry(f0),
      _entry(f0.subtract(const Duration(days: 7))),
      _entry(f0.subtract(const Duration(days: 14))),
    ]);
    // Weeks are reported as DAYS (7 per kept week) so badges, ranks,
    // stages and the widget label all stay coherent.
    expect(ctrl.state.currentStreak, 21);
    expect(ctrl.state.longestStreak, 21);
  });

  test('the empty days between Fridays never break the streak', () async {
    // Only Fridays are logged; the six days between are absent entirely.
    final f0 = _lastFriday();
    final ctrl = await _controller(_kahf(), [
      _entry(f0),
      _entry(f0.subtract(const Duration(days: 7))),
    ]);
    expect(ctrl.state.currentStreak, 14);
  });

  test('a missed Friday breaks the weekly streak', () async {
    final f0 = _lastFriday();
    final ctrl = await _controller(_kahf(), [
      _entry(f0),
      // f0 - 7 missing
      _entry(f0.subtract(const Duration(days: 14))),
    ]);
    expect(ctrl.state.currentStreak, 7);
  });

  test('a daily habit keeps its day-by-day semantics', () async {
    final today = DateTime.now();
    final daily = Habit(
      id: 'k1',
      track: 'build',
      catalogKey: 'daily_quran',
      title: 'ورد',
      createdAt: today.subtract(const Duration(days: 30)),
    );
    final ctrl = await _controller(daily, [
      _entry(today),
      _entry(today.subtract(const Duration(days: 1))),
    ]);
    expect(ctrl.state.currentStreak, 2);
  });
test('weekly streak is expressed in DAYS so badges and labels stay honest', () async {
    // Regression guard for the review's critical finding: returning WEEKS
    // made the widget say «يومان» for a two-week run and made the
    // "30 days" badge require 30 Fridays (about 7 months).
    final f0 = _lastFriday();
    final entries = <DailyEntry>[];
    for (var i = 0; i < 5; i++) {
      entries.add(_entry(f0.subtract(Duration(days: 7 * i))));
    }
    final ctrl = await _controller(_kahf(), entries);
    expect(ctrl.state.currentStreak, 35); // 5 Fridays kept = 5 weeks of days
    expect(ctrl.state.currentStreak % 7, 0);
  });
}
