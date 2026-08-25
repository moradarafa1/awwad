export const meta = {
  name: 'awwad-session-adversarial-review',
  description: 'Adversarial multi-dimension review of the 2026-07-31 Awwad session diff, verify each finding',
  phases: [
    { title: 'Review', detail: '4 dimension reviewers over the session diff' },
    { title: 'Verify', detail: 'adversarial refutation of each finding' },
  ],
}

const REPO = 'D:/Claude/awwad'
const CONTEXT = `
Repo: ${REPO} (Flutter app in app/, Astro site in web/, docs in docs/).
Review ONLY this session's uncommitted changes: run "git -C ${REPO} status --short" and "git -C ${REPO} diff" (new untracked files: read them fully - app/android/app/src/main/kotlin/com/awwad/awwad/{AdhanScheduler,AdhanAlarmReceiver,AdhanService,AdhanBootReceiver}.kt, app/lib/core/prayer/adhan_native.dart, app/lib/core/catalog/habit_display.dart, app/lib/features/prayer/prayer_auto_note.dart, tests).
SESSION INTENT (judge against this):
1. Native Android adhan chain: Dart writes a 30-day table (buildAdhanTableJson in prayer_scheduler.dart) to SharedPreferences flutter.adhan_native_v1; AdhanScheduler.kt arms ONE setExactAndAllowWhileIdle alarm; AdhanAlarmReceiver re-arms FIRST then a lateness guard (<=5min: AdhanService FGS mediaPlayback plays adhan mp3, USAGE_ALARM, stops on volume keys via MediaSession VolumeProvider + VOLUME_CHANGED fallback + SCREEN_ON/OFF; 5-30min: silent late notification; >30min: nothing). Boot/time/timezone/exact-grant receivers re-arm. FLN no longer schedules Android adhan mains when native path active (double-notify guard). iOS keeps FLN path.
2. Exact-alarm grant UX: primer row + home MaterialBanner.
3. Adhan master switch in main Settings (_AdhanSettingsTile).
4. Onboarding location step (country -> nearest city + GPS auto-attempt, optional/skippable) saving PrayerConfig (adhanSound default on, mobile).
5. Icon picker (24 icons) removed everywhere; model field kept for compat.
6. pray_on_time renamed «الصلاة على وقتها» (catalog+seed+live DB), generic reminder suppressed for it (habitRemindersFor skip), PrayerAutoReminderNote replaces hour pickers.
7. Language audit fixes: habitDisplayTitle at all render sites; primer uses app locale; language chip reschedules everything.
HARD PROJECT RULES: trilingual ar(MSA)/en/fr everywhere user-facing, NO em-dash in user-facing text, offline-first, fail-open, no store-rejection risks, backward compat for stored data.
Report findings as JSON. Be precise with file:line. Only REAL defects (would misbehave for a user / store risk / rule violation), not style.`

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'line', 'title', 'detail', 'severity'],
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          title: { type: 'string' },
          detail: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'major', 'minor'] },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['isReal', 'reason'],
  properties: {
    isReal: { type: 'boolean' },
    reason: { type: 'string' },
  },
}

const DIMENSIONS = [
  {
    key: 'kotlin-android',
    prompt: `${CONTEXT}\nYOUR DIMENSION: the Kotlin/Android native adhan chain correctness. Hunt for: alarm chain breaks (rearm races, entry matching by "at", PendingIntent flags/requestCode collisions), service lifecycle bugs (leaks, startForeground timing, START_NOT_STICKY implications, finish() re-posting races, static instance races), receiver bugs (exported flags, protected broadcasts, boot re-arm), notification bugs (channel creation, FGS notification swipe behavior across API levels), MediaPlayer bugs (release, wake mode, error paths), API-level guards (minSdk compatibility of every call used: MediaSession/VolumeProvider API 21+, stopForeground constants, appops), manifest correctness. Compare against AndroidManifest.xml changes.`,
  },
  {
    key: 'dart-logic',
    prompt: `${CONTEXT}\nYOUR DIMENSION: Dart-side logic. Hunt for: prayer_scheduler branch bugs (double-notify or NO-notify cases: e.g. when native adhan active are FLN mains correctly skipped but PRE-ALERTS kept? when adhan off does everything restore?), clearNativeAdhan on every exit path, buildAdhanTableJson correctness (windows, offsets, locale copy, DST/timezone pitfalls with epoch ms), habitDisplayTitle correctness at every call site (loc variable in scope and correct, background isolate safety), habitRemindersFor pray_on_time skip side effects (does pray_on_time still get RESCHEDULED wird/other flows?), settings _AdhanSettingsTile state bugs (stale _cfg after returning from prayer settings, context.mounted misuse), onboarding location step bugs (state races, _savePrayerLocation overwriting existing config wrongly, GPS flow), language-chip reschedule (uses _applySchedule with right locale, runs on web safely), notification_actions changes.`,
  },
  {
    key: 'i18n-content',
    prompt: `${CONTEXT}\nYOUR DIMENSION: i18n + content rules. Hunt for: any NEW user-facing string missing ar/en/fr or using colloquial Arabic instead of MSA, any em-dash (—) in new user-facing strings (grep the diff), RTL/bidi hazards (lines starting with Latin in Arabic strings, mixed-direction concatenations like the PrayerAutoReminderNote times line), habitDisplayTitle language-fallback correctness (CatalogHabit.t fallback), the seed.sql/catalog/live-DB consistency claim (compare app/lib/core/catalog/habit_catalog.dart pray_on_time entry vs supabase/seed.sql), stored-data compat (old titles migration only exact match).`,
  },
  {
    key: 'policy-regression',
    prompt: `${CONTEXT}\nYOUR DIMENSION: store policy + regressions. Hunt for: Play policy risks in the new manifest permissions/service (FOREGROUND_SERVICE_MEDIA_PLAYBACK declaration needs, SCHEDULE_EXACT_ALARM already declared, boot receiver actions), regressions to EXISTING behavior: iOS path unchanged? web build unaffected (no dart:io / MethodChannel at import time on web - check adhan_native.dart guards), FLN id-space collisions with native notification id 6100 vs documented id namespace in notifications_mobile.dart header, removed icon picker leaving dead refs (kCustomHabitIcons uses), tests deleted/weakened, docs drift (PROJECT_STATE changelog claims vs actual code).`,
  },
]

const results = await pipeline(
  DIMENSIONS,
  (d) => agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA }),
  (review, d) =>
    parallel(
      (review?.findings ?? []).slice(0, 10).map((f) => () =>
        agent(
          `${CONTEXT}\nADVERSARIALLY VERIFY this claimed defect. Read the actual code at ${f.file}:${f.line} and everything it interacts with. Try hard to REFUTE it: is it truly a user-visible defect / store risk / rule violation given how the code is actually called? If uncertain after reading, isReal=false.\nCLAIM [${f.severity}] ${f.title}\n${f.detail}`,
          { label: `verify:${d.key}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ).then((v) => ({ ...f, dimension: d.key, verdict: v }))
      )
    )
)

const all = results.filter(Boolean).flat().filter(Boolean)
const confirmed = all.filter((f) => f.verdict?.isReal)
const refuted = all.filter((f) => f.verdict && !f.verdict.isReal)
return {
  confirmed,
  refutedCount: refuted.length,
  refutedTitles: refuted.map((f) => `[${f.severity}] ${f.title}: ${f.verdict.reason}`),
}