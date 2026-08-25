export const meta = {
  name: 'awwad-full-audit',
  description: 'Comprehensive adversarial audit of the whole Awwad project: core logic, platform/mobile, security, Arabic content and UX truthfulness',
  phases: [{ title: 'Hunt' }, { title: 'Verify' }],
}

const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['file', 'line', 'problem', 'fix', 'severity'],
    properties: {
      file: { type: 'string' }, line: { type: 'number' },
      problem: { type: 'string' }, fix: { type: 'string' },
      severity: { enum: ['blocker', 'major', 'minor'] },
    } } } },
}
const VERDICT = {
  type: 'object', required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } },
}

const CTX = String.raw`PROJECT: Awwad (عوّاد), trilingual Arabic-first habit app. Flutter app at D:\Claude\awwad\app (offline-first, SharedPreferences via LocalStore, Riverpod, optional Supabase cloud sync), Astro site at D:\Claude\awwad\web, Supabase SQL at D:\Claude\awwad\supabase.
ALREADY KNOWN AND FIXED TODAY (do NOT re-report): missing flutter_local_notifications receivers in the manifest; missing proguard keep rules for GSON; permission-denial not flipping the notifications toggle; 15 layout overflow defects incl. the pomodoro infinite-width crash; skip-quota UI wiring.
RULES: STRICTLY READ-ONLY - edit nothing. Do NOT run flutter/dart/gradle/npm (builds run concurrently; locks will collide). Diagnose by reading source only. Report REAL defects a user would hit or an attacker could exploit, with concrete evidence. An empty findings list is a valid result. Severity: blocker = data loss/crash/dead feature; major = wrong behaviour a normal user hits; minor = polish.`

phase('Hunt')
const LENSES = [
  { key: 'core-logic', prompt: String.raw`LENS: core state correctness. Files: app/lib/core/state/app_state.dart (streaks, badges, skip quotas, multi-habit scoping, migrations), app/lib/core/models.dart (json roundtrips, copyWith gaps), app/lib/core/data/local_store.dart, app/lib/core/catalog/*.dart. Hunt: calendar/streak edge cases (DST, month boundaries, entries out of order, duplicate dates), badge award/revoke asymmetries, skip-quota window math abuse (backfilled yesterday-skips vs the anchor), activeHabit null paths after deleting the active habit, migration paths that drop fields (e.g. copyWith missing a field so an edit silently erases another), JSON fields written but never read back or vice versa.` },
  { key: 'cloud-sync', prompt: String.raw`LENS: cloud + sync integrity. Files: app/lib/core/cloud/supabase_service.dart, app/lib/core/cloud/sync_service.dart, app/lib/features/auth/auth_screen.dart (flows), supabase/migrations/*.sql, supabase/seed.sql. Hunt: push/pull races that duplicate or lose entries (importSnapshot vs local data), sync of deleted habits/entries (tombstones? or do deletions resurrect on next pull), fields silently not synced (customMetric*, costPerDay, entryType, trigger - check EVERY model field against sync_service columns), auth state edge cases (sign-out leaves other user's data on device? sign-in on a device with existing guest data - merge or clobber?), RLS assumptions the client violates, PII leaking into analytics props.` },
  { key: 'platform-mobile', prompt: String.raw`LENS: Android/iOS/web platform behaviour. Files: app/lib/core/notifications/* (remaining issues beyond the fixed receivers/proguard: notification ids colliding, 60-slot cap vs 6 habits x N times, timezone changes while app installed, hour-only scheduling vs minute precision), app/lib/core/platform/usage_stats.dart + android/app/src/main/kotlin MainActivity.kt (channel contract mismatches, exceptions on old Android versions), app/lib/features/shield/dns_shield_screen.dart, web stubs (notifications_stub, usage on web - every mobile-only feature must no-op gracefully on web), app/web/index.html + passkeys bundle, connectivity_plus usage. Also: pubspec dependency versions with known breaking behaviour.` },
  { key: 'arabic-ux', prompt: String.raw`LENS: Arabic quality + UX truthfulness (the app is Arabic-first for Muslim users). Files: app/lib/l10n/app_ar.arb (vs en/fr - missing keys, MSA purity, no Egyptian colloquial), inline _strings maps across features (pomodoro, sos, settings, habits, add_habit, usage, shield - ar/en/fr key parity: a missing key in one locale crashes with ! operator), core/catalog/habit_catalog.dart + habit_content.dart (religious accuracy red flags, em-dash violations anywhere user-facing), bidi hazards (Latin tokens at line starts in Arabic strings), numbers/dates localization, and UX lies: UI text promising something the code does not do (e.g. "syncs when back online" claims, reminder wording vs actual behaviour).` },
]

const results = await pipeline(
  LENSES,
  l => agent(`${CTX}

${l.prompt}`, { label: `hunt:${l.key}`, phase: 'Hunt', schema: FINDINGS }),
  rev => parallel((rev?.findings ?? []).filter(f => f.severity !== 'minor').map(f => () =>
    agent(`${CTX}

ADVERSARIALLY VERIFY by reading the code. Default isReal=false unless the source plainly proves it. Quote the decisive lines in your reason.
CLAIM: ${f.file}:${f.line} [${f.severity}] - ${f.problem} (proposed fix: ${f.fix})`,
      { label: 'verify', phase: 'Verify', schema: VERDICT })
      .then(v => ({ ...f, verdict: v }))))
)

const all = results.flat().filter(Boolean)
const confirmed = all.filter(f => f.verdict?.isReal)
log(`${all.length} candidates -> ${confirmed.length} confirmed`)
return {
  confirmed,
  rejected: all.filter(f => !f.verdict?.isReal).map(f => `${f.file}:${f.line} :: ${(f.verdict?.reason || '').slice(0, 120)}`),
}
