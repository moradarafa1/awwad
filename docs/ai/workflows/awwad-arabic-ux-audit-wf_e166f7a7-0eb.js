export const meta = {
  name: 'awwad-arabic-ux-audit',
  description: 'Arabic quality + UX truthfulness lens (rerun of the lens that died on the session limit)',
  phases: [{ title: 'Hunt' }, { title: 'Verify' }],
}
const FINDINGS = { type: 'object', required: ['findings'], properties: { findings: { type: 'array', items: {
  type: 'object', required: ['file', 'line', 'problem', 'fix', 'severity'],
  properties: { file: { type: 'string' }, line: { type: 'number' }, problem: { type: 'string' }, fix: { type: 'string' }, severity: { enum: ['blocker', 'major', 'minor'] } } } } } }
const VERDICT = { type: 'object', required: ['isReal', 'reason'], properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } } }
const CTX = String.raw`PROJECT: Awwad Arabic-first habit app, D:\Claude\awwad\app. STRICTLY READ-ONLY, no flutter/dart commands (builds running). Report REAL user-facing defects only; empty findings is valid.`
phase('Hunt')
const rev = await agent(`${CTX}
LENS: Arabic quality + UX truthfulness. Files: app/lib/l10n/app_ar.arb vs app_en.arb/app_fr.arb (key parity - a key missing in one locale crashes via ! operator; MSA purity, no Egyptian colloquial like يلا/ازاي/عايز/مش), ALL inline _strings/_kStr maps across features (pomodoro, sos, settings, habits, add_habit, usage, shield, auth, daily_log, onboarding - ar/en/fr KEY PARITY within each map), core/catalog/habit_catalog.dart + habit_content.dart + motivation.dart (em-dash — anywhere user-facing is FORBIDDEN, religious accuracy red flags), and UX lies (UI text promising behaviour the code does not do). Check bidi hazards: Arabic strings that START with a Latin token.`,
  { label: 'hunt:arabic-ux', phase: 'Hunt', schema: FINDINGS })
const out = await parallel((rev?.findings ?? []).filter(f => f.severity !== 'minor').map(f => () =>
  agent(`${CTX}
ADVERSARIALLY VERIFY by reading the files; default isReal=false. CLAIM: ${f.file}:${f.line} [${f.severity}] ${f.problem} (fix: ${f.fix})`,
    { label: 'verify', phase: 'Verify', schema: VERDICT }).then(v => ({ ...f, verdict: v }))))
const all = (out || []).filter(Boolean)
return { confirmed: all.filter(f => f.verdict?.isReal), minors: (rev?.findings ?? []).filter(f => f.severity === 'minor') }
