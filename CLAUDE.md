# Standing instruction — keep the handoff current, every turn

`docs/PROJECT_STATE.md` is this project's single source of truth (see its own
§0 for the full resume protocol). It must never fall behind reality.

**Rule: after any change to this project — code, config, a decision, a
blocker discovered, a build/deploy outcome — however small, update
`docs/PROJECT_STATE.md` in the SAME turn, before finishing your response.**

This is not deferred to "end of session" and not conditional on the owner
asking for a summary. Concretely, in the turn where you make a change:

- Update the relevant numbered section (§7 current state, §12 backlog, etc.).
- If it changes what the very next session should do, update §0.5 HANDOFF
  (the "RESUME HERE" block) so it reflects the current next steps, not stale
  ones.
- Add one line to §13 Changelog.
- Keep entries terse and information-dense (this file is optimized for an AI
  resuming cold, not prose) — match the existing style, no em-dash.

Do this even for small changes — a one-line fix still gets a one-line
changelog entry. The goal: any future session (new chat, new machine, after
context compaction) can resume from this file alone with zero loss, without
the owner ever having to ask "update the handoff" or say "/compact" first.

No hook enforces this (a Stop-event hook can't reliably tell "meaningful
change" from "just answered a question," and a PostToolUse agent-hook would
cost real API tokens on every single edit — contrary to this project's
zero-cost principle, see docs/PROJECT_STATE.md §2). This instruction is the
mechanism. Follow it every turn.
