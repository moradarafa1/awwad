// Core data models for Awwad (P1 — local/offline).
// Plain immutable classes with JSON (de)serialization, no codegen.

class AppSettings {
  final String? locale; // null => follow device, choose in onboarding
  final bool showReligiousContent;
  final bool onboardingDone;
  final bool notificationsEnabled;
  final int reminderHour;

  const AppSettings({
    this.locale,
    this.showReligiousContent = true,
    this.onboardingDone = false,
    this.notificationsEnabled = true,
    this.reminderHour = 20,
  });

  AppSettings copyWith({
    String? locale,
    bool? showReligiousContent,
    bool? onboardingDone,
    bool? notificationsEnabled,
    int? reminderHour,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        showReligiousContent: showReligiousContent ?? this.showReligiousContent,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
      );

  Map<String, dynamic> toJson() => {
        'locale': locale,
        'showReligiousContent': showReligiousContent,
        'onboardingDone': onboardingDone,
        'notificationsEnabled': notificationsEnabled,
        'reminderHour': reminderHour,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        locale: j['locale'] as String?,
        showReligiousContent: j['showReligiousContent'] as bool? ?? true,
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? true,
        reminderHour: j['reminderHour'] as int? ?? 20,
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
  final int reminderHour;
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
    required this.createdAt,
  });

  Habit copyWith({String? title, String? reason, int? reminderHour}) => Habit(
        id: id,
        track: track,
        catalogKey: catalogKey,
        isCustom: isCustom,
        title: title ?? this.title,
        reason: reason ?? this.reason,
        templateKey: templateKey,
        totalWeeks: totalWeeks,
        reminderHour: reminderHour ?? this.reminderHour,
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

  const EarnedBadge({
    required this.badgeKey,
    required this.earnedAt,
    this.celebrated = false,
  });

  EarnedBadge copyWith({bool? celebrated}) => EarnedBadge(
        badgeKey: badgeKey,
        earnedAt: earnedAt,
        celebrated: celebrated ?? this.celebrated,
      );

  Map<String, dynamic> toJson() => {
        'badgeKey': badgeKey,
        'earnedAt': earnedAt.toIso8601String(),
        'celebrated': celebrated,
      };

  factory EarnedBadge.fromJson(Map<String, dynamic> j) => EarnedBadge(
        badgeKey: j['badgeKey'] as String,
        earnedAt:
            DateTime.tryParse(j['earnedAt'] as String? ?? '') ?? DateTime.now(),
        celebrated: j['celebrated'] as bool? ?? false,
      );
}
