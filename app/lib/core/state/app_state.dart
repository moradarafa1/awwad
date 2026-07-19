import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../analytics/analytics.dart';
import '../catalog/badge_catalog.dart';
import '../catalog/default_fields.dart';
import '../catalog/habit_catalog.dart' show weeklyWeekdayFor;
import '../custom_field.dart';
import '../data/local_store.dart';
import '../models.dart';

const _uuid = Uuid();

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The auto-log entry shared by AppController.quickLogHabit and the
/// home-screen widget's background quick-log: neutral positive ratings,
/// no slip (build habit done / break habit clean). Pure for tests.
DailyEntry buildQuickEntry(Habit habit, String today, {String? note}) {
  final rating = habit.track == 'build' ? 8 : 2;
  return DailyEntry(
    id: _uuid.v4(),
    habitId: habit.id,
    date: today,
    urge: rating,
    resistance: rating,
    didSlip: false,
    note: note,
    createdAt: DateTime.now(),
  );
}

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
  // SKIP entries (excused days: travel/sickness) are TRANSPARENT everywhere:
  // they neither break nor extend streaks and never count as logged/clean.
  int get daysLogged => activeEntries.where((e) => !e.isSkip).length;
  int get cleanDays =>
      activeEntries.where((e) => !e.isSkip && !e.didSlip).length;

  // Streaks are CALENDAR-AWARE: a day with no entry and no excuse BREAKS the
  // streak (that is what the repair banner protects against); an excused skip
  // passes through; TODAY without an entry does not break (day not over yet).
  /// For a WEEKLY habit (e.g. surah_kahf on Friday) every other weekday is
  /// transparent: it neither counts nor breaks. Null for daily habits.
  int? get _weeklyWeekday => weeklyWeekdayFor(activeHabit?.catalogKey);

  int get currentStreak {
    final byDay = {for (final e in activeEntries) e.date: e};
    if (byDay.isEmpty) return 0;
    final weekly = _weeklyWeekday;
    var s = 0;
    // Calendar arithmetic ONLY (never Duration): a DST shift makes absolute
    // 24h/168h steps land on the wrong calendar day, which for a weekly
    // habit silently skips an entire week.
    var d = _todayMidnight;
    if (byDay[dayKey(d)] == null) {
      d = _minusDays(d, 1); // today still pending
    }
    // A weekly habit's run may only be walked back from its own weekday;
    // start by rewinding to the most recent one that is not still pending.
    if (weekly != null) {
      while (d.weekday != weekly) {
        d = _minusDays(d, 1);
      }
      if (byDay[dayKey(d)] == null && !d.isBefore(_todayMidnight)) {
        d = _minusDays(d, 7); // this week still pending
      }
    }
    while (true) {
      final e = byDay[dayKey(d)];
      if (weekly != null && d.weekday != weekly) {
        d = _minusDays(d, 1); // off-day: transparent
        continue;
      }
      if (e == null) break; // missed, unexcused day -> broken
      if (!e.isSkip) {
        if (e.didSlip) break;
        s++;
      }
      d = _minusDays(d, weekly != null ? 7 : 1);
    }
    // The COUNT STAYS IN DAYS for weekly habits (7 per kept week): every
    // consumer (badges, ranks, stages, the widget label, «أيام متتالية»)
    // reads this number as days, so returning weeks would make all of them
    // lie. Only the walk is weekly.
    return weekly != null ? s * 7 : s;
  }

  static DateTime _minusDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day - n);

  static DateTime get _todayMidnight {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  int get longestStreak {
    final byDay = {for (final e in activeEntries) e.date: e};
    if (byDay.isEmpty) return 0;
    final dates = byDay.keys.toList()..sort();
    final p = dates.first.split('-').map(int.parse).toList();
    var d = DateTime(p[0], p[1], p[2]);
    final now = DateTime.now();
    // Today without an entry must not reset an ongoing run.
    final end = byDay[dayKey(now)] != null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
    final weekly = _weeklyWeekday;
    var longest = 0, run = 0;
    while (!d.isAfter(end)) {
      if (weekly != null && d.weekday != weekly) {
        d = DateTime(d.year, d.month, d.day + 1); // off-day: transparent
        continue;
      }
      final e = byDay[dayKey(d)];
      if (e == null || (!e.isSkip && e.didSlip)) {
        run = 0; // gap or slip breaks the run
      } else if (!e.isSkip) {
        run++;
        if (run > longest) longest = run;
      } // skip: pass through
      d = DateTime(d.year, d.month, d.day + 1);
    }
    // Same unit rule as currentStreak: days, not weeks.
    return weekly != null ? longest * 7 : longest;
  }

  /// HABIT STRENGTH (0-100): an exponentially weighted view of the last ~8
  /// weeks, where recent days matter most (14-day half-life). Unlike the
  /// streak it does NOT collapse to zero after one bad day, which is the
  /// single most common reason people abandon a tracker. Excused skips are
  /// transparent (neither credit nor penalty), matching every other getter.
  int get habitStrength {
    final byDay = {for (final e in activeEntries) e.date: e};
    if (byDay.isEmpty) return 0;
    final weekly = _weeklyWeekday;
    const halfLifeDays = 14.0;
    const windowDays = 56; // ~4 half-lives: older days add nothing visible
    // Days BEFORE the habit was created are out of scope: counting them
    // would cap a brand-new habit's score far below 100 no matter how
    // perfectly the user performs.
    final created = activeHabit?.createdAt;
    final floor = created == null
        ? null
        : DateTime(created.year, created.month, created.day);
    var weighted = 0.0, total = 0.0;
    var d = _todayMidnight;
    for (var i = 0; i < windowDays; i++, d = _minusDays(d, 1)) {
      if (floor != null && d.isBefore(floor)) break;
      // A weekly habit is only measured on its own weekday.
      if (weekly != null && d.weekday != weekly) continue;
      final e = byDay[dayKey(d)];
      if (e != null && e.isSkip) continue; // excused: transparent
      // Today counts only once logged, so an unfinished day never drags
      // the score down before it is over.
      if (i == 0 && e == null) continue;
      final w = _pow2(-i / halfLifeDays);
      total += w;
      if (e != null && !e.didSlip) weighted += w;
    }
    if (total <= 0) return 0;
    return (weighted / total * 100).round().clamp(0, 100);
  }

  /// 2^x without importing dart:math into this file's const-heavy scope.
  static double _pow2(double x) {
    var r = 1.0;
    var n = x;
    // exp(x * ln2) via repeated squaring on the integer part + a short
    // series on the fraction: accurate enough for a 0-100 display value.
    final whole = n.floor();
    n -= whole;
    if (whole >= 0) {
      for (var i = 0; i < whole; i++) {
        r *= 2;
      }
    } else {
      for (var i = 0; i < -whole; i++) {
        r /= 2;
      }
    }
    // 2^n for n in [0,1) = e^(n*ln2), 5 terms is well within display error.
    const ln2 = 0.6931471805599453;
    final y = n * ln2;
    final frac = 1 + y + y * y / 2 + y * y * y / 6 + y * y * y * y / 24;
    return r * frac;
  }

  bool get hasComeback =>
      activeEntries.any((e) => !e.isSkip && e.didSlip) && currentStreak >= 1;

  int get weekNumber {
    final h = activeHabit;
    if (h == null) return 1;
    final days = DateTime.now().difference(h.createdAt).inDays;
    final w = (days ~/ 7) + 1;
    return w.clamp(1, h.totalWeeks);
  }

  double get avgUrge {
    final recent = activeEntries.where((e) => !e.isSkip).take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.urge).reduce((a, b) => a + b) / recent.length;
  }

  double get avgResistance {
    final recent = activeEntries.where((e) => !e.isSkip).take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.resistance).reduce((a, b) => a + b) /
        recent.length;
  }

  /// Yesterday's entry for the active habit, or null (streak-repair banner).
  DailyEntry? entryForYesterday() {
    final id = activeHabitId;
    if (id == null) return null;
    final y = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    for (final e in entries) {
      if (e.date == y && e.habitId == id) return e;
    }
    return null;
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

  // ----- excused-day (skip) quotas: 2 per rolling week, 4 per rolling month,
  // counted PER HABIT from that habit's FIRST skip, renewing every 7 / ~30 days.
  static const int kSkipsPerWeek = 2;
  static const int kSkipsPerMonth = 4;

  /// The active habit's skip entries, oldest first.
  List<DailyEntry> get _activeSkips {
    final id = activeHabitId;
    if (id == null) return const [];
    final list = entries
        .where((e) => e.habitId == id && e.isSkip)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Skips used in the current rolling window since the FIRST-ever skip.
  /// [periodDays] = 7 (week) or 30 (month). Returns (used, limit).
  ({int used, int limit}) _skipUsage(int periodDays, int limit) {
    final skips = _activeSkips;
    if (skips.isEmpty) return (used: 0, limit: limit);
    final firstParts = skips.first.date.split('-').map(int.parse).toList();
    final anchor = DateTime(firstParts[0], firstParts[1], firstParts[2]);
    final today = DateTime.now();
    // How many whole periods have elapsed since the anchor; the current
    // window starts at anchor + periodsElapsed*period.
    final daysSince = today.difference(anchor).inDays;
    final periodsElapsed = daysSince < 0 ? 0 : daysSince ~/ periodDays;
    final windowStart = anchor.add(Duration(days: periodsElapsed * periodDays));
    final startKey = dayKey(windowStart);
    var used = 0;
    for (final e in skips) {
      if (e.date.compareTo(startKey) >= 0) used++;
    }
    return (used: used, limit: limit);
  }

  ({int used, int limit}) get weeklySkipUsage =>
      _skipUsage(7, kSkipsPerWeek);
  ({int used, int limit}) get monthlySkipUsage =>
      _skipUsage(30, kSkipsPerMonth);

  /// null = a skip is allowed now; otherwise 'week' or 'month' = the exhausted
  /// quota, so the UI can show the right message.
  String? skipBlockedBy() {
    final w = weeklySkipUsage;
    if (w.used >= w.limit) return 'week';
    final m = monthlySkipUsage;
    if (m.used >= m.limit) return 'month';
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

  /// Re-reads the persisted state after an EXTERNAL writer may have changed
  /// it - the home-screen widget's background quick-log writes entries from
  /// its own isolate while this isolate's SharedPreferences cache is stale.
  /// Called on app resume. Safe to replace wholesale because every in-app
  /// mutation persists immediately, so disk is always authoritative.
  Future<void> refreshFromStore() async {
    try {
      await _store.reload();
      state = state.copyWith(
        settings: _store.loadSettings(),
        habits: _store.loadHabits(),
        entries: _sorted(_store.loadEntries()),
        badges: _store.loadBadges(),
      );
    } catch (_) {
      // Fail-open: keep the in-memory state.
    }
  }

  // ---------- settings ----------
  Future<void> setLocale(String locale) async {
    final s = state.settings.copyWith(locale: locale);
    state = state.copyWith(settings: s);
    await _store.saveSettings(s);
    AnalyticsService.instance.locale = locale;
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
  /// Marks [date] (a dayKey) as an EXCUSED day for the active habit
  /// (travel/sickness): transparent to streaks, drawn distinctly.
  Future<void> skipDay(String date) async {
    final habit = state.activeHabit;
    if (habit == null) return;
    final entry = DailyEntry(
      id: _uuid.v4(),
      habitId: habit.id,
      date: date,
      urge: 0,
      resistance: 0,
      didSlip: false,
      entryType: 'skip',
      createdAt: DateTime.now(),
    );
    final list = [
      ...state.entries
          .where((e) => !(e.date == date && e.habitId == habit.id)),
      entry,
    ];
    final sorted = _sorted(list);
    state = state.copyWith(entries: sorted);
    await _store.saveEntries(sorted);
  }

  /// Streak repair: backfill YESTERDAY with a quick log (neutral sliders).
  /// Badges are re-evaluated on the next normal save.
  Future<void> backfillYesterday({required bool didSlip}) async {
    final habit = state.activeHabit;
    if (habit == null) return;
    final y = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (state.entries.any((e) => e.date == y && e.habitId == habit.id)) {
      return; // already covered
    }
    final entry = DailyEntry(
      id: _uuid.v4(),
      habitId: habit.id,
      date: y,
      urge: 5,
      resistance: 5,
      didSlip: didSlip,
      createdAt: DateTime.now(),
    );
    final sorted = _sorted([...state.entries, entry]);
    state = state.copyWith(entries: sorted);
    await _store.saveEntries(sorted);
  }

  Future<List<EarnedBadge>> saveEntry({
    required int urge,
    required int resistance,
    required bool didSlip,
    String? moodEmoji,
    String? moodLabel,
    String? note,
    String? trigger,
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
      trigger: didSlip ? trigger : null,
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
      'habit_track': habit.track,
      'catalog_key': habit.catalogKey,
    });

    return _evaluateAndAwardBadges();
  }

  /// Auto-logs a SPECIFIC habit as done for today WITHOUT changing the active
  /// habit. Used by the listening players (Quran wird, hadith radio): after the
  /// user has listened enough, today's entry is created automatically. Idempotent
  /// (does nothing if today is already logged for that habit). Returns true if a
  /// new entry was created.
  Future<bool> quickLogHabit(String habitId, {String? note}) async {
    Habit? habit;
    for (final h in state.habits) {
      if (h.id == habitId) {
        habit = h;
        break;
      }
    }
    if (habit == null) return false;
    final today = dayKey(DateTime.now());
    final already = state.entries
        .any((e) => e.date == today && e.habitId == habitId && !e.isSkip);
    if (already) return false; // never overwrite a manual log

    final rating = habit.track == 'build' ? 8 : 2; // mirrors buildQuickEntry
    final entry = buildQuickEntry(habit, today, note: note);
    final list = [
      ...state.entries.where((e) => !(e.date == today && e.habitId == habitId)),
      entry,
    ];
    final sorted = _sorted(list);
    state = state.copyWith(entries: sorted);
    await _store.saveEntries(sorted);
    AnalyticsService.instance.track('entry_saved', {
      'did_slip': false,
      'urge': rating,
      'resistance': rating,
      'habit_track': habit.track,
      'catalog_key': habit.catalogKey,
      'auto': true,
    });
    // The signed-in cloud push happens on the next app open / save (auto-sync).
    return true;
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

  /// Union-merge a cloud snapshot into EXISTING local data (sign-in on a
  /// device that already has habits, e.g. new phone onboarded as guest first).
  /// Habits union by id; entries union by (habit, date) with the newer
  /// createdAt winning. Nothing is dropped from either side.
  Future<void> mergeSnapshot(List<Habit> cloudHabits,
      List<DailyEntry> cloudEntries, SurveyData? cloudSurvey) async {
    final habitsById = {for (final h in state.habits) h.id: h};
    for (final h in cloudHabits) {
      habitsById.putIfAbsent(h.id, () => h);
    }
    final habits = habitsById.values.toList();

    final byKey = <String, DailyEntry>{};
    for (final e in [...cloudEntries, ...state.entries]) {
      final k = '${e.habitId}|${e.date}';
      final prev = byKey[k];
      if (prev == null || e.createdAt.isAfter(prev.createdAt)) byKey[k] = e;
    }
    final entries = _sorted(byKey.values.toList());

    var s = state.settings;
    if (habits.isNotEmpty) {
      s = s.copyWith(
        onboardingDone: true,
        activeHabitId: s.activeHabitId ?? habits.first.id,
      );
    }
    final survey = state.survey ?? cloudSurvey;
    final fields = state.fields.isEmpty
        ? seedFields(s.locale ?? 'ar',
            habits.isNotEmpty ? habits.first.track : 'break')
        : state.fields;
    state = state.copyWith(
        settings: s,
        habits: habits,
        entries: entries,
        survey: survey,
        fields: fields);
    await _store.saveSettings(s);
    await _store.saveHabits(habits);
    await _store.saveEntries(entries);
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
