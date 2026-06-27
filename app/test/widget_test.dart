import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/catalog/badge_catalog.dart';

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
}
