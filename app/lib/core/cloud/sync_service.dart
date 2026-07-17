// Sync engine (P2). Pushes the local snapshot to Supabase and pulls it back so
// a user's data follows them across devices. RLS guarantees each row is scoped
// to auth.uid(). Conflict policy: last-write-wins via upsert on natural keys.
//
// STATUS: compiles and targets the real schema; needs a live Supabase project
// for end-to-end testing (P2). Covers habit + daily entries + survey. Per-event
// checklist selections (entry_selections) and custom fields sync land next.

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'supabase_service.dart';

class CloudSnapshot {
  final List<Habit> habits;
  final List<DailyEntry> entries;
  final SurveyData? survey;
  const CloudSnapshot({this.habits = const [], this.entries = const [], this.survey});
}

class SyncService {
  SyncService._();

  static SupabaseClient get _c => SupabaseService.client;
  static String? get _uid => SupabaseService.currentUser?.id;

  // The account that OWNS the data on this device. Set after any successful
  // push/pull; checked before every push so one person's private relapse
  // history can never be uploaded into somebody else's account on a shared
  // device (they sign out, a relative signs in...).
  static const _kOwnerUid = 'awwad_owner_uid';

  static Future<String?> ownerUid() async =>
      (await SharedPreferences.getInstance()).getString(_kOwnerUid);

  static Future<void> _markOwner(String uid) async =>
      (await SharedPreferences.getInstance()).setString(_kOwnerUid, uid);

  static Future<void> clearOwner() async =>
      (await SharedPreferences.getInstance()).remove(_kOwnerUid);

  /// Push the local snapshot up. Safe to call repeatedly (idempotent upserts).
  static Future<void> pushAll({
    required List<Habit> habits,
    required List<DailyEntry> entries,
    required SurveyData? survey,
  }) async {
    final uid = _uid;
    if (uid == null || habits.isEmpty) return;
    final owner = await ownerUid();
    if (owner != null && owner != uid) {
      // Data on this device belongs to another account; never cross-upload.
      debugPrint('awwad sync: push blocked (device data owned by $owner)');
      return;
    }

    await _c.from('habits').upsert([
      for (final habit in habits)
        {
          'id': habit.id,
          'user_id': uid,
          'track': habit.track,
          'is_custom': habit.isCustom,
          'title': habit.title,
          'reason': habit.reason,
          'template_key': habit.templateKey,
          'total_weeks': habit.totalWeeks,
          'reminder_hour': habit.reminderHour,
          // Client creation time: without it a restore misdates every habit
          // to the first push, which corrupts streak/anniversary math.
          'created_at': habit.createdAt.toUtc().toIso8601String(),
          'config': {
            'catalog_key': habit.catalogKey,
            'origin': 'offline',
            'reminder_hours': habit.reminderHours,
            if ((habit.customMetricPrimary ?? '').isNotEmpty)
              'metric_p': habit.customMetricPrimary,
            if ((habit.customMetricSecondary ?? '').isNotEmpty)
              'metric_s': habit.customMetricSecondary,
            if (habit.costPerDay != null) 'cost_per_day': habit.costPerDay,
            if (habit.minutesPerDay != null)
              'minutes_per_day': habit.minutesPerDay,
          },
        }
    ]);

    if (entries.isNotEmpty) {
      await _c.from('daily_entries').upsert(
        entries
            .map((e) => {
                  'id': e.id,
                  'user_id': uid,
                  'habit_id': e.habitId,
                  'entry_date': e.date,
                  // Skip (excused) days carry 0/0 locally, but the DB checks
                  // demand 1..10: nulls pass the checks and mean "no rating".
                  // Without this, ONE skip entry poisoned the whole atomic
                  // upsert and silently killed entry backup forever.
                  'urge_level': e.isSkip ? null : e.urge,
                  'resistance_level': e.isSkip ? null : e.resistance,
                  'did_slip': e.didSlip,
                  'mood_label': e.moodLabel,
                  'mood_emoji': e.moodEmoji,
                  'note': e.note,
                  'entry_type': e.entryType,
                  'trigger_key': e.trigger,
                  'created_at': e.createdAt.toUtc().toIso8601String(),
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

    await _markOwner(uid);
  }

  /// Tombstone one habit (and its entries) in the cloud so it cannot
  /// resurrect on the next pull after the user deleted it locally.
  static Future<void> deleteHabitCloud(String habitId) async {
    final uid = _uid;
    if (uid == null) return;
    await _c
        .from('daily_entries')
        .update({'is_deleted': true}).eq('habit_id', habitId);
    await _c.from('habits').update({'is_deleted': true}).eq('id', habitId);
  }

  /// Tombstone EVERYTHING for the signed-in user ("erase my data"): the local
  /// wipe must not quietly leave a full relapse history in the cloud.
  static Future<void> deleteAllCloud() async {
    final uid = _uid;
    if (uid == null) return;
    await _c.from('daily_entries').update({'is_deleted': true}).eq('user_id', uid);
    await _c.from('habits').update({'is_deleted': true}).eq('user_id', uid);
  }

  /// Pull the user's snapshot from the cloud (used on first login on a device).
  static Future<CloudSnapshot> pullAll() async {
    final uid = _uid;
    if (uid == null) return const CloudSnapshot();

    final habitRows = await _c
        .from('habits')
        .select()
        .eq('is_deleted', false)
        .order('created_at', ascending: true);
    final habits = habitRows
        .map((h) => Habit(
              id: h['id'] as String,
              track: h['track'] as String? ?? 'break',
              catalogKey: (h['config'] as Map?)?['catalog_key'] as String?,
              customMetricPrimary:
                  (h['config'] as Map?)?['metric_p'] as String?,
              customMetricSecondary:
                  (h['config'] as Map?)?['metric_s'] as String?,
              costPerDay:
                  ((h['config'] as Map?)?['cost_per_day'] as num?)?.toDouble(),
              minutesPerDay:
                  ((h['config'] as Map?)?['minutes_per_day'] as num?)?.toInt(),
              isCustom: h['is_custom'] as bool? ?? false,
              title: h['title'] as String? ?? '',
              reason: h['reason'] as String?,
              templateKey: h['template_key'] as String? ?? 'generic',
              totalWeeks: h['total_weeks'] as int? ?? 8,
              reminderHour: h['reminder_hour'] as int? ?? 20,
              reminderHours: ((h['config'] as Map?)?['reminder_hours'] as List?)
                      ?.whereType<num>()
                      .map((n) => n.toInt())
                      .toList() ??
                  const [],
              createdAt: DateTime.tryParse(h['created_at'] as String? ?? '') ??
                  DateTime.now(),
            ))
        .toList();

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
              // Skip entries store NULL ratings in the cloud (see pushAll);
              // locally they are 0/0.
              urge: e['urge_level'] as int? ??
                  ((e['entry_type'] as String?) == 'skip' ? 0 : 5),
              resistance: e['resistance_level'] as int? ??
                  ((e['entry_type'] as String?) == 'skip' ? 0 : 5),
              didSlip: e['did_slip'] as bool? ?? false,
              moodEmoji: e['mood_emoji'] as String?,
              moodLabel: e['mood_label'] as String?,
              note: e['note'] as String?,
              entryType: e['entry_type'] as String? ?? 'log',
              trigger: e['trigger_key'] as String?,
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

    await _markOwner(uid);
    return CloudSnapshot(habits: habits, entries: entries, survey: survey);
  }
}
