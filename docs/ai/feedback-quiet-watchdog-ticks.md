---
name: quiet-watchdog-ticks
description: "On routine automated watchdog ticks (usage-limit checks, quiet no-op runs), don't ask for permission or narrate — just run silently and report only when there's real news."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fb97344a-1b5b-4ed4-99f8-1a26e831d8cc
---

Owner does not want to be asked/pinged for confirmation on routine automated checks (e.g. the `resume-unfinished-work-after-limit-reset` scheduled task's hourly usage check). Run these autonomously without checking in.

**Why:** Owner finds repeated "should I proceed?" style check-ins on a routine scheduled tick annoying, and wants token usage kept minimal on these quiet ticks.

**How to apply:** For scheduled/automated routine runs (usage-limit watchdog, quiet no-op ticks), just execute per the task's own rules and stay silent unless there's real, actionable output (per [[feedback-no-push-notifications]] the output goes in-chat only when there IS something to report). Don't ask "should I continue?" and don't over-explain a no-op tick — keep it to the minimum needed. This is already partially the scheduled task's own design (it says stay silent on a pure quiet tick); this memory reinforces: also avoid asking permission mid-run for the routine's own defined actions, and keep any reports terse to save tokens.
