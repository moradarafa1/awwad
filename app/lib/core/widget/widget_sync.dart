// Home-screen widget (streak + quick log), Android only, via home_widget.
// The widget itself is native (AwwadWidgetProvider.kt + res/layout/
// awwad_widget.xml); this file is the Dart side: composing the localized
// display strings, pushing them to the widget's data store, and the
// background callback the widget's quick-log button fires while the app may
// be closed. Fail-open everywhere: web/iOS/errors are silent no-ops.

import 'dart:async' show FutureOr;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_store.dart';
import '../state/app_state.dart';

/// «سلسلتك: N» line with correct MSA number agreement. Pure for tests.
String widgetStreakLabel(String locale, int n) {
  switch (locale) {
    case 'ar':
      if (n <= 0) return 'ابدأ سلسلتك اليوم';
      if (n == 1) return 'سلسلتك: يوم واحد';
      if (n == 2) return 'سلسلتك: يومان';
      // MSA agreement keys on n % 100: 3-10 plural تمييز (أيام), 11-99
      // singular accusative (يوماً), exact hundreds bare singular (يوم).
      final r = n % 100;
      if (r >= 3 && r <= 10) return 'سلسلتك: $n أيام';
      if (r >= 11) return 'سلسلتك: $n يوماً';
      return 'سلسلتك: $n يوم';
    case 'fr':
      if (n <= 0) return "Commencez votre série aujourd'hui";
      return n == 1 ? 'Série : 1 jour' : 'Série : $n jours';
    default:
      if (n <= 0) return 'Start your streak today';
      return n == 1 ? 'Streak: 1 day' : 'Streak: $n days';
  }
}

/// Quick-log button label (before / after today is logged). Pure for tests.
String widgetButtonLabel(String locale, {required bool logged}) {
  switch (locale) {
    case 'ar':
      return logged ? 'سُجّل اليوم' : 'سجّل هذا اليوم';
    case 'fr':
      return logged ? 'Enregistré' : 'Enregistrer ce jour';
    default:
      return logged ? 'Logged today' : 'Log today';
  }
}

/// Second line when no habit exists yet. Pure for tests.
String widgetEmptyLabel(String locale) {
  switch (locale) {
    case 'ar':
      return 'أضف عادة من التطبيق لتبدأ';
    case 'fr':
      return "Ajoutez une habitude dans l'application";
    default:
      return 'Add a habit in the app to start';
  }
}

/// Shared iOS app-group id: the WidgetKit extension (ios/AwwadWidget/) reads
/// the aw_* keys from this group's UserDefaults. Must match the App Group
/// capability added to BOTH Runner and the extension (docs/IOS_PARITY_SETUP.md).
const String kAwwadAppGroup = 'group.com.awwad.awwad';

class HomeWidgetSync {
  HomeWidgetSync._();

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool _iosGroupSet = false;

  static Future<void> _ensureIosGroup() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || _iosGroupSet) return;
    await HomeWidget.setAppGroupId(kAwwadAppGroup);
    _iosGroupSet = true;
  }

  /// Pushes the active habit's name / streak / logged-today state to the
  /// widget and asks Android to re-render it. Cheap; safe to call after
  /// every state change.
  static Future<void> push(AppState s) async {
    if (!_supported) return;
    try {
      await _ensureIosGroup();
      final locale = s.settings.locale ?? 'ar';
      final habit = s.activeHabit;
      final today = dayKey(DateTime.now());
      final logged = habit != null &&
          s.entries.any(
              (e) => e.habitId == habit.id && e.date == today && !e.isSkip);
      await HomeWidget.saveWidgetData<String>('aw_name', habit?.title ?? 'عوّاد');
      await HomeWidget.saveWidgetData<String>(
          'aw_streak',
          habit == null
              ? widgetEmptyLabel(locale)
              : widgetStreakLabel(locale, s.currentStreak));
      await HomeWidget.saveWidgetData<String>(
          'aw_btn_log', widgetButtonLabel(locale, logged: false));
      await HomeWidget.saveWidgetData<String>(
          'aw_btn_done', widgetButtonLabel(locale, logged: true));
      await HomeWidget.saveWidgetData<bool>('aw_logged', logged);
      await HomeWidget.saveWidgetData<bool>('aw_has', habit != null);
      await HomeWidget.saveWidgetData<String>('aw_date', today);
      await HomeWidget.updateWidget(
          androidName: 'AwwadWidgetProvider', iOSName: 'AwwadWidget');
    } catch (_) {
      // Fail-open: the widget keeps its previous content.
    }
  }

  /// Registers the background quick-log callback (Android alarms-style
  /// broadcast; iOS 17 interactive-widget AppIntent). Call once per app open
  /// (idempotent); the handle persists across restarts.
  static Future<void> registerCallback() async {
    if (!_supported) return;
    try {
      await _ensureIosGroup();
      await HomeWidget.registerInteractivityCallback(
          homeWidgetBackgroundCallback);
    } catch (_) {
      // Fail-open: the widget still displays; only the button would no-op.
    }
  }
}

/// Background entry point fired by the widget's quick-log button, possibly
/// with the app closed. Runs in its own isolate: rebuilds state from disk,
/// logs today for the ACTIVE habit (idempotent, mirrors quickLogHabit via
/// the shared buildQuickEntry), then pushes the refreshed widget data back.
/// The foreground app reconciles via refreshFromStore() on resume.
@pragma('vm:entry-point')
FutureOr<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri?.host != 'quicklog') return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // this isolate's cache may predate app writes
    final store = LocalStore(prefs);
    final settings = store.loadSettings();
    final habits = store.loadHabits();
    var entries = store.loadEntries();
    var state =
        AppState(settings: settings, habits: habits, entries: entries);
    final habit = state.activeHabit;
    if (habit != null) {
      final today = dayKey(DateTime.now());
      final already = entries.any(
          (e) => e.habitId == habit.id && e.date == today && !e.isSkip);
      if (!already) {
        // Replace any same-day skip entry, like quickLogHabit does.
        entries = [
          ...entries
              .where((e) => !(e.date == today && e.habitId == habit.id)),
          buildQuickEntry(habit, today),
        ]..sort((a, b) => b.date.compareTo(a.date));
        await store.saveEntries(entries);
        state =
            AppState(settings: settings, habits: habits, entries: entries);
      }
    }
    await HomeWidgetSync.push(state);
  } catch (_) {
    // Fail-open: the widget simply keeps its previous content.
  }
}
