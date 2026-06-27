// Sync engine (P2). Pushes the local snapshot to Supabase and pulls it back so
// a user's data follows them across devices. RLS guarantees each row is scoped
// to auth.uid(). Conflict policy: last-write-wins via upsert on natural keys.
//
// STATUS: compiles and targets the real schema; needs a live Supabase project
// for end-to-end testing (P2). Covers habit + daily entries + survey. Per-event
// checklist selections (entry_selections) and custom fields sync land next.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'supabase_service.dart';

class CloudSnapshot {
  final Habit? habit;
  final List<DailyEntry> entries;
  final SurveyData? survey;
  const CloudSnapshot({this.habit, this.entries = const [], this.survey});
}

class SyncService {
  SyncService._();

  static SupabaseClient get _c => SupabaseService.client;
  static String? get _uid => SupabaseService.currentUser?.id;

  /// Push the local snapshot up. Safe to call repeatedly (idempotent upserts).
  static Future<void> pushAll({
    required Habit? habit,
    required List<DailyEntry> entries,
    required SurveyData? survey,
  }) async {
    final uid = _uid;
    if (uid == null || habit == null) return;

    await _c.from('habits').upsert({
      'id': habit.id,
      'user_id': uid,
      'track': habit.track,
      'is_custom': habit.isCustom,
      'title': habit.title,
      'reason': habit.reason,
      'template_key': habit.templateKey,
      'total_weeks': habit.totalWeeks,
      'reminder_hour': habit.reminderHour,
      'config': {'catalog_key': habit.catalogKey, 'origin': 'offline'},
    });

    if (entries.isNotEmpty) {
      await _c.from('daily_entries').upsert(
        entries
            .map((e) => {
                  'id': e.id,
                  'user_id': uid,
                  'habit_id': habit.id,
                  'entry_date': e.date,
                  'urge_level': e.urge,
                  'resistance_level': e.resistance,
                  'did_slip': e.didSlip,
                  'mood_label': e.moodLabel,
                  'mood_emoji': e.moodEmoji,
                  'note': e.note,
                })
            .toList(),
        onConflict: 'habit_id,entry_date',
      );
    }

    if (survey != null) {
      await _c.from('onboarding_survey').upsert({
        'user_id': uid,
        'consent': survey.consent,
        'age_range': survey.ageRange,
        'gender': survey.gender,
        'country': survey.country,
        'referral_source': survey.referralSource,
      }, onConflict: 'user_id');
    }
  }

  /// Pull the user's snapshot from the cloud (used on first login on a device).
  static Future<CloudSnapshot> pullAll() async {
    final uid = _uid;
    if (uid == null) return const CloudSnapshot();

    final habitRows = await _c.from('habits').select().eq('is_deleted', false).limit(1);
    Habit? habit;
    if (habitRows.isNotEmpty) {
      final h = habitRows.first;
      habit = Habit(
        id: h['id'] as String,
        track: h['track'] as String? ?? 'break',
        catalogKey: (h['config'] as Map?)?['catalog_key'] as String?,
        isCustom: h['is_custom'] as bool? ?? false,
        title: h['title'] as String? ?? '',
        reason: h['reason'] as String?,
        templateKey: h['template_key'] as String? ?? 'generic',
        totalWeeks: h['total_weeks'] as int? ?? 8,
        reminderHour: h['reminder_hour'] as int? ?? 20,
        createdAt:
            DateTime.tryParse(h['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }

    final entryRows = await _c
        .from('daily_entries')
        .select()
        .eq('is_deleted', false)
        .order('entry_date', ascending: false);
    final entries = entryRows
        .map((e) => DailyEntry(
              id: e['id'] as String,
              habitId: e['habit_id'] as String? ?? '',
              date: e['entry_date'] as String,
              urge: e['urge_level'] as int? ?? 5,
              resistance: e['resistance_level'] as int? ?? 5,
              didSlip: e['did_slip'] as bool? ?? false,
              moodEmoji: e['mood_emoji'] as String?,
              moodLabel: e['mood_label'] as String?,
              note: e['note'] as String?,
              createdAt: DateTime.tryParse(e['created_at'] as String? ?? '') ??
                  DateTime.now(),
            ))
        .toList();

    SurveyData? survey;
    final surveyRows = await _c.from('onboarding_survey').select().limit(1);
    if (surveyRows.isNotEmpty) {
      final s = surveyRows.first;
      survey = SurveyData(
        consent: s['consent'] as bool? ?? false,
        ageRange: s['age_range'] as String?,
        gender: s['gender'] as String?,
        country: s['country'] as String?,
        referralSource: s['referral_source'] as String?,
      );
    }

    return CloudSnapshot(habit: habit, entries: entries, survey: survey);
  }
}
