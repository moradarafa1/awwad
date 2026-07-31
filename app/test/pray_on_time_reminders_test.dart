// pray_on_time (owner order 2026-07-31): renamed to «الصلاة على وقتها» and its
// reminders ARE the five exact prayer-time notifications from the prayer
// window. These tests lock (a) the generic fixed-hour reminder is NOT built
// for it, (b) the read-side title migration for habits stored under the old
// default name, (c) the catalog carries the new name.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/catalog/habit_catalog.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/notifications/notif_scheduler.dart';

Habit _habit(String id, {String? catalogKey, String title = 'x'}) => Habit(
      id: id,
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
  test('catalog title is the new short name', () {
    final h = kHabitCatalog.firstWhere((h) => h.key == 'pray_on_time');
    expect(h.t('ar'), 'الصلاة على وقتها');
  });

  test('no generic reminder slot is built for pray_on_time', () {
    final specs = habitRemindersFor([
      _habit('a', catalogKey: 'pray_on_time', title: 'الصلاة على وقتها'),
      _habit('b', catalogKey: 'daily_quran', title: 'وِرد القرآن اليومي'),
    ], 'ar');
    expect(specs.where((s) => s.habitId == 'a'), isEmpty,
        reason: 'pray_on_time reminders are the prayer window, not a slot');
    expect(specs.where((s) => s.habitId == 'b'), isNotEmpty,
        reason: 'other habits keep their reminder slots');
  });

  test('a stored habit under the OLD default title is migrated on read', () async {
    final old = _habit('a',
        catalogKey: 'pray_on_time', title: 'المحافظة على الصلاة في وقتها');
    final custom = _habit('b',
        catalogKey: 'pray_on_time', title: 'صلاتي في المسجد');
    SharedPreferences.setMockInitialValues({
      'awwad_habits': jsonEncode([old.toJson(), custom.toJson()]),
    });
    final store = LocalStore(await SharedPreferences.getInstance());
    final loaded = store.loadHabits();
    expect(loaded.firstWhere((h) => h.id == 'a').title, 'الصلاة على وقتها');
    // A user-chosen name is sacred: only the exact old default is migrated.
    expect(loaded.firstWhere((h) => h.id == 'b').title, 'صلاتي في المسجد');
  });
}
