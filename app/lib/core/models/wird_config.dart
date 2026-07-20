/// Per-habit settings for a LISTENING wird (Qur'an, hadith and sunnah, du'a,
/// adhkar, salawat: anything the user completes by listening).
///
/// Owner brief, 2026-07-20:
///   - the user picks how many MINUTES count as one completed session,
///   - the user picks WHEN it should start, and may ask for it to start by
///     itself at that time,
///   - the user may want it more than once a day,
///   - but ONE completed session logs the habit for the day. Listening three
///     times does not log three times.
///
/// The minimum is five minutes, also his instruction: the old hardcoded
/// two-minute threshold logged a wird for barely more than a nod.
class WirdConfig {
  /// Whether this habit uses the listening wird at all.
  final bool enabled;

  /// Minutes of REAL listening that complete one session. Never below
  /// [kMinWirdMinutes]; the setter clamps rather than rejects so an older
  /// stored value can never disable the feature.
  final int minutesPerSession;

  /// Hours of the day (0-23) the user wants the wird at. Empty means "no
  /// schedule, I open it myself".
  final List<int> times;

  /// Start playing by itself at each scheduled time. When false the app only
  /// REMINDS at that time and the user presses play.
  ///
  /// Default false on purpose: audio that starts on its own without being
  /// asked is hostile, and on some devices it is also blocked.
  final bool autoPlay;

  /// How many sessions the user is aiming for per day. Purely a personal
  /// target shown in the UI: the habit is logged after the FIRST completed
  /// session regardless, per the owner's instruction.
  final int sessionsPerDay;

  const WirdConfig({
    this.enabled = false,
    this.minutesPerSession = kMinWirdMinutes,
    this.times = const [],
    this.autoPlay = false,
    this.sessionsPerDay = 1,
  });

  /// The floor the owner set. Anything shorter is not a wird.
  static const int kMinWirdMinutes = 5;
  static const int kMaxWirdMinutes = 120;
  static const int kMaxSessionsPerDay = 10;

  /// Seconds of real listening that complete a session. This is what the
  /// players count against, replacing the old hardcoded 120.
  int get secondsPerSession => minutesPerSession * 60;

  WirdConfig copyWith({
    bool? enabled,
    int? minutesPerSession,
    List<int>? times,
    bool? autoPlay,
    int? sessionsPerDay,
  }) =>
      WirdConfig(
        enabled: enabled ?? this.enabled,
        minutesPerSession: _clampMinutes(minutesPerSession ?? this.minutesPerSession),
        times: times ?? this.times,
        autoPlay: autoPlay ?? this.autoPlay,
        sessionsPerDay: _clampSessions(sessionsPerDay ?? this.sessionsPerDay),
      );

  static int _clampMinutes(int m) =>
      m < kMinWirdMinutes ? kMinWirdMinutes : (m > kMaxWirdMinutes ? kMaxWirdMinutes : m);

  static int _clampSessions(int n) =>
      n < 1 ? 1 : (n > kMaxSessionsPerDay ? kMaxSessionsPerDay : n);

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'minutesPerSession': minutesPerSession,
        'times': times,
        'autoPlay': autoPlay,
        'sessionsPerDay': sessionsPerDay,
      };

  /// Tolerant of anything on disk. A stored 2 (from before the five-minute
  /// floor existed) is clamped up, never honoured.
  factory WirdConfig.fromJson(Map<String, dynamic> j) => WirdConfig(
        enabled: j['enabled'] == true,
        minutesPerSession: _clampMinutes(
            (j['minutesPerSession'] as num?)?.toInt() ?? kMinWirdMinutes),
        times: ((j['times'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .where((h) => h >= 0 && h <= 23)
            .toList(),
        autoPlay: j['autoPlay'] == true,
        sessionsPerDay: _clampSessions((j['sessionsPerDay'] as num?)?.toInt() ?? 1),
      );

  @override
  bool operator ==(Object other) =>
      other is WirdConfig &&
      other.enabled == enabled &&
      other.minutesPerSession == minutesPerSession &&
      other.autoPlay == autoPlay &&
      other.sessionsPerDay == sessionsPerDay &&
      other.times.length == times.length &&
      other.times.every(times.contains);

  @override
  int get hashCode => Object.hash(
      enabled, minutesPerSession, autoPlay, sessionsPerDay, Object.hashAll(times));
}

/// Habits whose daily goal is completed by LISTENING. These are the ones that
/// get the wird card at the top of the habit page and the wird settings.
///
/// Keyed by catalog key so a custom habit never accidentally qualifies.
const Set<String> kListeningHabits = {
  'daily_quran',
  'hadith_wird',
  'listening_wird',
  'surah_kahf',
  'adhkar',
  'salawat',
  'dua',
};

bool isListeningHabit(String? catalogKey) =>
    catalogKey != null && kListeningHabits.contains(catalogKey);
