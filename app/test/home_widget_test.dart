import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/models.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/core/widget/widget_sync.dart';

// Home-screen widget (streak + quick log): the pure pieces - localized
// labels with MSA number agreement, and the shared quick-entry builder the
// background callback and quickLogHabit both use.

Habit _habit(String track) => Habit(
      id: 'h1',
      track: track,
      title: 'قراءة',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('Arabic streak label follows number agreement', () {
    expect(widgetStreakLabel('ar', 0), 'ابدأ سلسلتك اليوم');
    expect(widgetStreakLabel('ar', 1), 'سلسلتك: يوم واحد');
    expect(widgetStreakLabel('ar', 2), 'سلسلتك: يومان');
    expect(widgetStreakLabel('ar', 7), 'سلسلتك: 7 أيام');
    expect(widgetStreakLabel('ar', 10), 'سلسلتك: 10 أيام');
    expect(widgetStreakLabel('ar', 11), 'سلسلتك: 11 يوماً');
    expect(widgetStreakLabel('ar', 30), 'سلسلتك: 30 يوماً');
    // n % 100 buckets: exact hundreds bare singular, 103-110 plural,
    // 111-199 singular accusative (the 100-day milestone is celebrated
    // by the badges, so the widget must be grammatical there).
    expect(widgetStreakLabel('ar', 100), 'سلسلتك: 100 يوم');
    expect(widgetStreakLabel('ar', 101), 'سلسلتك: 101 يوم');
    expect(widgetStreakLabel('ar', 103), 'سلسلتك: 103 أيام');
    expect(widgetStreakLabel('ar', 110), 'سلسلتك: 110 أيام');
    expect(widgetStreakLabel('ar', 111), 'سلسلتك: 111 يوماً');
    expect(widgetStreakLabel('ar', 180), 'سلسلتك: 180 يوماً');
    expect(widgetStreakLabel('ar', 200), 'سلسلتك: 200 يوم');
  });

  test('English and French streak labels', () {
    expect(widgetStreakLabel('en', 0), 'Start your streak today');
    expect(widgetStreakLabel('en', 1), 'Streak: 1 day');
    expect(widgetStreakLabel('en', 9), 'Streak: 9 days');
    expect(widgetStreakLabel('fr', 1), 'Série : 1 jour');
    expect(widgetStreakLabel('fr', 9), 'Série : 9 jours');
    // Unknown locale falls back to English.
    expect(widgetStreakLabel('de', 3), 'Streak: 3 days');
  });

  test('button and empty labels exist per locale, no em-dash anywhere', () {
    for (final loc in ['ar', 'en', 'fr']) {
      for (final s in [
        widgetButtonLabel(loc, logged: false),
        widgetButtonLabel(loc, logged: true),
        widgetEmptyLabel(loc),
        widgetStreakLabel(loc, 5),
      ]) {
        expect(s, isNotEmpty);
        expect(s.contains('—'), isFalse);
      }
      expect(widgetButtonLabel(loc, logged: false),
          isNot(widgetButtonLabel(loc, logged: true)));
    }
  });

  test('buildQuickEntry mirrors quickLogHabit semantics', () {
    final build = buildQuickEntry(_habit('build'), '2026-07-18');
    expect(build.urge, 8);
    expect(build.resistance, 8);
    expect(build.didSlip, isFalse);
    expect(build.habitId, 'h1');
    expect(build.date, '2026-07-18');

    final brk = buildQuickEntry(_habit('break'), '2026-07-18');
    expect(brk.urge, 2);
    expect(brk.didSlip, isFalse);
    expect(brk.id, isNot(build.id)); // unique ids
  });
}
