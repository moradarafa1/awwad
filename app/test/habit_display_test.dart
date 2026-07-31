// Locks the language-audit fix (owner report 2026-07-31): catalog habit
// titles FOLLOW the app language unless the user customized them, so
// switching Arabic -> English can no longer leave habit names behind in
// Arabic (and vice versa).

import 'package:flutter_test/flutter_test.dart';

import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/catalog/habit_display.dart';
import 'package:awwad/core/models.dart';

Habit _habit(String title, {String? catalogKey}) => Habit(
      id: 'x',
      track: 'build',
      catalogKey: catalogKey,
      isCustom: catalogKey == null,
      title: title,
      templateKey: 'generic',
      reminderHour: 20,
      reminderHours: const [20],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  test('a catalog default title follows the app language', () {
    final cat = kHabitCatalog.firstWhere((c) => c.key == 'quit_smoking');
    final storedInArabic = _habit(cat.t('ar'), catalogKey: 'quit_smoking');
    expect(habitDisplayTitle(storedInArabic, 'en'), cat.t('en'));
    expect(habitDisplayTitle(storedInArabic, 'fr'), cat.t('fr'));
    expect(habitDisplayTitle(storedInArabic, 'ar'), cat.t('ar'));
    // And the other direction: created under English, rendered in Arabic.
    final storedInEnglish = _habit(cat.t('en'), catalogKey: 'quit_smoking');
    expect(habitDisplayTitle(storedInEnglish, 'ar'), cat.t('ar'));
  });

  test('EVERY catalog habit round-trips through all three languages', () {
    for (final cat in kHabitCatalog) {
      for (final from in const ['ar', 'en', 'fr']) {
        for (final to in const ['ar', 'en', 'fr']) {
          final h = _habit(cat.t(from), catalogKey: cat.key);
          expect(habitDisplayTitle(h, to), cat.t(to),
              reason: '${cat.key}: stored $from must render as $to');
        }
      }
    }
  });

  test('a user-customized name is never translated away', () {
    final h = _habit('صلاتي في المسجد', catalogKey: 'pray_on_time');
    expect(habitDisplayTitle(h, 'en'), 'صلاتي في المسجد');
    final custom = _habit('My own habit');
    expect(habitDisplayTitle(custom, 'ar'), 'My own habit');
  });

  test('the legacy pray_on_time default still follows the language', () {
    final h = _habit('المحافظة على الصلاة في وقتها',
        catalogKey: 'pray_on_time');
    expect(habitDisplayTitle(h, 'en'), 'Pray on time');
  });
}
