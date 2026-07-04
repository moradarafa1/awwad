// Core data models for Awwad (P1 — local/offline).
// Plain immutable classes with JSON (de)serialization, no codegen.

class AppSettings {
  final String? locale; // null => follow device, choose in onboarding
  final bool showReligiousContent;
  final bool onboardingDone;
  final bool notificationsEnabled;
  final int reminderHour;
  final String? activeHabitId; // which habit the Today/Stats/History tabs show
  final bool authChoiceMade; // first-open: sign-in vs continue-as-guest answered
  final bool firstLogPromptShown; // the "create an account" popup shown once
  final bool notifPromptShown; // notification-permission rationale shown once
  final bool dhikrEnabled; // daily Ibrahimic-prayer dhikr notification
  final int dhikrHour; // when the daily dhikr fires

  const AppSettings({
    this.locale,
    this.showReligiousContent = true,
    this.onboardingDone = false,
    this.notificationsEnabled = true,
    this.reminderHour = 20,
    this.activeHabitId,
    this.authChoiceMade = false,
    this.firstLogPromptShown = false,
    this.notifPromptShown = false,
    this.dhikrEnabled = true,
    this.dhikrHour = 8,
  });

  AppSettings copyWith({
    String? locale,
    bool? showReligiousContent,
    bool? onboardingDone,
    bool? notificationsEnabled,
    int? reminderHour,
    String? activeHabitId,
    bool clearActiveHabit = false,
    bool? authChoiceMade,
    bool? firstLogPromptShown,
    bool? notifPromptShown,
    bool? dhikrEnabled,
    int? dhikrHour,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        showReligiousContent: showReligiousContent ?? this.showReligiousContent,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        activeHabitId:
            clearActiveHabit ? null : (activeHabitId ?? this.activeHabitId),
        authChoiceMade: authChoiceMade ?? this.authChoiceMade,
        firstLogPromptShown: firstLogPromptShown ?? this.firstLogPromptShown,
        notifPromptShown: notifPromptShown ?? this.notifPromptShown,
        dhikrEnabled: dhikrEnabled ?? this.dhikrEnabled,
        dhikrHour: dhikrHour ?? this.dhikrHour,
      );

  Map<String, dynamic> toJson() => {
        'locale': locale,
        'showReligiousContent': showReligiousContent,
        'onboardingDone': onboardingDone,
        'notificationsEnabled': notificationsEnabled,
        'reminderHour': reminderHour,
        'activeHabitId': activeHabitId,
        'authChoiceMade': authChoiceMade,
        'firstLogPromptShown': firstLogPromptShown,
        'notifPromptShown': notifPromptShown,
        'dhikrEnabled': dhikrEnabled,
        'dhikrHour': dhikrHour,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        locale: j['locale'] as String?,
        showReligiousContent: j['showReligiousContent'] as bool? ?? true,
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? true,
        reminderHour: j['reminderHour'] as int? ?? 20,
        activeHabitId: j['activeHabitId'] as String?,
        authChoiceMade: j['authChoiceMade'] as bool? ?? false,
        firstLogPromptShown: j['firstLogPromptShown'] as bool? ?? false,
        notifPromptShown: j['notifPromptShown'] as bool? ?? false,
        dhikrEnabled: j['dhikrEnabled'] as bool? ?? true,
        dhikrHour: j['dhikrHour'] as int? ?? 8,
      );
}

enum HabitTrack { breakHabit, buildHabit }

extension HabitTrackX on HabitTrack {
  String get id => this == HabitTrack.breakHabit ? 'break' : 'build';
  static HabitTrack fromId(String s) =>
      s == 'build' ? HabitTrack.buildHabit : HabitTrack.breakHabit;
}

class Habit {
  final String id;
  final String track; // 'break' | 'build'
  final String? catalogKey;
  final bool isCustom;
  final String title;
  final String? reason;
  final String templateKey;
  final int totalWeeks;
  final int reminderHour; // legacy single time (kept for migration)
  final List<int> reminderHours; // one or more daily reminder hours
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.track,
    this.catalogKey,
    this.isCustom = false,
    required this.title,
    this.reason,
    this.templateKey = 'generic',
    this.totalWeeks = 8,
    this.reminderHour = 20,
    this.reminderHours = const [],
    required this.createdAt,
  });

  /// The effective reminder times (falls back to the legacy single hour).
  List<int> get times =>
      reminderHours.isNotEmpty ? reminderHours : [reminderHour];

  Habit copyWith(
          {String? title,
          String? reason,
          int? reminderHour,
          List<int>? reminderHours}) =>
      Habit(
        id: id,
        track: track,
        catalogKey: catalogKey,
        isCustom: isCustom,
        title: title ?? this.title,
        reason: reason ?? this.reason,
        templateKey: templateKey,
        totalWeeks: totalWeeks,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderHours: reminderHours ?? this.reminderHours,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'track': track,
        'catalogKey': catalogKey,
        'isCustom': isCustom,
        'title': title,
        'reason': reason,
        'templateKey': templateKey,
        'totalWeeks': totalWeeks,
        'reminderHour': reminderHour,
        'reminderHours': reminderHours,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        track: j['track'] as String? ?? 'break',
        catalogKey: j['catalogKey'] as String?,
        isCustom: j['isCustom'] as bool? ?? false,
        title: j['title'] as String? ?? '',
        reason: j['reason'] as String?,
        templateKey: j['templateKey'] as String? ?? 'generic',
        totalWeeks: j['totalWeeks'] as int? ?? 8,
        reminderHour: j['reminderHour'] as int? ?? 20,
        reminderHours:
            (j['reminderHours'] as List<dynamic>?)?.cast<int>() ?? const [],
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class DailyEntry {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd (local day key)
  final int urge; // 1..10
  final int resistance; // 1..10
  final bool didSlip;
  final String? moodEmoji;
  final String? moodLabel;
  final String? note;
  final List<String> competingResponses; // selected labels (snapshot)
  final List<String> environment; // selected labels (snapshot)
  final DateTime createdAt;

  const DailyEntry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.urge,
    required this.resistance,
    required this.didSlip,
    this.moodEmoji,
    this.moodLabel,
    this.note,
    this.competingResponses = const [],
    this.environment = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date,
        'urge': urge,
        'resistance': resistance,
        'didSlip': didSlip,
        'moodEmoji': moodEmoji,
        'moodLabel': moodLabel,
        'note': note,
        'competingResponses': competingResponses,
        'environment': environment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DailyEntry.fromJson(Map<String, dynamic> j) => DailyEntry(
        id: j['id'] as String,
        habitId: j['habitId'] as String? ?? '',
        date: j['date'] as String,
        urge: j['urge'] as int? ?? 5,
        resistance: j['resistance'] as int? ?? 5,
        didSlip: j['didSlip'] as bool? ?? false,
        moodEmoji: j['moodEmoji'] as String?,
        moodLabel: j['moodLabel'] as String?,
        note: j['note'] as String?,
        competingResponses:
            (j['competingResponses'] as List<dynamic>? ?? []).cast<String>(),
        environment: (j['environment'] as List<dynamic>? ?? []).cast<String>(),
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class SurveyData {
  final bool consent;
  final String? ageRange;
  final String? gender;
  final String? country;
  final String? referralSource;

  const SurveyData({
    this.consent = false,
    this.ageRange,
    this.gender,
    this.country,
    this.referralSource,
  });

  Map<String, dynamic> toJson() => {
        'consent': consent,
        'ageRange': ageRange,
        'gender': gender,
        'country': country,
        'referralSource': referralSource,
      };

  factory SurveyData.fromJson(Map<String, dynamic> j) => SurveyData(
        consent: j['consent'] as bool? ?? false,
        ageRange: j['ageRange'] as String?,
        gender: j['gender'] as String?,
        country: j['country'] as String?,
        referralSource: j['referralSource'] as String?,
      );
}

class EarnedBadge {
  final String badgeKey;
  final DateTime earnedAt;
  final bool celebrated;
  final String? habitId; // badges are earned per-habit; null = legacy/global

  const EarnedBadge({
    required this.badgeKey,
    required this.earnedAt,
    this.celebrated = false,
    this.habitId,
  });

  EarnedBadge copyWith({bool? celebrated}) => EarnedBadge(
        badgeKey: badgeKey,
        earnedAt: earnedAt,
        celebrated: celebrated ?? this.celebrated,
        habitId: habitId,
      );

  Map<String, dynamic> toJson() => {
        'badgeKey': badgeKey,
        'earnedAt': earnedAt.toIso8601String(),
        'celebrated': celebrated,
        'habitId': habitId,
      };

  factory EarnedBadge.fromJson(Map<String, dynamic> j) => EarnedBadge(
        badgeKey: j['badgeKey'] as String,
        earnedAt:
            DateTime.tryParse(j['earnedAt'] as String? ?? '') ?? DateTime.now(),
        celebrated: j['celebrated'] as bool? ?? false,
        habitId: j['habitId'] as String?,
      );
}
