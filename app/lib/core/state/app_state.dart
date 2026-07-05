import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../analytics/analytics.dart';
import '../catalog/badge_catalog.dart';
import '../catalog/default_fields.dart';
import '../custom_field.dart';
import '../data/local_store.dart';
import '../models.dart';

const _uuid = Uuid();

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Provided via override in main() once SharedPreferences is ready.
final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden in main()');
});

/// Max habits the user may run concurrently, per track (break / build).
const int kMaxHabitsPerTrack = 3;

@immutable
class AppState {
  final AppSettings settings;
  final List<Habit> habits; // up to kMaxHabitsPerTrack per track
  final List<DailyEntry> entries; // all habits, newest first
  final SurveyData? survey;
  final List<EarnedBadge> badges; // all habits
  final List<CustomField> fields;

  const AppState({
    required this.settings,
    this.habits = const [],
    this.entries = const [],
    this.survey,
    this.badges = const [],
    this.fields = const [],
  });

  AppState copyWith({
    AppSettings? settings,
    List<Habit>? habits,
    List<DailyEntry>? entries,
    SurveyData? survey,
    List<EarnedBadge>? badges,
    List<CustomField>? fields,
  }) =>
      AppState(
        settings: settings ?? this.settings,
        habits: habits ?? this.habits,
        entries: entries ?? this.entries,
        survey: survey ?? this.survey,
        badges: badges ?? this.badges,
        fields: fields ?? this.fields,
      );

  // ----- habit selection -----
  /// The currently-focused habit id (falls back to the first habit).
  String? get activeHabitId {
    final id = settings.activeHabitId;
    if (id != null && habits.any((h) => h.id == id)) return id;
    return habits.isNotEmpty ? habits.first.id : null;
  }

  /// The currently-focused habit; what Today / Stats / History show.
  Habit? get activeHabit {
    final id = activeHabitId;
    if (id == null) return null;
    for (final h in habits) {
      if (h.id == id) return h;
    }
    return habits.isNotEmpty ? habits.first : null;
  }

  /// Backwards-compatible alias used by older call sites.
  Habit? get habit => activeHabit;

  List<Habit> habitsForTrack(String track) =>
      habits.where((h) => h.track == track).toList();

  int trackCount(String track) => habitsForTrack(track).length;

  bool canAddTrack(String track) => trackCount(track) < kMaxHabitsPerTrack;

  /// Catalog keys already in use, so the picker can hide duplicates.
  Set<String> get ownedCatalogKeys =>
      {for (final h in habits) if (h.catalogKey != null) h.catalogKey!};

  // ----- entries / badges scoped to the active habit -----
  List<DailyEntry> entriesFor(String? habitId) => habitId == null
      ? const []
      : entries.where((e) => e.habitId == habitId).toList();

  List<DailyEntry> get activeEntries => entriesFor(activeHabitId);

  List<EarnedBadge> badgesFor(String? habitId) => habitId == null
      ? const []
      : badges.where((b) => b.habitId == habitId).toList();

  List<EarnedBadge> get activeBadges => badgesFor(activeHabitId);

  List<CustomField> visibleFields(String group) =>
      (fields.where((f) => f.group == group && !f.hidden).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  List<CustomField> allFields(String group) =>
      (fields.where((f) => f.group == group).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  // ----- derived stats for the ACTIVE habit (computed locally; offline) -----
  int get daysLogged => activeEntries.length;
  int get cleanDays => activeEntries.where((e) => !e.didSlip).length;

  int get currentStreak {
    var s = 0;
    for (final e in activeEntries) {
      if (!e.didSlip) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  int get longestStreak {
    var longest = 0, run = 0;
    final asc = activeEntries.reversed.toList();
    for (final e in asc) {
      if (!e.didSlip) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    return longest;
  }

  bool get hasComeback =>
      activeEntries.any((e) => e.didSlip) && currentStreak >= 1;

  int get weekNumber {
    final h = activeHabit;
    if (h == null) return 1;
    final days = DateTime.now().difference(h.createdAt).inDays;
    final w = (days ~/ 7) + 1;
    return w.clamp(1, h.totalWeeks);
  }

  double get avgUrge {
    final recent = activeEntries.take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.urge).reduce((a, b) => a + b) / recent.length;
  }

  double get avgResistance {
    final recent = activeEntries.take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.resistance).reduce((a, b) => a + b) /
        recent.length;
  }

  DailyEntry? entryForToday() {
    final id = activeHabitId;
    if (id == null) return null;
    final today = dayKey(DateTime.now());
    for (final e in entries) {
      if (e.date == today && e.habitId == id) return e;
    }
    return null;
  }
}

class AppController extends Notifier<AppState> {
  late final LocalStore _store;

  @override
  AppState build() {
    _store = ref.read(localStoreProvider);
    var settings = _store.loadSettings();
    var habits = _store.loadHabits();

    // One-time migration: an old install stored a single habit under the legacy
    // key. Wrap it into the new list and make it the active habit.
    final legacy = _store.loadLegacyHabit();
    if (habits.isEmpty && legacy != null) {
      habits = [legacy];
      settings = settings.copyWith(activeHabitId: legacy.id);
      _store.saveHabits(habits);
      _store.saveSettings(settings);
      _store.clearLegacyHabit();
    }

    final entries = _sorted(_store.loadEntries());

    // Migration for new first-open / first-log flags: a user who has already
    // onboarded should NOT be shown the new auth-choice screen, and a user who
    // already has entries should NOT get the first-log account popup again.
    if ((settings.onboardingDone || habits.isNotEmpty) &&
        !settings.authChoiceMade) {
      settings = settings.copyWith(
        authChoiceMade: true,
        firstLogPromptShown:
            settings.firstLogPromptShown || entries.isNotEmpty,
      );
      _store.saveSettings(settings);
    }

    return AppState(
      settings: settings,
      habits: habits,
      entries: entries,
      survey: _store.loadSurvey(),
      badges: _store.loadBadges(),
      fields: _store.loadFields(),
    );
  }

  List<DailyEntry> _sorted(List<DailyEntry> list) {
    final copy = [...list]..sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  // ---------- settings ----------
  Future<void> setLocale(String locale) async {
    final s = state.settings.copyWith(locale: locale);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('language_selected', {'locale': locale});
  }

  Future<void> setShowReligiousContent(bool show) async {
    final s = state.settings.copyWith(showReligiousContent: show);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance
        .track('religious_content_toggled', {'visible': show});
  }

  Future<void> setDarkMode(bool dark) async {
    final s = state.settings.copyWith(darkMode: dark);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
  }

  Future<void> setReminderHour(int hour) async {
    final s = state.settings.copyWith(reminderHour: hour);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('reminder_set', {'hour': hour});
  }

  Future<void> saveSurvey(SurveyData survey) async {
    state = state.copyWith(survey: survey);
    await _store.saveSurvey(survey);
  }

  // ---------- onboarding ----------
  Future<void> completeOnboarding(Habit habit, {SurveyData? survey}) async {
    final s = state.settings
        .copyWith(onboardingDone: true, activeHabitId: habit.id);
    final fields = state.fields.isEmpty
        ? seedFields(state.settings.locale ?? 'ar', habit.track)
        : state.fields;
    state = state.copyWith(
        settings: s, habits: [habit], survey: survey, fields: fields);
    await _store.saveHabits([habit]);
    await _store.saveSettings(s);
    await _store.saveFields(fields);
    if (survey != null) await _store.saveSurvey(survey);
    AnalyticsService.instance.track('onboarding_completed', {
      'track': habit.track,
      'is_custom': habit.isCustom,
    });
  }

  // ---------- multi-habit management ----------
  /// Adds a new habit (respecting the per-track cap) and focuses it.
  /// Returns false if the track is already at the cap.
  Future<bool> addHabit(Habit habit) async {
    if (!state.canAddTrack(habit.track)) return false;
    final habits = [...state.habits, habit];
    final s = state.settings.copyWith(activeHabitId: habit.id);
    state = state.copyWith(habits: habits, settings: s);
    await _store.saveHabits(habits);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('habit_added', {
      'track': habit.track,
      'is_custom': habit.isCustom,
      'catalog_key': habit.catalogKey,
      'total_habits': habits.length,
    });
    return true;
  }

  /// Update a habit's reminder times (hours of day).
  Future<void> setHabitReminderHours(String habitId, List<int> hours) async {
    final habits = state.habits
        .map((h) => h.id == habitId ? h.copyWith(reminderHours: hours) : h)
        .toList();
    state = state.copyWith(habits: habits);
    await _store.saveHabits(habits);
    AnalyticsService.instance
        .track('habit_reminders_set', {'count': hours.length});
  }

  /// Switch which habit the Today / Stats / History tabs show.
  Future<void> setActiveHabit(String habitId) async {
    if (!state.habits.any((h) => h.id == habitId)) return;
    final s = state.settings.copyWith(activeHabitId: habitId);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('habit_switched', {'habit_id': habitId});
  }

  /// Remove a habit and all of its entries and badges.
  Future<void> removeHabit(String habitId) async {
    final habits = state.habits.where((h) => h.id != habitId).toList();
    final entries = state.entries.where((e) => e.habitId != habitId).toList();
    final badges = state.badges.where((b) => b.habitId != habitId).toList();
    final nextActive = state.settings.activeHabitId == habitId
        ? (habits.isNotEmpty ? habits.first.id : null)
        : state.settings.activeHabitId;
    final s = nextActive == null
        ? state.settings.copyWith(clearActiveHabit: true)
        : state.settings.copyWith(activeHabitId: nextActive);
    state = state.copyWith(
        habits: habits, entries: entries, badges: badges, settings: s);
    await _store.saveHabits(habits);
    await _store.saveEntries(entries);
    await _store.saveBadges(badges);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('habit_removed', {'habit_id': habitId});
  }

  // ---------- custom fields ----------
  Future<void> _persistFields(List<CustomField> fields) async {
    state = state.copyWith(fields: fields);
    await _store.saveFields(fields);
  }

  Future<void> addField(String group, String label, {String? emoji}) async {
    final maxOrder = state.allFields(group).fold<int>(
        0, (m, f) => f.sortOrder > m ? f.sortOrder : m);
    final field = CustomField(
      id: _uuid.v4(),
      group: group,
      label: label,
      emoji: emoji,
      sortOrder: maxOrder + 1,
    );
    await _persistFields([...state.fields, field]);
    AnalyticsService.instance.track('custom_field_added', {'group': group});
  }

  Future<void> updateFieldLabel(String id, String label) async {
    await _persistFields(
        state.fields.map((f) => f.id == id ? f.copyWith(label: label) : f).toList());
  }

  Future<void> toggleFieldHidden(String id) async {
    await _persistFields(state.fields
        .map((f) => f.id == id ? f.copyWith(hidden: !f.hidden) : f)
        .toList());
  }

  Future<void> deleteField(String id) async {
    // System defaults are hidden rather than destroyed (restorable); user fields delete.
    final field = state.fields.firstWhere((f) => f.id == id,
        orElse: () => const CustomField(id: '', group: '', label: ''));
    if (field.isSystem) {
      await toggleFieldHidden(id);
    } else {
      await _persistFields(state.fields.where((f) => f.id != id).toList());
    }
  }

  // ---------- daily log ----------
  Future<List<EarnedBadge>> saveEntry({
    required int urge,
    required int resistance,
    required bool didSlip,
    String? moodEmoji,
    String? moodLabel,
    String? note,
    List<String> competingResponses = const [],
    List<String> environment = const [],
  }) async {
    final habit = state.activeHabit;
    if (habit == null) return const [];
    final today = dayKey(DateTime.now());

    final existing = state.entryForToday();
    final entry = DailyEntry(
      id: existing?.id ?? _uuid.v4(),
      habitId: habit.id,
      date: today,
      urge: urge,
      resistance: resistance,
      didSlip: didSlip,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      note: note,
      competingResponses: competingResponses,
      environment: environment,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    // Replace only THIS habit's entry for today, leaving other habits intact.
    final list = [
      ...state.entries
          .where((e) => !(e.date == today && e.habitId == habit.id)),
      entry,
    ];
    final sorted = _sorted(list);
    state = state.copyWith(entries: sorted);
    await _store.saveEntries(sorted);

    AnalyticsService.instance.track('entry_saved', {
      'did_slip': didSlip,
      'urge': urge,
      'resistance': resistance,
    });

    return _evaluateAndAwardBadges();
  }

  Future<List<EarnedBadge>> _evaluateAndAwardBadges() async {
    final habitId = state.activeHabitId;
    if (habitId == null) return const [];
    final qualified = evaluateBadges(
      currentStreak: state.currentStreak,
      daysLogged: state.daysLogged,
      hasComeback: state.hasComeback,
    );
    final existingKeys =
        state.badgesFor(habitId).map((b) => b.badgeKey).toSet();
    final newKeys = qualified.difference(existingKeys);
    if (newKeys.isEmpty) return const [];

    final newlyEarned = newKeys
        .map((k) =>
            EarnedBadge(badgeKey: k, earnedAt: DateTime.now(), habitId: habitId))
        .toList();
    final all = [...state.badges, ...newlyEarned];
    state = state.copyWith(badges: all);
    await _store.saveBadges(all);

    for (final b in newlyEarned) {
      final def = badgeByKey(b.badgeKey);
      AnalyticsService.instance.track('badge_earned',
          {'badge_key': b.badgeKey, 'tier': def?.tier ?? 'unknown'});
    }
    return newlyEarned;
  }

  Future<void> markBadgeCelebrated(String badgeKey) async {
    final habitId = state.activeHabitId;
    final all = state.badges
        .map((b) => (b.badgeKey == badgeKey && b.habitId == habitId)
            ? b.copyWith(celebrated: true)
            : b)
        .toList();
    state = state.copyWith(badges: all);
    await _store.saveBadges(all);
    AnalyticsService.instance.track('badge_celebrated', {'badge_key': badgeKey});
  }

  // ---------- cloud (P2) ----------
  /// Adopt a snapshot pulled from the cloud (first login on a fresh device).
  Future<void> importSnapshot(
      List<Habit> habits, List<DailyEntry> entries, SurveyData? survey) async {
    if (habits.isEmpty) return;
    final s = state.settings
        .copyWith(onboardingDone: true, activeHabitId: habits.first.id);
    final sorted = _sorted(entries);
    final fields = state.fields.isEmpty
        ? seedFields(state.settings.locale ?? 'ar', habits.first.track)
        : state.fields;
    state = state.copyWith(
        settings: s,
        habits: habits,
        entries: sorted,
        survey: survey,
        fields: fields);
    await _store.saveSettings(s);
    await _store.saveHabits(habits);
    await _store.saveEntries(sorted);
    await _store.saveFields(fields);
    if (survey != null) await _store.saveSurvey(survey);
  }

  // ---------- reset ----------
  Future<void> resetAll() async {
    await _store.clearAll();
    // Preserve locale + preferences, but re-show onboarding and the first-open
    // auth choice, and clear the active-habit pointer.
    final s = state.settings.copyWith(
      onboardingDone: false,
      authChoiceMade: false,
      firstLogPromptShown: false,
      clearActiveHabit: true,
    );
    await _store.saveSettings(s);
    state = AppState(settings: s);
  }

  // ---------- onboarding / consent flags ----------
  /// Records the first-open choice (sign in vs continue as guest).
  Future<void> setAuthChoice({required bool guest}) async {
    final s = state.settings.copyWith(authChoiceMade: true);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('auth_choice', {'guest': guest});
  }

  Future<void> markFirstLogPromptShown() async {
    final s = state.settings.copyWith(firstLogPromptShown: true);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
  }

  Future<void> markNotifPromptShown() async {
    final s = state.settings.copyWith(notifPromptShown: true);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
  }

  Future<void> setNotificationsEnabled(bool on) async {
    final s = state.settings.copyWith(notificationsEnabled: on);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('notifications_toggled', {'enabled': on});
  }

  Future<void> setDhikrEnabled(bool on) async {
    final s = state.settings.copyWith(dhikrEnabled: on);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.track('dhikr_toggled', {'enabled': on});
  }
}

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);
