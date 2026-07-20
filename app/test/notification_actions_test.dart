import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/notifications/notification_actions.dart';
import 'package:awwad/core/notifications/notifications.dart' show kTapHabit;
import 'package:awwad/core/prayer/prayer_scheduler.dart' show prayerName;
import 'package:awwad/core/state/app_state.dart' show dayKey;

// Notification ACTION buttons (phase 0.6 item 3).
//
// These run in a BACKGROUND ISOLATE with no Riverpod container, so every
// assertion here goes through LocalStore + SharedPreferences, which is the
// only channel the real handler has. resolveNotificationAction() is
// deliberately free of plugin calls precisely so it can be tested like this;
// the plugin half (applyActionResult) needs a device and is item 7.

Future<LocalStore> _store({
  List<Habit> habits = const [],
  List<DailyEntry> entries = const [],
  AppSettings settings = const AppSettings(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final s = LocalStore(prefs);
  await s.saveSettings(settings);
  await s.saveHabits(habits);
  await s.saveEntries(entries);
  return s;
}

Habit _habit({String id = 'h1'}) => Habit(
      id: id,
      title: 'ترك التدخين',
      track: 'break',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('«تم» auto-logs', () {
    test('writes today\'s entry for the habit in the payload', () async {
      final store = await _store(habits: [_habit()]);
      final now = DateTime(2026, 7, 20, 20, 30);

      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionDone,
        payload: 'habit:h1',
        notificationId: 3000,
        now: now,
      );

      expect(r.logged, isTrue);
      final entries = store.loadEntries();
      expect(entries, hasLength(1));
      expect(entries.single.habitId, 'h1');
      expect(entries.single.date, dayKey(now));
      expect(entries.single.didSlip, isFalse);
    });

    test('is idempotent: a second tap does not double-log', () async {
      final store = await _store(habits: [_habit()]);
      final now = DateTime(2026, 7, 20, 20, 30);
      Future<NotificationActionResult> tap() => resolveNotificationAction(
            store: store,
            actionId: kActionDone,
            payload: 'habit:h1',
            notificationId: 3000,
            now: now,
          );

      expect((await tap()).logged, isTrue);
      final second = await tap();
      expect(second.logged, isFalse);
      expect(second.alreadyLogged, isTrue);
      expect(store.loadEntries(), hasLength(1));
    });

    test('replaces a same-day skip entry rather than stacking on it', () async {
      final now = DateTime(2026, 7, 20, 20, 30);
      final skip = DailyEntry(
        id: 'skip1',
        habitId: 'h1',
        date: dayKey(now),
        urge: 0,
        resistance: 0,
        didSlip: false,
        entryType: 'skip', // isSkip is derived from this
        createdAt: now,
      );
      final store = await _store(habits: [_habit()], entries: [skip]);

      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionDone,
        payload: 'habit:h1',
        notificationId: 3000,
        now: now,
      );

      expect(r.logged, isTrue);
      final entries = store.loadEntries();
      expect(entries, hasLength(1), reason: 'the skip must be replaced');
      expect(entries.single.isSkip, isFalse);
    });

    test('a habit deleted after the reminder was scheduled is a no-op',
        () async {
      final store = await _store(habits: [_habit(id: 'other')]);
      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionDone,
        payload: 'habit:h1',
        notificationId: 3000,
      );
      expect(r.logged, isFalse);
      expect(store.loadEntries(), isEmpty);
    });

    test('does NOT log on a prayer alert', () async {
      // One of five prayers is not the daily pray-on-time habit; crediting the
      // day off the Fajr alert would mark four prayers that have not happened.
      final store = await _store(habits: [_habit()]);
      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionDone,
        payload: 'prayer:fajr',
        notificationId: 4000,
      );
      expect(r.logged, isFalse);
      expect(store.loadEntries(), isEmpty);
    });
  });

  group('«أمهلني» snooze', () {
    test('re-arms a habit reminder at +N minutes under a DERIVED id', () async {
      final store = await _store(
        habits: [_habit()],
        settings: const AppSettings(locale: 'ar', snoozeMinutes: 30),
      );
      final now = DateTime(2026, 7, 20, 20, 0);

      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionSnooze,
        payload: 'habit:h1',
        notificationId: 3007,
        now: now,
      );

      expect(r.snoozeAt, DateTime(2026, 7, 20, 20, 30));
      expect(r.snoozeTitle, 'ترك التدخين');
      expect(r.snoozeBody, isNotEmpty);
      // THE POINT OF THE DERIVED ID: habit reminders repeat daily via
      // matchDateTimeComponents.time. Re-using id 3007 would overwrite that
      // repeat and silently destroy the user's daily reminder.
      expect(r.snoozedId, isNot(3007));
      expect(r.snoozedId, 3007 + kSnoozeIdOffset);
    });

    test('re-snoozing reuses the derived id instead of stacking', () {
      final once = snoozeIdFor(3007);
      expect(snoozeIdFor(once), once);
    });

    test('snooze ids never collide across the habit and prayer ranges', () {
      final ids = <int>{};
      for (var i = 3000; i < 3060; i++) {
        ids.add(snoozeIdFor(i));
      }
      for (var i = 4000; i <= 4300; i++) {
        ids.add(snoozeIdFor(i));
      }
      expect(ids, hasLength(60 + 301));
    });

    test('names the prayer it defers, and does not repeat the time claim',
        () async {
      final store = await _store(
        settings: const AppSettings(locale: 'ar', snoozeMinutes: 10),
      );
      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionSnooze,
        payload: 'prayer:maghrib',
        notificationId: 4012,
        now: DateTime(2026, 7, 20, 19, 0),
      );
      expect(r.snoozeAt, DateTime(2026, 7, 20, 19, 10));
      expect(r.snoozeTitle, contains('المغرب'));
      // «حان وقت» would be a false statement ten minutes after the fact.
      expect(r.snoozeTitle, isNot(contains('حان وقت')));
    });

    test('a legacy bare `prayer` payload still snoozes', () async {
      // Notifications scheduled by the build before the key was added carry no
      // prayer key, and can still be sitting in the OS queue after an update.
      final store = await _store();
      final r = await resolveNotificationAction(
        store: store,
        actionId: kActionSnooze,
        payload: 'prayer',
        notificationId: 4012,
        now: DateTime(2026, 7, 20, 19, 0),
      );
      expect(r.snoozedId, isNotNull);
      expect(r.snoozeTitle, isNotEmpty);
      expect(r.snoozeTitle, isNot(contains('{p}')));
    });

    test('honours the stored snooze length', () async {
      for (final m in [10, 30]) {
        final store = await _store(
          habits: [_habit()],
          settings: AppSettings(snoozeMinutes: m),
        );
        final now = DateTime(2026, 7, 20, 20, 0);
        final r = await resolveNotificationAction(
          store: store,
          actionId: kActionSnooze,
          payload: 'habit:h1',
          notificationId: 3000,
          now: now,
        );
        expect(r.snoozeAt, now.add(Duration(minutes: m)));
      }
    });
  });

  group('payload parsing', () {
    test('splits kind from argument, and survives a colon in the argument', () {
      expect(parsePayload('habit:abc'), ('habit', 'abc'));
      expect(parsePayload('prayer:fajr'), ('prayer', 'fajr'));
      expect(parsePayload('prayer'), ('prayer', null));
      expect(parsePayload('report'), ('report', null));
      expect(parsePayload(null), ('', null));
      expect(parsePayload(''), ('', null));
      // A uuid habit id has no colon today, but splitting on the FIRST one
      // keeps the parse correct if one ever appears.
      expect(parsePayload('habit:a:b'), ('habit', 'a:b'));
    });

    test('the literal used above IS the prefix the scheduler writes', () {
      // These tests hand-write 'habit:h1'. If kTapHabit ever changed, they
      // would keep passing while every real notification stopped matching.
      expect(kTapHabit, 'habit:');
      expect(parsePayload('${kTapHabit}h1'), ('habit', 'h1'));
    });
  });

  group('settings', () {
    test('a stored non-positive snooze falls back to the default', () {
      // A zero would schedule the snooze in the past, i.e. fire immediately,
      // forever.
      expect(AppSettings.fromJson({'snoozeMinutes': 0}).snoozeMinutes, 10);
      expect(AppSettings.fromJson({'snoozeMinutes': -5}).snoozeMinutes, 10);
      expect(AppSettings.fromJson({'snoozeMinutes': 30}).snoozeMinutes, 30);
      expect(AppSettings.fromJson(const {}).snoozeMinutes, 10);
    });

    test('snoozeMinutes survives a settings roundtrip', () {
      const s = AppSettings(snoozeMinutes: 30);
      expect(AppSettings.fromJson(s.toJson()).snoozeMinutes, 30);
    });
  });

  group('action labels', () {
    test('every action label is trilingual and non-empty', () {
      for (final loc in ['ar', 'en', 'fr']) {
        expect(kActionDoneLabel[loc], isNotNull);
        expect(kActionDoneLabel[loc]!.trim(), isNotEmpty);
        expect(kActionSnoozeLabel(10)[loc]!.trim(), isNotEmpty);
        expect(kActionSnoozeLabel(30)[loc], contains('30'));
      }
    });

    test('no em-dash in any user-facing action copy', () {
      // Project rule: em-dashes are banned in Arabic prose and site copy.
      for (final loc in ['ar', 'en', 'fr']) {
        expect(kActionDoneLabel[loc], isNot(contains('—')));
        expect(kActionSnoozeLabel(10)[loc], isNot(contains('—')));
      }
    });
  });

  test('the duplicated prayer-name map matches prayer_scheduler', () {
    // notification_actions.dart keeps its own copy so the background isolate
    // never drags in the prayer engine. This test is what makes that safe.
    for (final key in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final mine = debugActionPrayerNames[key];
      expect(mine, isNotNull, reason: '$key missing from the action copy');
      for (final loc in ['ar', 'en', 'fr']) {
        expect(mine![loc], isNotNull);
        expect(mine[loc], prayerName(key, loc),
            reason: '$key/$loc drifted from prayer_scheduler');
      }
    }
  });
}
