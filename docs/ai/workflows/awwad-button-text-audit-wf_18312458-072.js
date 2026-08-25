export const meta = {
  name: 'awwad-button-text-audit',
  description: 'Audit every button/chip/nav label for text overflow or clipping across the app',
  phases: [{ title: 'Audit' }, { title: 'Verify' }],
}
const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['file', 'line', 'widget', 'problem', 'fix'],
    properties: {
      file: { type: 'string' }, line: { type: 'number' },
      widget: { type: 'string' },
      problem: { type: 'string' },
      fix: { type: 'string' },
      severity: { enum: ['major', 'minor'] },
    } } } },
}
const VERDICT = {
  type: 'object', required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } },
}
phase('Audit')
const DIRS = [
  'D:\\Claude\\awwad\\app\\lib\\features\\auth and D:\\Claude\\awwad\\app\\lib\\features\\onboarding',
  'D:\\Claude\\awwad\\app\\lib\\features\\home (daily_log, settings, add_habit, habits, profile, stats, month_heatmap, journey_cards, home_shell)',
  'D:\\Claude\\awwad\\app\\lib\\features (sos, shield, phone, pomodoro) and core/widgets (glass_button, common, reminder_times_picker)',
]
const results = await pipeline(
  DIRS,
  d => agent(`Audit the Flutter Dart files in ${d} for BUTTON/CHIP/NAV TEXT that could OVERFLOW, CLIP, or truncate - especially Arabic (longer than English) inside fixed-width or Row-constrained containers. Look concretely for: Text inside FilledButton/OutlinedButton/TextButton/ElevatedButton/Chip/ActionChip/NavigationDestination labels or custom pill Containers where the label is long Arabic and the button has a fixed width, is inside a Row with Expanded siblings that could squeeze it, uses a single line without softWrap/ellipsis where wrapping is needed, or a fixed height Container with text that could exceed it. Also flag NavigationBar labels that are long (e.g. multi-word Arabic) at fontSize 11 which may clip. Awwad is RTL Arabic-default. For each real risk report: file, line, the widget, the problem, and a concrete fix (e.g. wrap in Flexible/FittedBox, add maxLines+overflow, shorten label, allow 2 lines, reduce font). Read the files; only report REAL risks with specific Arabic strings, not hypotheticals.`, {label: `audit`, phase: 'Audit', schema: FINDINGS}),
  (rev, d) => parallel((rev?.findings ?? []).filter(f => f.severity === 'major').map(f => () =>
    agent(`Verify by reading the file: is this button-text overflow risk REAL and worth fixing? Default isReal=false for hypotheticals. Claim: ${f.widget} at ${f.file}:${f.line} - ${f.problem} FIX: ${f.fix}`, {label: `verify`, phase: 'Verify', schema: VERDICT})
      .then(v => ({...f, verdict: v}))))
)
const confirmed = results.flat().filter(Boolean).filter(f => f.verdict?.isReal)
const minors = results.flat().filter(Boolean).filter(f => f.severity === 'minor')
return { confirmed, minorCount: minors.length, minors: minors.map(m => `${m.file.split('\\\\').pop()}:${m.line} ${m.widget}`) }