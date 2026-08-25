# HANDOVER — continuing Awwad on a different Claude account or a different machine

> Written 2026-08-26, at the owner's request, because he may close the Claude account this
> project was built with. Everything an assistant needs is either in this repository or in the
> one local folder named at the bottom. Nothing that matters lives only inside a chat.
>
> **If you are a fresh assistant starting cold: read `docs/PROJECT_STATE.md` first (its §0 is the
> resume protocol), then this file.** PROJECT_STATE is the state of the PRODUCT; this file is
> the state of the ENVIRONMENT around it.

---

## 1. What survives an account switch, and what does not

| Lives in | Survives a new account? | Survives a new machine? |
|---|---|---|
| This git repository (pushed to GitHub) | yes | yes |
| `docs/ai/` (copied here 2026-08-26) | yes | yes |
| `_local/` folder next to this repo | yes | **only if you copy it by hand** |
| The chat/session history in the Claude app | no | no |
| The assistant's own memory files | no | no (they were copied into `docs/ai/` and `_local/`) |
| The `Awwad` skill, the scheduled tasks | no | no (copied into `docs/ai/`) |
| Windows credential store (GitHub token) | not applicable | no, sign in again |

Everything in the "no" rows was exported on 2026-08-26. That is what this file is for.

---

## 2. The five minutes that get a new assistant productive

1. `git clone https://github.com/moradarafa1/awwad.git` (private repo, the owner's GitHub
   account `moradarafa1` must be signed in).
2. Read `docs/PROJECT_STATE.md` §0 and §0.6 (the RESUME block). It is deliberately written for
   an AI resuming cold and it is kept current every single turn.
3. Read `docs/ai/ACCOUNT_RULES.md` and the `docs/ai/feedback-*.md` files. Those are the owner's
   standing working rules, learned over months. They are not optional preferences, they are how
   he wants the work done. The most load-bearing ones:
   - finish long jobs across usage windows, pause cleanly at about 90% of the limit;
   - Arabic is the working language, Modern Standard Arabic, never start an Arabic line with a
     Latin word, no em-dash;
   - deploy the site and the web app on every update without asking; ask before Netlify; build
     Android only at the end;
   - never ask about or change the bypass-permissions mode.
4. Read `docs/ai/memory-project_awwad.md`. It is the redacted copy of the assistant memory that
   drove this project, including hard rules and the toolchain paths.
5. Skim `docs/SESSIONS_LOG.md` to see which chat did what, in order.

---

## 3. This machine's toolchain (nothing is on PATH)

| Tool | Path |
|---|---|
| Flutter 3.44.4 / Dart 3.12.2 | `D:\flutter\bin\flutter.bat` |
| JDK 17 | `D:\jdk17\jdk-17.0.19+10` |
| Android SDK | `D:\Android\Sdk` (build-tools 36.0.0 used for `aapt`/`aapt2` checks) |
| Supabase CLI | `D:\supabase\supabase.exe` |
| Repo | `D:\Claude\awwad` |

Exact build commands, with the required `--dart-define` values, are in PROJECT_STATE §6. On a
NEW machine, install the same versions, then re-point these paths. Nothing else is
machine-specific.

---

## 4. Secrets: what exists, where it lives, what only the owner can restore

**No secret value is written in this repository, deliberately** (it is one of the project's hard
rules). The full values live in `_local/memory-project_awwad.FULL.md`. This is the inventory:

| Secret | Where the value is | If it is lost |
|---|---|---|
| Android upload keystore + its password | `_local/signing/` (keystore + `key.properties`) | **Unrecoverable.** The app could never be updated on Google Play again under the same listing. Back this up first, before anything else. |
| Supabase `service_role` key | Supabase dashboard, and `_local/…FULL.md` | Re-readable from the dashboard |
| Supabase Management PAT (`sbp_…`) | `_local/…FULL.md` | Should be REVOKED anyway at supabase.com/dashboard/account/tokens, it was only for a one-off task |
| Brevo SMTP key | Brevo dashboard, and `_local/…FULL.md` | Re-creatable in Brevo |
| Supabase anon key | `ops/build-app-cloud.ps1`, in the repo | Public by design, safe to ship |
| GitHub token | Windows credential store on this machine | Sign in again |

A new machine needs the owner to sign in again to: GitHub, Supabase, Netlify, Brevo, Google
Play Console. No assistant can do that part.

---

## 5. The local folder that must be carried by hand

```
D:\Claude\awwad\_local\
```

It is git-ignored on purpose and it holds the four things that cannot be committed:

- `memory-project_awwad.FULL.md` — the assistant memory WITH the secret values.
- `signing/` — the upload keystore and `key.properties`. The single irreplaceable item.
- `sessions/` — the raw archives of the Awwad chats (14 files, about 5 MB).
- `awwad-readiness-audit.FULL.js` — the audit workflow with its real password literal.

**To move to another machine: copy this folder, by USB or OneDrive, and put it back at the same
place inside the clone. Never commit it, never paste its contents into a chat.**

---

## 6. What was copied into `docs/ai/` on 2026-08-26

| File | What it is |
|---|---|
| `ACCOUNT_RULES.md` | The owner's account-wide working rules (was `~/.claude/CLAUDE.md`) |
| `feedback-*.md` (6 files) | Standing corrections and confirmed ways of working |
| `memory-project_awwad.md` | Project memory, redacted |
| `memory-project_awwad_hosting.md` | Why hosting is GitHub Pages and not Netlify (the owner's ISP blocks netlify.app) |
| `SKILL-Awwad.md` | The reusable playbook for building a project like this one |
| `scheduled-tasks/*.md` | Two recurring automations that were set up for Awwad |
| `workflows/*.js` | The 12 multi-agent review and audit scripts used on this project |

The scheduled tasks and the skill will NOT run on a new account by themselves. Re-create them
there from these files if they are still wanted.

---

## 7. Live surfaces, so nothing is lost by accident

- Site: https://moradarafa1.github.io/ and web app: https://moradarafa1.github.io/app/
  (deployed from the separate public repo `moradarafa1/moradarafa1.github.io`, which holds only
  built output).
- Netlify mirrors `awwad-habits` / `awwad-app` still exist as a global fallback.
- Supabase project ref `kdczbzzjezyhfxgpegqc`. It pauses when idle, and a GitHub Actions cron
  plus a heartbeat RPC keep it awake. If that cron stops running, the database pauses.

---

## 8. Honest gaps a new assistant should know about

- The Android app has never been verified on the owner's own phone for the newest work (the
  native adhan chain and the prayer widget). PROJECT_STATE §0.6 (b) lists exactly what to watch.
- iOS has never been built. All of it waits on a Mac plus a paid Apple account. The iOS code is
  written and waiting in `app/ios/`, with `docs/IOS_PARITY_SETUP.md` as the step-by-step guide.
- The store submission is prepared but not done. It waits on the owner's accounts.
