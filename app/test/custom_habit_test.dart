import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/catalog/habit_icons.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/notifications/notif_scheduler.dart';
import 'package:awwad/core/state/app_state.dart';

// PRO customization (owner brief 2026-07-20): icon, accent color and weekday
// schedule on every habit. These tests lock the three rules that are easy to
// break by accident:
//  1. storage stays backward compatible (an old JSON parses, a new one
//     round-trips),
//  2. an unscheduled day is TRANSPARENT to the streak walkers (it neither
//     counts nor breaks), and
//  3. reminders expand to weekly slots only for scheduled habits.
Habit _habit({List<int>? days}) => Habit(
      id: 'h1',
      track: 'build',
      isCustom: true,
      title: 'قراءة',
      createdAt: DateTime(2026, 1, 1),
      iconName: 'menu_book',
      accentColor: '#60a5fa',
      scheduleDays: days,
    );

DailyEntry _entry(DateTime d, {bool slip = false, bool skip = false}) =>
    DailyEntry(
      id: 'e${d.millisecondsSinceEpoch}',
      habitId: 'h1',
      date: dayKey(d),
      urge: 5,
      resistance: 5,
      didSlip: slip,
      entryType: skip ? 'skip' : 'log',
      createdAt: d,
    );

Future<AppState> _stateWith(Habit h, List<DailyEntry> entries) async {
  SharedPreferences.setMockInitialValues({});
  final store = LocalStore(await SharedPreferences.getInstance());
  await store.saveHabits([h]);
  await store.saveEntries(entries);
  await store.saveSettings(AppSettings(
      onboardingDone: true, activeHabitId: h.id, authChoiceMade: true));
  return AppState(
    settings: store.loadSettings(),
    habits: store.loadHabits(),
    entries: store.loadEntries(),
  );
}

void main() {
  test('json round-trips the customization, and legacy json still parses', () {
    final h = _habit(days: [1, 3, 5]);
    final back = Habit.fromJson(h.toJson());
    expect(back.iconName, 'menu_book');
    expect(back.accentColor, '#60a5fa');
    expect(back.scheduleDays, [1, 3, 5]);

    // A habit stored by ANY earlier version has none of the three keys.
    final legacy = Habit.fromJson({
      'id': 'old',
      'track': 'break',
      'title': 'قديم',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    expect(legacy.iconName, isNull);
    expect(legacy.accentColor, isNull);
    expect(legacy.scheduleDays, isNull);
    expect(legacy.isScheduledOn(DateTime.monday), isTrue);
  });

  test('isScheduledOn: null, empty and full-week all mean daily', () {
    expect(_habit(days: null).isScheduledOn(3), isTrue);
    expect(_habit(days: const []).isScheduledOn(3), isTrue);
    expect(
        _habit(days: const [1, 2, 3, 4, 5, 6, 7]).isScheduledOn(7), isTrue);
    expect(_habit(days: const [5]).isScheduledOn(5), isTrue);
    expect(_habit(days: const [5]).isScheduledOn(6), isFalse);
  });

  test('an unscheduled day neither breaks nor extends the streak', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Schedule = today's weekday and the day BEFORE yesterday's weekday, so
    // yesterday is an off-day. Entries exist on the two scheduled days only.
    int wd(DateTime d) => d.weekday;
    final dayMinus2 = today.subtract(const Duration(days: 2));
    final sched = {wd(today), wd(dayMinus2)}.toList()..sort();
    // Guard: if today and day-2 share a weekday the scenario is degenerate.
    if (sched.length == 1) sched.add((sched.first % 7) + 1);

    final h = _habit(days: sched);
    final s = await _stateWith(h, [
      _entry(today),
      _entry(dayMinus2),
    ]);
    // Yesterday is unscheduled and has NO entry. Without transparency the
    // walk would break there and count only today.
    expect(s.currentStreak, 2,
        reason: 'the unscheduled gap day must be transparent');
  });

  test('a missed SCHEDULED day still breaks the streak', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final h = _habit(days: null); // daily
    final s = await _stateWith(h, [
      _entry(today),
      // yesterday scheduled (daily) and missing -> break after today
      _entry(today.subtract(const Duration(days: 2))),
    ]);
    expect(s.currentStreak, 1);
  });

  test('reminders expand weekly for scheduled habits, daily otherwise', () {
    // Distinct ids: both helpers default to 'h1', and the spec filter below
    // is by habitId, so sharing an id would double-count.
    final daily = Habit(
        id: 'daily',
        track: 'build',
        title: 'د',
        createdAt: DateTime(2026),
        reminderHours: const [8, 20]);
    final sched = Habit(
        id: 'sched',
        track: 'build',
        title: 'س',
        createdAt: DateTime(2026),
        reminderHours: const [8],
        scheduleDays: const [5, 6]);
    final specs = habitRemindersFor([daily, sched], 'ar');

    final dailySpecs = specs.where((s) => s.habitId == daily.id).toList();
    expect(dailySpecs.length, 2);
    expect(dailySpecs.every((s) => s.weekday == null), isTrue,
        reason: 'daily habits keep repeat-daily slots');

    final schedSpecs = specs.where((s) => s.habitId == sched.id).toList();
    expect(schedSpecs.map((s) => s.weekday).toSet(), {5, 6},
        reason: 'one weekly slot per scheduled day');
  });

  test('every pickable icon resolves and every color parses', () {
    for (final e in kCustomHabitIcons.entries) {
      expect(e.value, isA<IconData>(), reason: e.key);
    }
    for (final hex in kHabitAccentChoices) {
      expect(habitAccentColor(hex), isNotNull, reason: hex);
    }
    // Malformed stored values degrade to null, never throw.
    expect(habitAccentColor('#12'), isNull);
    expect(habitAccentColor('60a5fa'), isNull);
    expect(habitAccentColor(null), isNull);
  });

  testWidgets('HabitIcon: user icon wins over catalog, bad key falls back',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          HabitIcon(
              habitKey: 'quit_smoking', iconName: 'brush', emoji: '🚭'),
          HabitIcon(habitKey: null, iconName: 'no_such_key', emoji: '🎯'),
        ]),
      ),
    ));
    expect(find.byIcon(Icons.brush_rounded), findsOneWidget,
        reason: 'the user override must beat the catalog icon');
    expect(find.text('🎯'), findsOneWidget,
        reason: 'an unknown icon key must fall back to the emoji');
  });
}
