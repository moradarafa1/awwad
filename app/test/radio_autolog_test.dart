import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/prayer/prayer_engine.dart';
import 'package:awwad/core/radio/radio_stations.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/core/catalog/habit_catalog.dart';

// The listening habits: radio station data is well-formed, and quickLogHabit
// (the "auto-log after listening" backbone) creates today's entry once and is
// idempotent, without disturbing the active habit. Plus the adhan-sound flag
// survives a PrayerConfig roundtrip.

void main() {
  test('radio stations are well-formed and categorised', () {
    expect(kRadioStations, isNotEmpty);
    expect(radioByCategory('hadith'), isNotEmpty);
    expect(radioByCategory('quran'), isNotEmpty);
    for (final s in kRadioStations) {
      expect(s.url.startsWith('https://'), isTrue,
          reason: '${s.id} must stream over https');
      for (final loc in ['ar', 'en', 'fr']) {
        expect(s.t(loc).trim(), isNotEmpty);
      }
    }
  });

  test('hadith_wird and listening_wird are in the catalog', () {
    expect(catalogByKey('hadith_wird'), isNotNull);
    expect(catalogByKey('listening_wird'), isNotNull);
    expect(catalogByKey('hadith_wird')!.track, 'build');
  });

  test('quickLogHabit creates today entry once and is idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final wird = Habit(
        id: 'w',
        track: 'build',
        catalogKey: 'hadith_wird',
        title: 'x',
        createdAt: DateTime(2026, 1, 1));
    final other = Habit(
        id: 'o',
        track: 'break',
        catalogKey: 'quit_smoking',
        title: 'y',
        createdAt: DateTime(2026, 1, 1));
    await store.saveHabits([other, wird]);
    await store.saveSettings(
        const AppSettings(onboardingDone: true, activeHabitId: 'o'));
    final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)]);
    addTearDown(container.dispose);
    final ctrl = container.read(appControllerProvider.notifier);

    final today = dayKey(DateTime.now());
    expect(await ctrl.quickLogHabit('w'), isTrue);
    var st = container.read(appControllerProvider);
    final logged =
        st.entries.where((e) => e.habitId == 'w' && e.date == today).toList();
    expect(logged.length, 1);
    expect(logged.first.didSlip, isFalse);
    expect(st.settings.activeHabitId, 'o'); // active habit untouched

    expect(await ctrl.quickLogHabit('w'), isFalse); // idempotent
    st = container.read(appControllerProvider);
    expect(
        st.entries.where((e) => e.habitId == 'w' && e.date == today).length, 1);
  });

  test('adhan sound flag survives a PrayerConfig JSON roundtrip', () {
    const cfg = PrayerConfig(lat: 30, lng: 31, adhanSound: true, preAlert: true);
    final back = PrayerConfig.fromJson(cfg.toJson());
    expect(back.adhanSound, true);
    expect(back.preAlert, true);
    // Default is off.
    expect(const PrayerConfig().adhanSound, false);
  });
}
