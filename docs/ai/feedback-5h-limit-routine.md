---
name: feedback-5h-limit-routine
description: "Standing routine for the 5-hour usage limit - at ~90% stop, wait for reset, then resume; applies to every project and chat on this account"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cd302e1e-25bd-46a9-bb9b-2fa36b239aff
---

When working on a long task, keep going until every task, update and test is
finished. Do not stop early to check in.

If the 5-hour usage limit reaches about **90%** before the work is done: stop
working, tell the owner where things stand, and wait for the limit to reset.
When it resets, resume automatically and continue the same way. Repeat as many
cycles as the work needs.

**Why:** the owner would rather a long job be finished across several limit
windows than be left half-done, and he does not want to be asked each time.

**How to apply:** treat this as the default working rhythm for EVERY project
and EVERY chat on this account, not just the one it was said in. Before
starting a long stretch, note the current limit percentage; as it climbs past
~90%, wrap up cleanly (commit, update the handoff doc, state the exact next
step) rather than being cut off mid-edit. See [[project_awwad]] for a project
whose own rules already demand a handoff doc stay current every turn.

**Where it is enforced:** the owner asked for this at ACCOUNT level, so the
rule also lives in `C:\Users\morad\.claude\CLAUDE.md`, which loads in every
project and every session. That file is the authority; this memory is the
reasoning behind it. If one is edited, keep the other in step.

**Implemented as a scheduled task (2026-07-20, generalized 2026-07-20):**
`resume-unfinished-work-after-limit-reset` in the scheduled-tasks MCP. Started
Awwad-only, then generalized the same day to cover EVERY project folder under
D:\Claude, not one hardcoded project — the owner asked twice the same day to
widen this, so it now lists D:\Claude's subfolders live each run rather than
naming any project.
- Checks the account's 5-hour usage-limit % on a recurring cron. Default
  cadence/threshold: hourly / ~90%. When the executing model is Fable, it
  detects that from its own system context and switches itself to every 30
  minutes / ~80% (tighter, since Fable sessions burn budget faster).
- At threshold, it re-lists every folder directly under D:\Claude and checks
  each for ANY of four state/handoff conventions: `docs\PROJECT_STATE.md`
  (0.6 HANDOFF section, [[project_awwad]]'s pattern and the richest one),
  `STATUS.md`, `TASKS.md`, or `HANDOFF.md` at the project root — verifies/fixes
  whichever it finds, then reads the live "Resets in Xh Ym" countdown and calls
  `update_scheduled_task` on ITS OWN taskId to swap its cron for a one-time
  `fireAt` = now + countdown + 5 minutes. One reschedule covers every pending
  project at once. A project with none of those four files (e.g.
  [[project_between]] as of 2026-07-20 — a largely-finished static demo site;
  also bloomingn, kc-deploy, wabl-monitor, usage-meter as of that date) is
  simply skipped — it starts being tracked automatically the moment it gets
  any one of those files, no task edit required.
- When the one-time fire happens, it resumes each pending project in turn,
  using THAT project's own CLAUDE.md/build/verify conventions (Awwad's
  Flutter-specific commands are kept as Awwad-only, not applied elsewhere),
  then MUST restore its own recurring cron before ending (a run that skipped
  this once left the routine disabled and it silently vanished from the
  Routines list in the UI until the owner noticed — always end with the
  restore step).
- Never sends anything via a notification tool — see
  [[feedback-no-push-notifications]]; output is an in-chat message only, and
  `notifyOnCompletion` is set to `false` on the task itself.
