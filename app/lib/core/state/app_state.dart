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

@immutable
class AppState {
  final AppSettings settings;
  final Habit? habit;
  final List<DailyEntry> entries; // newest first
  final SurveyData? survey;
  final List<EarnedBadge> badges;
  final List<CustomField> fields;

  const AppState({
    required this.settings,
    this.habit,
    this.entries = const [],
    this.survey,
    this.badges = const [],
    this.fields = const [],
  });

  AppState copyWith({
    AppSettings? settings,
    Habit? habit,
    List<DailyEntry>? entries,
    SurveyData? survey,
    List<EarnedBadge>? badges,
    List<CustomField>? fields,
  }) =>
      AppState(
        settings: settings ?? this.settings,
        habit: habit ?? this.habit,
        entries: entries ?? this.entries,
        survey: survey ?? this.survey,
        badges: badges ?? this.badges,
        fields: fields ?? this.fields,
      );

  List<CustomField> visibleFields(String group) =>
      (fields.where((f) => f.group == group && !f.hidden).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  List<CustomField> allFields(String group) =>
      (fields.where((f) => f.group == group).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  // ----- derived stats (computed locally; works offline) -----
  int get daysLogged => entries.length;
  int get cleanDays => entries.where((e) => !e.didSlip).length;

  int get currentStreak {
    var s = 0;
    for (final e in entries) {
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
    final asc = entries.reversed.toList();
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

  bool get hasComeback => entries.any((e) => e.didSlip) && currentStreak >= 1;

  int get weekNumber {
    if (habit == null) return 1;
    final days = DateTime.now().difference(habit!.createdAt).inDays;
    final w = (days ~/ 7) + 1;
    return w.clamp(1, habit!.totalWeeks);
  }

  double get avgUrge {
    final recent = entries.take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.urge).reduce((a, b) => a + b) / recent.length;
  }

  double get avgResistance {
    final recent = entries.take(7).toList();
    if (recent.isEmpty) return 0;
    return recent.map((e) => e.resistance).reduce((a, b) => a + b) /
        recent.length;
  }

  DailyEntry? entryForToday() {
    final today = dayKey(DateTime.now());
    for (final e in entries) {
      if (e.date == today) return e;
    }
    return null;
  }
}

class AppController extends Notifier<AppState> {
  late final LocalStore _store;

  @override
  AppState build() {
    _store = ref.read(localStoreProvider);
    return AppState(
      settings: _store.loadSettings(),
      habit: _store.loadHabit(),
      entries: _sorted(_store.loadEntries()),
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
    final s = state.settings.copyWith(onboardingDone: true);
    final fields = state.fields.isEmpty
        ? seedFields(state.settings.locale ?? 'ar', habit.track)
        : state.fields;
    state = state.copyWith(
        settings: s, habit: habit, survey: survey, fields: fields);
    await _store.saveHabit(habit);
    await _store.saveSettings(s);
    await _store.saveFields(fields);
    if (survey != null) await _store.saveSurvey(survey);
    AnalyticsService.instance.track('onboarding_completed', {
      'track': habit.track,
      'is_custom': habit.isCustom,
    });
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
    final habit = state.habit;
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

    final list = [...state.entries.where((e) => e.date != today), entry];
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
    final qualified = evaluateBadges(
      currentStreak: state.currentStreak,
      daysLogged: state.daysLogged,
      hasComeback: state.hasComeback,
    );
    final existingKeys = state.badges.map((b) => b.badgeKey).toSet();
    final newKeys = qualified.difference(existingKeys);
    if (newKeys.isEmpty) return const [];

    final newlyEarned = newKeys
        .map((k) => EarnedBadge(badgeKey: k, earnedAt: DateTime.now()))
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
    final all = state.badges
        .map((b) => b.badgeKey == badgeKey ? b.copyWith(celebrated: true) : b)
        .toList();
    state = state.copyWith(badges: all);
    await _store.saveBadges(all);
    AnalyticsService.instance.track('badge_celebrated', {'badge_key': badgeKey});
  }

  // ---------- cloud (P2) ----------
  /// Adopt a snapshot pulled from the cloud (first login on a fresh device).
  Future<void> importSnapshot(
      Habit habit, List<DailyEntry> entries, SurveyData? survey) async {
    final s = state.settings.copyWith(onboardingDone: true);
    final sorted = _sorted(entries);
    final fields = state.fields.isEmpty
        ? seedFields(state.settings.locale ?? 'ar', habit.track)
        : state.fields;
    state = state.copyWith(
        settings: s,
        habit: habit,
        entries: sorted,
        survey: survey,
        fields: fields);
    await _store.saveSettings(s);
    await _store.saveHabit(habit);
    await _store.saveEntries(sorted);
    await _store.saveFields(fields);
    if (survey != null) await _store.saveSurvey(survey);
  }

  // ---------- reset ----------
  Future<void> resetAll() async {
    await _store.clearAll();
    final s = state.settings.copyWith(onboardingDone: false);
    await _store.saveSettings(s);
    state = AppState(settings: s);
  }
}

final appControllerProvider =
    NotifierProvider<AppController, AppState>(AppController.new);
