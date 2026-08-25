# Sessions log — every Awwad chat, and what it produced

> Exported 2026-08-26 so the project survives closing the Claude account it was built with.
> The chats themselves are account-local and cannot be moved into another account. What is
> portable is (a) this index, (b) the raw archives copied to `_local/sessions/`, and (c) the
> changelog in `docs/PROJECT_STATE.md` §13, which is and always was the authoritative record of
> what actually changed. **If the two ever disagree, believe PROJECT_STATE: chats hold
> intentions, the changelog holds outcomes.**

---

## 1. Archived chats (raw copies in `_local/sessions/`)

Fourteen Awwad chats were still in the desktop app's local store on 2026-08-26 and were copied
out verbatim. A small file is a stub record (a chat that was resumed under another id); a large
one carries the full transcript with its tool output.

| Chat id | Title | Last active | Size |
|---|---|---|---|
| `local_f4b88da3…` | Awwad, New session | 2026-07-17 | 600K |
| `local_8e765ce5…` | بلا عنوان، استئناف من HANDOFF 0.6 | 2026-07-20 | 632K |
| `local_f71fe104…` | مشروع عوّاد، المرحلة 0.5 | 2026-07-20 | stub |
| `local_d788abc7…` | حسابات Google Play وApp Store | 2026-07-20 | 632K |
| `local_3f5c9d2b…` | مشاكل تطبيق عواد | 2026-07-20 | 632K |
| `local_cd302e1e…` | مشروع عوّاد، المرحلة 6 | 2026-07-20 | stub |
| `local_66c2d72e…` | مشروع عوّاد، المرحلة 6 | 2026-07-20 | stub |
| `local_907e8579…` | بلا عنوان | 2026-07-26 | 600K |
| `local_18e3162b…` | مشروع عوّاد، المرحلة 6 | 2026-07-30 | 588K |
| `local_ed9ba8e7…` | بلا عنوان | 2026-07-30 | 588K |
| `local_844d716d…` | مشروع عوّاد، المرحلة 6 | 2026-07-30 | stub |
| `local_9e12228e…` | مشروع عوّاد، إصلاح الأذان والإعدادات | 2026-07-30 | stub |
| `local_24ffbd36…` | بلا عنوان، اختبار التطبيق على هاتف أندرويد | 2026-08-01 | 600K |
| `local_a2f27fa8…` | عواد · ودجت الصلاة والتاريخ الهجري | 2026-08-26 | 592K |

Two caveats, stated plainly:

- **This is not the whole history.** The project started in June 2026 and much of the early work
  ran in chats whose working directory was `D:\Claude` rather than `D:\Claude\awwad`, with
  generic titles. Those were not all recoverable on 2026-08-26. Nothing is lost by it: every
  outcome they produced is in the changelog below and in the code.
- Several long-running chats were the **usage-limit watchdog** ("Resume unfinished work after
  limit reset"). They covered many projects at once, not Awwad alone, so they were not archived
  here. One of them made the last commit before this export.

---

## 2. What each phase actually delivered

Reconstructed from `docs/PROJECT_STATE.md` §13. Newest first. Read that section for the full
detail; this is the map.

**2026-08-22 to 08-23 — prayer widget.** The Android home-screen prayer card: next prayer, a
live Chronometer countdown, the Umm al-Qura Hijri date, today's five times. Then an adversarial
review round that fixed five real defects (pushed clock strings going stale across timezones, an
isha-to-midnight inconsistency, a lying empty state, a negative countdown, an exported broadcast
action). iOS twin written in-repo with lock-screen families, still Mac-gated.

**2026-07-31 to 08-01 — the adhan bug, fixed at the root.** The owner's phone showed the adhan
up to 30 minutes late. Cause: `SCHEDULE_EXACT_ALARM` is denied by default on Android 14+, so
scheduling silently degraded to inexact and Doze deferred it. Replaced with a native chain: an
exact alarm re-armed for 30 days, a foreground service that plays the owner's own mp3, any
hardware button stops it, and a lateness guard that refuses to sound a stale adhan. Verified end
to end on an emulator. Also: the adhan became a core Settings feature, an onboarding location
step, automatic five-time reminders, and a language-independence audit.

**2026-07-20 — phase 0.6.** Two font families by role, an icon system replacing emoji, guests
skipping the survey, «تم» and «أمهلني» notification actions verified on a device, per-habit
customization, and the policy research for app blocking on both platforms.

**2026-07-17 to 07-19 — the mandate rounds.** The prayer-times engine, the Quran audio wird, the
monthly report, the porn-break habit with the DNS shield, the tasbih counter, scholar-video
curation, store metadata and the submission blockers, site SEO to 139 pages.

**2026-07-18 — the habit widget** (streak plus one-tap logging), per-app open counts, adhan
sound, the hadith radio, iOS parity work.

**2026-07-11 to 07-14 — auth and identity.** OTP moved to signup and password reset, Brevo SMTP
brought live, the month calendar heatmap, the seedling logo, the tracking layer, and a
layout-overflow round that caught a real crash.

**2026-07-04 to 07-12 — deployment and power features.** Deployed, then moved off Netlify to
GitHub Pages because the owner's ISP blocks netlify.app at the TCP level. SOS «لحظة ضعف», the
DNS content shield, phone-usage monitoring with per-app limits.

**June to early July 2026 — the build.** The Flutter app, the Astro marketing site, the Supabase
backend with RLS, the 36-habit catalog, offline-first storage, and the trilingual content, all
on free tiers.

---

## 3. How to pick up the thread with no chat history at all

1. `docs/PROJECT_STATE.md` §0.6 — the RESUME block, kept current every turn.
2. `docs/PROJECT_STATE.md` §12 — what is left to build, already ordered by priority.
3. `docs/PROJECT_STATE.md` §10 — the gotchas. Read them before debugging anything; several cost
   a whole session to find the first time.
4. `docs/HANDOVER.md` — the environment, the toolchain paths, and the secrets inventory.
5. `git log` — every commit message on this project is written to be read later, not skimmed.
