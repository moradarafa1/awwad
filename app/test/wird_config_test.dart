import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';

// The listening wird, owner brief 2026-07-20. The rules worth locking down are
// the ones a future edit could quietly undo: the five-minute floor, the fact
// that wird hours become real reminder times, and that a habit with no wird
// behaves exactly as before.
void main() {
  Habit habitWith(WirdConfig? w, {List<int> reminders = const [20]}) => Habit(
        id: 'h1',
        track: 'build',
        catalogKey: 'daily_quran',
        title: 'ورد القرآن',
        reminderHours: reminders,
        createdAt: DateTime(2026, 7, 20),
        wird: w,
      );

  group('the five-minute floor', () {
    test('a shorter length is clamped up, never honoured', () {
      expect(const WirdConfig().copyWith(minutesPerSession: 2).minutesPerSession,
          WirdConfig.kMinWirdMinutes);
      expect(const WirdConfig().copyWith(minutesPerSession: 0).minutesPerSession,
          WirdConfig.kMinWirdMinutes);
      expect(const WirdConfig().copyWith(minutesPerSession: -9).minutesPerSession,
          WirdConfig.kMinWirdMinutes);
    });

    test('a value stored before the floor existed is clamped on read', () {
      // The old hardcoded threshold was 120 seconds. A config persisted from
      // that era must not resurrect a two-minute wird.
      final old = WirdConfig.fromJson({'enabled': true, 'minutesPerSession': 2});
      expect(old.minutesPerSession, WirdConfig.kMinWirdMinutes);
      expect(old.secondsPerSession, 5 * 60);
    });

    test('a sane length is left alone', () {
      expect(const WirdConfig().copyWith(minutesPerSession: 20).minutesPerSession, 20);
    });
  });

  group('wird hours are reminder times', () {
    test('an enabled wird contributes its hours, sorted and deduped', () {
      final h = habitWith(
          const WirdConfig(enabled: true, times: [7, 20, 5]),
          reminders: [20]);
      expect(h.times, [5, 7, 20]);
    });

    test('a DISABLED wird contributes nothing', () {
      final h = habitWith(const WirdConfig(times: [7, 5]), reminders: [20]);
      expect(h.times, [20]);
    });

    test('a habit with no wird is untouched', () {
      expect(habitWith(null, reminders: [8, 21]).times, [8, 21]);
    });
  });

  group('persistence', () {
    test('survives a roundtrip', () {
      const cfg = WirdConfig(
          enabled: true,
          minutesPerSession: 15,
          times: [6, 21],
          autoPlay: true,
          sessionsPerDay: 3);
      expect(WirdConfig.fromJson(cfg.toJson()), cfg);
    });

    test('a habit carries its wird through json', () {
      final h = habitWith(const WirdConfig(enabled: true, minutesPerSession: 12));
      final back = Habit.fromJson(h.toJson());
      expect(back.wird?.enabled, isTrue);
      expect(back.wird?.minutesPerSession, 12);
    });

    test('garbage on disk degrades to null rather than throwing', () {
      final j = habitWith(null).toJson()..['wird'] = 'not a map';
      expect(Habit.fromJson(j).wird, isNull);
    });

    test('an out-of-range hour is dropped', () {
      final cfg = WirdConfig.fromJson({
        'enabled': true,
        'times': [7, 99, -3, 23],
      });
      expect(cfg.times, [7, 23]);
    });
  });

  test('sessionsPerDay is a target, and is bounded', () {
    expect(const WirdConfig().copyWith(sessionsPerDay: 0).sessionsPerDay, 1);
    expect(const WirdConfig().copyWith(sessionsPerDay: 99).sessionsPerDay,
        WirdConfig.kMaxSessionsPerDay);
  });

  test('only listening habits qualify', () {
    expect(isListeningHabit('daily_quran'), isTrue);
    expect(isListeningHabit('hadith_wird'), isTrue);
    expect(isListeningHabit('quit_smoking'), isFalse);
    // A custom habit has no catalog key and must never qualify.
    expect(isListeningHabit(null), isFalse);
  });
}
