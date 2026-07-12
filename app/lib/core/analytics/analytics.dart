import 'package:flutter/foundation.dart';

/// Central, single-entry analytics layer (the "Data Layer").
///
/// Every tracked event in the app flows through [track]. In P1 events are
/// buffered locally and logged in debug; in P2 the same surface flushes to the
/// Supabase `analytics_events` table. Adding a new event later = one line here +
/// an entry in docs/tracking-plan.md. NO PII is ever passed in [props].
class AnalyticsEvent {
  final String name;
  final Map<String, Object?> props;
  final DateTime at;
  AnalyticsEvent(this.name, this.props, this.at);
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final List<AnalyticsEvent> _buffer = [];
  List<AnalyticsEvent> get buffered => List.unmodifiable(_buffer);

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
  };

  void track(String name, [Map<String, Object?> props = const {}]) {
    assert(_allowed.contains(name), 'Unknown analytics event: $name (add it to tracking-plan.md & allow-list)');
    final event = AnalyticsEvent(name, props, DateTime.now());
    _buffer.add(event);
    if (kDebugMode) {
      // ignore: avoid_print
      print('📊 analytics: $name $props');
    }
    // P2: enqueue + flush to Supabase analytics_events here.
  }
}
