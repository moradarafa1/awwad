export const meta = {
  name: 'awwad-features-batch-review',
  description: 'Adversarial review: streak-skip logic, repair/skip flows, journey cards, sync fields',
  phases: [{ title: 'Review' }, { title: 'Verify' }],
}
const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['file', 'line', 'severity', 'title', 'detail'],
    properties: {
      file: { type: 'string' }, line: { type: 'number' },
      severity: { enum: ['critical', 'major', 'minor'] },
      title: { type: 'string' }, detail: { type: 'string' },
    } } } },
}
const VERDICT = {
  type: 'object', required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } },
}
phase('Review')
const DIMS = [
  { key: 'streaks', prompt: `Review the NEW streak-protection feature for CORRECTNESS. Files: D:\\Claude\\awwad\\app\\lib\\core\\state\\app_state.dart (skip-transparent streak getters daysLogged/cleanDays/currentStreak/longestStreak/hasComeback/avgUrge/avgResistance, new skipDay/backfillYesterday, and the trigger param on saveEntry), D:\\Claude\\awwad\\app\\lib\\core\\models.dart (DailyEntry entryType/trigger + Habit costPerDay/minutesPerDay). CRITICAL interactions to check: badge evaluation (core/catalog/badge_catalog.dart evaluateBadges called in saveEntry) - do skip entries corrupt badge thresholds?; habit_stages.dart thresholds driven by which counter?; daily_log_screen _hydrateFromToday with a SKIP entry for today (save button state? entryForToday non-null -> what does the UI show/allow?); backfillYesterday creating entries out of order vs _sorted; the streak repair banner condition (habit created yesterday? timezone of createdAt vs dayKey).` },
  { key: 'ui-sync', prompt: `Review the NEW UI + sync changes for CORRECTNESS. Files: D:\\Claude\\awwad\\app\\lib\\features\\home\\daily_log_screen.dart (trigger chips, rank line, yesterday-repair banner + sheet, skip-today flow, auto-push after save), D:\\Claude\\awwad\\app\\lib\\features\\home\\month_heatmap.dart (skip cell/legend/sheet), D:\\Claude\\awwad\\app\\lib\\features\\home\\journey_cards.dart (RecoveryTimelineCard firstWhere usage!, SavingsCard math, TriggersCard), D:\\Claude\\awwad\\app\\lib\\features\\home\\stats_screen.dart integration, D:\\Claude\\awwad\\app\\lib\\core\\cloud\\sync_service.dart (entry_type/trigger_key/cost/minutes roundtrip vs the applied DB migration columns). Hunt: firstWhere orElse type errors at runtime, Dart cast/collection-if mistakes, RTL/l10n key misses (every _tr/_dl/_jc key exists in all 3 locales), context.mounted misuse in sheets, and whether the repair sheet needs a setState after pop to refresh the banner.` },
]
const results = await pipeline(
  DIMS,
  d => agent(d.prompt + ' Report ONLY defects you are confident are real (no style nits). For each: file, line, severity, title, one-paragraph detail with the concrete failing scenario.', {label: `review:${d.key}`, phase: 'Review', schema: FINDINGS}),
  (review, d) => parallel((review?.findings ?? []).map(f => () =>
    agent(`Adversarially VERIFY this claimed defect by reading the actual files. Default isReal=false unless you can trace the failure concretely at runtime. Claim: [${f.severity}] ${f.title} - ${f.detail} (${f.file}:${f.line})`, {label: `verify:${d.key}`, phase: 'Verify', schema: VERDICT})
      .then(v => ({...f, verdict: v}))
  ))
)
const confirmed = results.flat().filter(Boolean).filter(f => f.verdict?.isReal)
return { confirmed, totalChecked: results.flat().filter(Boolean).length }