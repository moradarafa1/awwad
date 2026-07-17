import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/catalog/habit_content.dart';
import 'package:awwad/core/catalog/habit_daily_content.dart';

// 0d Phase A2: the two new catalog habits exist and are fully wired (title in
// all locales, daily question, HRT content / scholar video), and every scholar
// video is a religious habit under 15 minutes as the owner required.

void main() {
  test('surah_kahf and break_porn are in the catalog, trilingual', () {
    for (final key in ['surah_kahf', 'break_porn']) {
      final h = catalogByKey(key);
      expect(h, isNotNull, reason: '$key missing from catalog');
      for (final loc in ['ar', 'en', 'fr']) {
        expect(h!.t(loc).trim(), isNotEmpty, reason: '$key title[$loc] empty');
        expect(h.d(loc).trim(), isNotEmpty, reason: '$key desc[$loc] empty');
      }
      expect(h!.isIslamic, isTrue);
    }
    expect(catalogByKey('surah_kahf')!.track, 'build');
    expect(catalogByKey('break_porn')!.track, 'break');
  });

  test('new habits have a daily question in all locales', () {
    for (final key in ['surah_kahf', 'break_porn']) {
      final q = kHabitQuestions[key];
      expect(q, isNotNull, reason: '$key has no daily question');
      for (final loc in ['ar', 'en', 'fr']) {
        expect((q![loc] ?? '').trim(), isNotEmpty);
      }
    }
  });

  test('break_porn reuses the secret-habit HRT checklists', () {
    final cr = habitChecklistLabels('break_porn', 'competing_response', 'ar');
    final env = habitChecklistLabels('break_porn', 'environment_action', 'ar');
    expect(cr, isNotEmpty);
    expect(env, isNotEmpty);
    expect(cr, habitChecklistLabels('secret_habit', 'competing_response', 'ar'));
  });

  test('every scholar video belongs to a real habit and is under 15 min', () {
    for (final entry in kHabitVideos.entries) {
      expect(catalogByKey(entry.key), isNotNull,
          reason: 'videos for unknown habit "${entry.key}"');
      for (final v in entry.value) {
        expect(v.seconds, lessThanOrEqualTo(900),
            reason: '${entry.key} video "${v.title}" is ${v.minutes} min (>15)');
        expect(v.id.trim(), isNotEmpty);
      }
    }
  });

  test('new habits surface a scholar video card', () {
    expect(kHabitVideos['break_porn'], isNotNull);
    expect(kHabitVideos['break_porn'], isNotEmpty);
  });
}
