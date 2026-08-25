---
name: feedback-bypass-permissions-and-limit-threshold
description: "Keep \"Bypass permissions\" mode as-is (never ask/change it); don't pause ongoing work until usage limit hits ~90%, matching the standard 5h-limit routine"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5dc31ead-3671-468e-be0b-1a6067e034b9
---

Two standing rules from the owner (2026-07-20):

1. The session runs in "Bypass permissions" mode (shown in the UI). Never ask to change this setting or suggest switching modes — leave it as is. As of 2026-07-20 this is pinned in `~/.claude/settings.json` as `permissions.defaultMode: "bypassPermissions"`, alongside `"model": "sonnet"`, because new sessions (especially scheduled-task runs) kept starting at Manual/Opus and the owner was re-setting them by hand every time.
2. Do not stop or pause active work just because the usage limit isn't at 0%. Keep working as long as the 5-hour usage limit (see [5-hour limit routine](feedback-5h-limit-routine.md)) is under 90% — only at/above ~90% do the agreed stop-cleanly-and-resume-after-reset routine (leave work resumable, wait for reset, continue).

**Why:** the owner wants continuous, uninterrupted execution without repeated permission prompts, and doesn't want work paused prematurely while there's still meaningful budget left. He confirmed 90% (not a lower, more cautious number) is the real threshold — matches the existing 5h-limit routine, no separate lower bar.

**How to apply:** never re-prompt about permission mode in this account's sessions. When deciding whether to keep going on a task, do NOT stop below 90% usage. At/above ~90%, follow [5-hour limit routine](feedback-5h-limit-routine.md) (stop cleanly, leave resumable state, wait for reset, resume). Project-specific routines with their own thresholds (e.g. Fable's 80% in the scheduled watchdog) still apply as written for their own pause/resume scheduling — this note just confirms not to add extra caution or stop earlier than agreed.
