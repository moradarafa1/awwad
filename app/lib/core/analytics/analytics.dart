import 'package:flutter/foundation.dart';

import '../cloud/supabase_service.dart';

/// Central, single-entry analytics layer (the "Data Layer").
///
/// Every tracked event in the app flows through [track]. Events are buffered
/// in memory and flushed in batches to the Supabase `analytics_events` table
/// (insert-only for clients; reads happen through admin RPCs) on app open and
/// after each saved daily entry. Flushing is FAIL-OPEN: any error keeps the
/// events buffered for the next flush and never surfaces to the UI.
///
/// Every event is enriched with the standard params {platform, app_version,
/// locale}; callers add habit_track / catalog_key where relevant. Adding a new
/// event later = one line in the allow-list + an entry in docs/tracking-plan.md
/// (which also carries the GA4/MMP name mapping). NO PII is ever passed in
/// [props].
class AnalyticsEvent {
  final String name;
  final Map<String, Object?> props;
  final DateTime at;
  AnalyticsEvent(this.name, this.props, this.at);
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  /// Keep in sync with the version line in settings_screen (bump on releases).
  static const String appVersion = '1.0.0';

  /// Current UI locale; set from main() at startup and on language change.
  String locale = 'ar';

  /// Never let an offline session grow the buffer unboundedly.
  static const int _maxBuffered = 200;

  final List<AnalyticsEvent> _buffer = [];
  List<AnalyticsEvent> get buffered => List.unmodifiable(_buffer);

  bool _flushing = false;

  /// Allow-listed event names — mirrors docs/tracking-plan.md.
  static const Set<String> _allowed = {
    'app_opened',
    'onboarding_started',
    'language_selected',
    'survey_shown',
    'survey_completed',
    'survey_skipped',
    'track_selected',
    'habit_selected',
    'habit_custom_created',
    'onboarding_completed',
    'entry_saved',
    'streak_milestone',
    'badge_earned',
    'badge_celebrated',
    'reminder_set',
    'religious_content_toggled',
    'data_exported',
    'account_deletion_requested',
    'popup_shown',
    'popup_cta_clicked',
    'notification_opened',
    'login_succeeded',
    'signup_succeeded',
    'otp_sent',
    'otp_verified',
    'device_trusted',
    'sos_opened',
    'sos_won',
    // Post-P1 additions (see docs/tracking-plan.md for the GA4/MMP mapping).
    'account_prompt_accepted',
    'account_prompt_declined',
    'add_habit_opened',
    'auth_choice',
    'custom_field_added',
    'dhikr_toggled',
    'habit_added',
    'habit_reminders_set',
    'habit_removed',
    'habit_switched',
    'notifications_toggled',
    'pomodoro_start',
    'pomodoro_complete',
  };

  void track(String name, [Map<String, Object?> props = const {}]) {
    assert(_allowed.contains(name), 'Unknown analytics event: $name (add it to tracking-plan.md & allow-list)');
    final event = AnalyticsEvent(name, {
      ...props,
      'platform': _platform,
      'app_version': appVersion,
      'locale': locale,
    }, DateTime.now());
    _buffer.add(event);
    if (_buffer.length > _maxBuffered) _buffer.removeAt(0);
    if (kDebugMode) {
      // ignore: avoid_print
      print('📊 analytics: $name ${event.props}');
    }
  }

  static String get _platform =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  /// Pushes all buffered events to Supabase `analytics_events` in one batch
  /// insert. Anonymous events are allowed by RLS (user_id NULL); signed-in
  /// events are stamped with the current user id at flush time. Fail-open:
  /// on any error the buffer is kept for the next flush (app open / next
  /// saved entry). Safe to call from anywhere via `unawaited(...)`.
  Future<void> flush() async {
    if (_flushing || _buffer.isEmpty || !SupabaseService.ready) return;
    _flushing = true;
    final batch = List<AnalyticsEvent>.from(_buffer);
    try {
      final userId = SupabaseService.currentUser?.id;
      final rows = batch
          .map((e) => {
                'user_id': userId,
                'event_name': e.name,
                'props': {...e.props}
                  ..remove('platform')
                  ..remove('app_version'),
                'platform': e.props['platform'],
                'app_version': e.props['app_version'],
                'occurred_at': e.at.toUtc().toIso8601String(),
              })
          .toList();
      await SupabaseService.client.from('analytics_events').insert(rows);
      // Drop exactly what was sent; events tracked mid-flight stay buffered.
      _buffer.removeRange(0, batch.length);
    } catch (_) {
      // Offline / transient / RLS error: keep the buffer, retry next flush.
    } finally {
      _flushing = false;
    }
  }
}
