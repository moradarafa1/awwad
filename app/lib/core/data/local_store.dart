import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../custom_field.dart';

/// Synchronous-read local store backed by SharedPreferences.
/// SharedPreferences caches values in memory after [getInstance], so reads
/// here are synchronous; writes are fire-and-forget Futures.
///
/// This is the P1 offline source of truth. In P2 it is replaced behind the
/// same surface by Drift + a sync engine to Supabase.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  /// Refreshes this isolate's SharedPreferences cache from disk. Needed after
  /// an EXTERNAL writer changed the data - the home-screen widget's quick-log
  /// runs in a background isolate with its own copy of the cache.
  Future<void> reload() => _prefs.reload();

  static const _kSettings = 'awwad_settings';
  static const _kHabit = 'awwad_habit'; // legacy single-habit (migration source)
  static const _kHabits = 'awwad_habits'; // multi-habit list
  static const _kEntries = 'awwad_entries';
  static const _kSurvey = 'awwad_survey';
  static const _kBadges = 'awwad_badges';
  static const _kFields = 'awwad_fields';

  AppSettings loadSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings s) =>
      _prefs.setString(_kSettings, jsonEncode(s.toJson()));

  /// Legacy single-habit reader, kept only to migrate old installs.
  Habit? loadLegacyHabit() {
    final raw = _prefs.getString(_kHabit);
    if (raw == null) return null;
    return Habit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<Habit> loadHabits() {
    final raw = _prefs.getString(_kHabits);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveHabits(List<Habit> habits) => _prefs.setString(
      _kHabits, jsonEncode(habits.map((h) => h.toJson()).toList()));

  Future<void> clearLegacyHabit() => _prefs.remove(_kHabit);

  List<DailyEntry> loadEntries() {
    final raw = _prefs.getString(_kEntries);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DailyEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveEntries(List<DailyEntry> entries) => _prefs.setString(
      _kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));

  SurveyData? loadSurvey() {
    final raw = _prefs.getString(_kSurvey);
    if (raw == null) return null;
    return SurveyData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSurvey(SurveyData s) =>
      _prefs.setString(_kSurvey, jsonEncode(s.toJson()));

  List<EarnedBadge> loadBadges() {
    final raw = _prefs.getString(_kBadges);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EarnedBadge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBadges(List<EarnedBadge> badges) => _prefs.setString(
      _kBadges, jsonEncode(badges.map((e) => e.toJson()).toList()));

  List<CustomField> loadFields() {
    final raw = _prefs.getString(_kFields);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CustomField.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFields(List<CustomField> fields) => _prefs.setString(
      _kFields, jsonEncode(fields.map((e) => e.toJson()).toList()));

  // ---- Pomodoro session (survives app restarts) ----
  static const _kPomodoro = 'awwad_pomodoro_v1';
  Map<String, dynamic>? loadPomodoro() {
    final raw = _prefs.getString(_kPomodoro);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePomodoro(Map<String, dynamic> state) =>
      _prefs.setString(_kPomodoro, jsonEncode(state));

  Future<void> clearPomodoro() async {
    await _prefs.remove(_kPomodoro);
  }

  // ---- Prayer-times config (location + offsets + pre-alert toggle) ----
  static const _kPrayer = 'awwad_prayer_v1';
  Map<String, dynamic>? loadPrayer() {
    final raw = _prefs.getString(_kPrayer);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePrayer(Map<String, dynamic> cfg) =>
      _prefs.setString(_kPrayer, jsonEncode(cfg));

  // ---- Quran listening wird (reciter + surah, to resume) ----
  static const _kQuranWird = 'awwad_quran_wird_v1';
  Map<String, dynamic>? loadQuranWird() {
    final raw = _prefs.getString(_kQuranWird);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveQuranWird(Map<String, dynamic> w) =>
      _prefs.setString(_kQuranWird, jsonEncode(w));

  Future<void> clearAll() async {
    await _prefs.remove(_kHabit);
    await _prefs.remove(_kHabits);
    await _prefs.remove(_kEntries);
    await _prefs.remove(_kSurvey);
    await _prefs.remove(_kBadges);
    await _prefs.remove(_kFields);
    // Everything else the user generated. The delete/erase copy promises
    // «كل بياناتك», and prayer config in particular holds real GPS
    // coordinates, so leaving these behind made that claim false.
    await _prefs.remove(_kPrayer);
    await _prefs.remove(_kPomodoro);
    await _prefs.remove(_kQuranWird);
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith('awwad_tasbih_v1_') ||
          k == 'app_usage_limits_v1' ||
          k == 'awwad_pull_pending') {
        await _prefs.remove(k);
      }
    }
    // settings (incl. locale) intentionally preserved; onboarding flag reset by caller.
  }
}
