export const meta = {
  name: 'awwad-infinite-width-sweep',
  description: 'Find every button that inherits an infinite min-width inside an unbounded-width parent (Row/ListView horizontal), the same bug class as the pomodoro Reset button',
  phases: [
    { title: 'Sweep', detail: 'search all lib/ for buttons as non-flex Row children' },
    { title: 'Prove', detail: 'widget-test each candidate to see if it really throws' },
  ],
}

const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['file', 'line', 'widget', 'why'],
    properties: {
      file: { type: 'string' }, line: { type: 'number' },
      widget: { type: 'string' },
      why: { type: 'string' },
      fix: { type: 'string' },
    } } } },
}
const VERDICT = {
  type: 'object', required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' }, fix: { type: 'string' } },
}

const CONTEXT = `PROJECT: Awwad Flutter app at D:\\Claude\\awwad\\app (Arabic-default RTL, trilingual).
BUG CLASS (already confirmed once, in pomodoro_screen.dart:222): the app's THEME sets
  filledButtonTheme -> minimumSize: const Size.fromHeight(52)   (app/lib/app/theme.dart:170)
Size.fromHeight(52) == Size(double.infinity, 52), i.e. an INFINITE MINIMUM WIDTH.
A Row (or any unbounded-width parent: horizontal ListView/SingleChildScrollView, IntrinsicWidth,
UnconstrainedBox) hands NON-FLEX children UNBOUNDED max width. A button with an infinite min width
in an unbounded-width parent throws "BoxConstraints forces an infinite width" EVERY FRAME and the
subtree fails to lay out. It is SAFE only when the parent bounds the width (Expanded/Flexible,
SizedBox(width:), a Column with stretch, a bounded dialog/OverflowBar, etc.), because then the
infinite minWidth is clamped by the bounded maxWidth.
So: EVERY FilledButton/FilledButton.icon (inherits the theme minimumSize), and every button whose
LOCAL style sets minimumSize: Size.fromHeight(...), is a candidate wherever its parent does not
bound its width.`

phase('Sweep')
const AREAS = [
  'app/lib/features/home (home_shell, daily_log_screen, settings_screen, add_habit_screen, habits_screen, profile_screen, stats_screen, history_screen, habit_switcher, month_heatmap, journey_cards, analytics_section)',
  'app/lib/features/auth (auth_screen, auth_choice_screen) and app/lib/features/onboarding (onboarding_flow, language_screen)',
  'app/lib/features/sos, app/lib/features/shield, app/lib/features/phone, app/lib/features/pomodoro, app/lib/core/widgets (glass_button, common, reminder_times_picker), app/lib/features/fields',
]

const results = await pipeline(
  AREAS,
  (area, _item, i) => agent(
    `${CONTEXT}

YOUR TASK: read EVERY Dart file in: ${area}
Find every occurrence of the bug class above: a button (FilledButton, FilledButton.icon,
ElevatedButton, OutlinedButton, TextButton, or any widget whose style sets minimumSize with an
infinite width) that sits in a parent which does NOT bound its width.

Method (be rigorous, do not guess):
1. grep/read for FilledButton, ElevatedButton, OutlinedButton, minimumSize, Size.fromHeight.
2. For EACH hit, read the surrounding widget tree UPWARD until you find what bounds the width:
   Expanded/Flexible/SizedBox(width:)/Container(width:)/a Column with CrossAxisAlignment.stretch/
   a bounded dialog action bar => SAFE, do not report.
   A Row/horizontal scroll view/IntrinsicWidth/UnconstrainedBox with the button as a NON-FLEX child
   => REPORT IT.
3. Note that ONLY FilledButton inherits the infinite minimumSize from the theme; OutlinedButton and
   TextButton are only affected if their LOCAL style sets it (like pomodoro_screen.dart:222 did).
   Check theme.dart yourself to confirm which button themes carry minimumSize before reporting.

Report file, line, the widget, why it is unbounded (name the exact parent), and the concrete fix
(wrap in Expanded/Flexible, or set minimumSize: Size(64, 52)). Report ONLY real hits; an empty
findings list is a perfectly good answer.`,
    { label: `sweep:${i + 1}`, phase: 'Sweep', schema: FINDINGS }),
  (rev, area, i) => parallel((rev?.findings ?? []).map(f => () =>
    agent(
      `${CONTEXT}

VERIFY this claim ADVERSARIALLY. Default to isReal=false unless you can PROVE it.
CLAIM: ${f.widget} at ${f.file}:${f.line} - ${f.why} (proposed fix: ${f.fix ?? 'n/a'})

Proof procedure:
1. Read the file and walk the widget tree UPWARD from the button. If ANY ancestor bounds the width
   (Expanded, Flexible, SizedBox/Container with a width, Column with stretch, dialog OverflowBar,
   a Wrap, a bounded parent), the claim is FALSE - say so.
2. If it still looks real, PROVE IT EMPIRICALLY: write a temporary widget test under
   D:\\Claude\\awwad\\app\\test\\ (name it _tmp_probe_<something>_test.dart) that pumps the exact
   screen/widget inside a MaterialApp with the app theme (buildAwwadTheme from app/theme.dart),
   localizationsDelegates from AppLocalizations, and a ProviderScope with
   localStoreProvider.overrideWithValue(LocalStore(await SharedPreferences.getInstance())) after
   SharedPreferences.setMockInitialValues({}). Catch tester.takeException() and report whether it
   is "BoxConstraints forces an infinite width".
   Run it with: cd /d/Claude/awwad/app && /d/flutter/bin/flutter.bat test test/_tmp_probe_<name>_test.dart
   THEN DELETE the temporary test file (it must not remain in the repo).
3. Report isReal + the exact evidence (the thrown exception text, or the ancestor that makes it safe)
   + the minimal fix.`,
      { label: `prove`, phase: 'Prove', schema: VERDICT })
      .then(v => ({ ...f, verdict: v }))))
)

const all = results.flat().filter(Boolean)
const confirmed = all.filter(f => f.verdict?.isReal)
log(`sweep done: ${all.length} candidates, ${confirmed.length} confirmed`)
return { confirmed, rejected: all.filter(f => !f.verdict?.isReal).map(f => `${f.file}:${f.line} ${f.verdict?.reason?.slice(0, 160)}`) }
