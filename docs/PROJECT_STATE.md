# Awwad — Canonical Project State & Handoff

> Single source of truth for the Awwad project. Read this first when resuming work
> (human or AI). It is written to survive context loss: every section is
> self-contained so you can jump to and edit one part without re-reading the rest.
>
> Last updated: 2026-06-28. When you change the project, update the relevant
> section AND add a line to the [Changelog](#13-changelog).

---

## 0. FOR THE NEXT CLAUDE CODE SESSION — START HERE

You are resuming the **Awwad** project. Do this, in order, to continue without burning
context or dropping anything:

1. **Read this file fully** (it is the handoff). Then skim `README.md` for build commands.
   Do NOT re-read the whole codebase; this file + targeted reads are enough.
2. **Greet the owner and ask for the new tasks.** Don't start changing things until asked.
3. **Methodology to follow** (this is how the project has been built and must continue):
   - Offline-first, zero-cost, trilingual MSA, no em-dash, Islamic-values aligned (see §2, §11).
   - For substantive work, use the **Workflow** tool (multi-agent) to research/design and to
     **adversarially review** before shipping. Research-heavy content (new habits, per-habit
     copy, scholar videos, the authentic Sahih-Muslim dhikr) was produced and **verified** this
     way. Generate large data files (e.g. `habit_content.dart`) programmatically, never by hand.
   - After every change: `flutter analyze lib` (No issues) + `flutter test` (all pass) +
     `flutter build web`; for the site `npm run build` + confirm 0 em-dashes in `web/dist`.
     Keep changes mirrored in **app + Astro site + seed.sql + the live Supabase catalog** when
     they touch habits/content. Update this file's §7/§12 and add a Changelog line.
   - The CanvasKit web preview cannot screenshot the Flutter canvas (gotcha #4) — verify via
     analyze/tests/build and reasoning, not screenshots.

4. **Two priority tasks the owner has queued** (do when asked):
   - **A. Deep "appropriateness" review of the whole app, like an expert human** who knows
     Arabs/Muslims AND is a programmer. Open the (web) app, exercise EVERY habit and screen,
     and make each habit's daily-log content **fit that specific habit** and be consistent with
     the others: the two metric sliders (`metricsForHabit` in `habit_catalog.dart`), the
     "did you slip / did you do it?" question, the HRT checklists (`habit_content.dart`),
     reminder defaults, and the suggested-video query. Several are still generic. Fix/improve
     anything illogical or mismatched. Run a Workflow to design per-habit content, then verify.
   - **B. Phone-usage control for the `phone_addiction` habit** — see §12 item "Phone control".

---

## Table of contents
1. [Snapshot](#1-snapshot)
2. [Hard constraints & conventions](#2-hard-constraints--conventions)
3. [Repo layout](#3-repo-layout)
4. [Tech stack & free-tier limits](#4-tech-stack--free-tier-limits)
5. [Accounts & secrets](#5-accounts--secrets)
6. [Build & run (exact commands)](#6-build--run-exact-commands)
7. [Current state by surface](#7-current-state-by-surface)
8. [Backend: database & security model](#8-backend-database--security-model)
9. [Edge functions](#9-edge-functions)
10. [Hard-won gotchas (read before debugging)](#10-hard-won-gotchas-read-before-debugging)
11. [Brand & content rules](#11-brand--content-rules)
12. [Pending work / TODO](#12-pending-work--todo)
13. [Changelog](#13-changelog)

---

## 1. Snapshot

**Awwad (عوّاد)** is a trilingual (Arabic-default RTL / English / French) habit-change
platform: a user either **breaks a bad habit** or **builds a new one**, guided by the
evidence-based **Habit Reversal Training (HRT)** method, with a supportive,
Islamic-values-aligned tone. Non-profit; runs entirely on free tiers (only paid item = domain).

- **Product** = the Flutter app (Android / iOS / Web).
- **Marketing site** = an Astro static site (SEO + 30-article blog + legal pages).
- **Backend** = Supabase (Postgres + Auth + RLS + Edge Functions), **LIVE and verified**.
- Brand slogan: **«رفيقٌ مَن زانَ عُمرَه، وحُسُنُ عملَه»**

**Status (2026-07-04): DEPLOYED.** Marketing site LIVE at **https://awwad-habits.netlify.app**
(112 pages incl. branded 404, og-image + favicons + theme-color, canonical/hreflang/sitemap on
the live URL) and the Flutter web app LIVE at **https://awwad-app.netlify.app** (cloud build,
SPA redirects, PWA manifest ar/rtl). Both on the owner's free Netlify team (`morad-vxjyb3y`).
Android is **store-ready**: signed release **AAB (56.3MB)** + **APK (58.4MB)** built with a real
upload keystore (`app/android/app/upload-keystore.jks` + gitignored `key.properties`). iOS
configured (bundle `com.awwad.awwad`, display name «عوّاد», encryption-exempt flag, ar/en/fr) -
needs a Mac to build/submit. Trilingual **ASO store listings** + Arabic **submission guide** +
Play graphics live in `docs/store/` + `assets/store/`. Site download CTAs route to the web app
until `androidLive`/`iosLive` are flipped in `site.js`. Mature multi-habit app (36-habit catalog,
per-habit HRT checklists/metrics/reminders, dhikr + badges notifications, Pomodoro, glass UI).
Backend LIVE. Verified: analyze clean, 8 tests, all builds OK. **Not yet store-submitted**
(owner action; see docs/store/SUBMISSION_GUIDE.md).

---

## 2. Hard constraints & conventions

These are non-negotiable. Violating them is a regression.

1. **Zero operational cost.** Free tiers only. The ONLY paid item is the domain. Never
   introduce a paid dependency. Never create a 2nd Supabase project (free org cap = 2).
2. **Trilingual, no hard-coded strings.** Arabic (default, RTL), English, French. App uses
   gen-l10n `.arb`; site uses `web/src/content/site.js`.
3. **Arabic = Modern Standard Arabic (فصحى).** No Egyptian colloquial anywhere user-facing.
4. **No em-dash (—) anywhere user-facing.** Use a regular hyphen `-`, colon, or comma.
   Audit: `grep -rl "—" web/dist` must return nothing.
5. **Islamic-values-aligned content.** Halal/haram rulings are sourced from islamweb.net
   with a standing disclaimer; we never issue our own fatwa. See
   [`docs/content-values-guideline.md`](content-values-guideline.md).
6. **Footer credit** «© Morad Arafa» links to https://www.linkedin.com/in/moradarafa/.
7. **Offline-first app.** Cloud auth/sync must never block startup.
8. **Security:** the Supabase `service_role` key NEVER appears in the repo or client. Only
   the public `anon` key is shipped to clients.

---

## 3. Repo layout

```
awwad/
  app/        Flutter app (Web + iOS + Android) — the actual product
  web/        Astro marketing site (ar/en/fr) — SEO, 30-article blog, legal pages
  admin/      Static admin dashboard (reads Supabase admin RPCs)
  supabase/   migrations/ (SQL + RLS), functions/ (Edge), seed.sql, config.toml
  ops/        keep-alive.yml (GitHub Action), build-app-cloud.ps1, icongen/
  assets/     icons / splash / store screenshots
  docs/       PROJECT_STATE.md (this file), content-values-guideline.md, tracking-plan.md
```

Key app files:
- `app/lib/main.dart` — entry; offline-first; cloud init is timeout-guarded.
- `app/lib/l10n/app_{ar,en,fr}.arb` — translations (ar is MSA). `l10n.yaml` configures gen-l10n.
- `app/lib/features/onboarding/onboarding_flow.dart` — welcome (shows slogan, line ~164), language pick, survey, track, habit pick.
- `app/lib/features/home/home_shell.dart` — 6-tab nav: Today, Stats, Badges, History, **Pomodoro**, Settings.
- `app/lib/features/home/habit_switcher.dart` — chips to switch active habit + "+" (multi-habit).
- `app/lib/features/home/add_habit_screen.dart` — add-habit flow (cap, 90-day advisory, dedup picker).
- `app/lib/core/state/app_state.dart` — `habits` list + active-habit-scoped stats/entries/badges.
- `app/lib/features/pomodoro/pomodoro_screen.dart` — Pomodoro timer (inline trilingual strings).
- `app/lib/features/auth/auth_screen.dart` — cloud account screen; sign-up collects gender + optional fields.
- `app/lib/core/cloud/{supabase_service,sync_service}.dart` — cloud gateway + sync.
- `app/lib/core/catalog/habit_catalog.dart` — offline habit catalog (source of truth for onboarding).
- `app/lib/app/theme.dart` — `AppColors` + dark theme.

Key site files:
- `web/src/content/site.js` — ALL site copy (trilingual). Edit here for site text.
- `web/src/content/posts.js` — the 30 blog articles (trilingual). Generated; see gotchas.
- `web/src/layouts/Base.astro` — global layout + design system (CSS).
- `web/src/pages/[...path].astro` — generates every page (home, marketing, legal, blog).

---

## 4. Tech stack & free-tier limits

| Layer | Service | Free limit | Current use |
|---|---|---|---|
| Backend/Auth/DB | **Supabase** | 500MB DB, 50k MAU, 500k edge calls/mo, **pauses after 7d idle** | <50MB, ~0 users |
| Email (OTP/retention) | **Brevo SMTP** | 300/day | not wired yet |
| Site/admin hosting | **Cloudflare Pages** (or Netlify) | unlimited bandwidth, 500 builds/mo | not deployed yet |
| Push | **Firebase FCM** | unlimited | not wired yet |
| keep-alive + CI | **GitHub Actions** | 2000 min/mo (private) | ~10 min/mo |

Paid (owner only, when shipping): domain (~$12/yr), Apple Developer ($99/yr), Google Play ($25 once).

**Keep-alive:** Supabase free pauses after 7 idle days. `ops/keep-alive.yml` /
`.github/workflows/keep-alive.yml` pings every 3 days but needs repo secrets
`SUPABASE_URL` + `SUPABASE_ANON_KEY` (Settings → Secrets → Actions) or it fails silently.

---

## 5. Accounts & secrets

> The actual `service_role` key and full credentials live ONLY in the local AI memory
> (`~/.claude/.../memory/project_awwad.md`), NEVER in this repo. This section lists
> public-safe values + where the secrets live.

- **GitHub:** https://github.com/moradarafa1/awwad.git (private). **Fully pushed & in sync as of 2026-07-11:** local `main` == `origin/main` at `042379d` (release networking fixes: signup edge fn, localized errors, Gradle heap). Working tree clean, no stash, no other branches.
- **Supabase project ref:** `kdczbzzjezyhfxgpegqc` (region ap-southeast-1, Singapore). Postgres 17.
- **Supabase URL:** `https://kdczbzzjezyhfxgpegqc.supabase.co`
- **anon key (public, safe to ship):** in `ops/build-app-cloud.ps1` and used via `--dart-define`. Publishable.
- **service_role key:** SECRET. Lives only in: Supabase dashboard, edge-function runtime env (`SUPABASE_SERVICE_ROLE_KEY`), and the local AI memory. Never commit it.
- **Owner email:** olenshop.sa@gmail.com
- **Netlify** (account moradarafa.business@gmail.com, team `morad-vxjyb3y`, CLI logged in on this
  machine): site **awwad-habits** (`0b65cc50-79b2-4d4d-a522-a85bab6bf260`, marketing site, deploy
  `web/dist`) and **awwad-app** (`ffa150f7-1c5d-4a57-871e-58117d7a2eae`, Flutter web app, deploy
  `app/build/web`). Deploy: `npx netlify-cli deploy --prod --dir <dir> --site <id>`.
  NOTE: `*.netlify.app` edge was unreachable from the owner's network on 2026-07-04 (TCP 443
  timeout to ALL netlify.app sites incl. old ones) while `api.netlify.com` worked; deploys are
  verified `state=ready` via API. If the sites don't open locally, test via phone data/VPN - it
  is a local ISP/network issue, not the deploy.
- **Android signing:** upload keystore `app/android/app/upload-keystore.jks` (alias `upload`),
  passwords in gitignored `app/android/key.properties` (also in the local AI memory). BACK IT UP.
- **Supabase MCP** is connected in the AI session (server id `ef4e3dc4-...`): `apply_migration`, `execute_sql`, `deploy_edge_function`, `get_advisors` work directly. Supabase CLI fallback at `D:\supabase\supabase.exe`.
- **Toolchains (this machine):** Flutter `D:\flutter\bin\flutter.bat` (3.44.4 / Dart 3.12.2, NOT on PATH); JDK 17 `D:\jdk17\jdk-17.0.19+10`; Android SDK `D:\Android\Sdk`; Node available; no emulator/device connected.

---

## 6. Build & run (exact commands)

**Flutter is not on PATH — always use `D:\flutter\bin\flutter.bat`.**

### App (web, offline mode)
```bash
cd /d/Claude/awwad/app
/d/flutter/bin/flutter.bat run -d chrome
```

### App (web, CLOUD mode — auth/sync enabled)
```bash
cd /d/Claude/awwad/app
/d/flutter/bin/flutter.bat build web \
  --dart-define=SUPABASE_URL=https://kdczbzzjezyhfxgpegqc.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key from ops/build-app-cloud.ps1>
# or: ops/build-app-cloud.ps1  (has the keys wired)
```

### App (Android debug APK)
```bash
export JAVA_HOME='D:\jdk17\jdk-17.0.19+10'
export ANDROID_HOME='D:\Android\Sdk'
cd /d/Claude/awwad/app
/d/flutter/bin/flutter.bat build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# output: app/build/app/outputs/flutter-apk/app-debug.apk (~160MB debug)
```

### App (Android RELEASE — APK + store AAB)
```bash
# Same env as debug. The --dart-define keys are REQUIRED on release too,
# otherwise the app ships in offline-only mode (no auth/sync).
/d/flutter/bin/flutter.bat build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/d/flutter/bin/flutter.bat build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# outputs: flutter-apk/app-release.apk (~59MB) · bundle/release/app-release.aab
# After ANY release build, verify INTERNET permission is in the packaged APK:
#   'D:\Android\Sdk\build-tools\36.0.0\aapt.exe' dump permissions app/build/app/outputs/flutter-apk/app-release.apk | grep INTERNET
```

### Verify app
```bash
cd /d/Claude/awwad/app
/d/flutter/bin/flutter.bat analyze lib      # must be: No issues found
/d/flutter/bin/flutter.bat test             # 5 tests pass
/d/flutter/bin/flutter.bat gen-l10n         # after editing .arb files
```

### Site & admin
```bash
cd /d/Claude/awwad/web && npm install && npm run build   # -> web/dist (111 pages)
# local preview servers (.claude/launch.json): awwad-site :8088, awwad-web(app) :8099, awwad-admin :8077
```

### Backend (via Supabase MCP — preferred) or CLI
- Migrations: apply each `supabase/migrations/000N_*.sql` with `apply_migration`.
- Seed (data, not DDL): run `supabase/seed.sql` with `execute_sql`.
- After DDL always run `get_advisors(type:security)`.
- Edge functions: `deploy_edge_function` (deploy as self-contained single files; the repo
  versions import `../_shared/utils.ts`, which the CLI bundles but the MCP does not).

---

## 7. Current state by surface

### Flutter app — multi-habit, mature
- **First open:** `AuthChoiceScreen` (sign in / continue as guest = offline on device); also
  requests OS notification permission directly (no extra dialog). Gated by `settings.authChoiceMade`.
- **Onboarding:** welcome+language → optional survey → track → habit pick (36-habit catalog +
  custom, hides already-owned) → setup (name/why + **multi-time `ReminderTimesPicker`**).
- **Multi-habit:** `AppState.habits` list (cap 3 break + 3 build, `kMaxHabitsPerTrack`),
  `HabitSwitcher` chips on Today/Stats/History/Badges, Settings→**العادات** add/delete (can't
  delete the last), per-habit reminder times editable (alarm icon → reschedule). All stats/
  entries/badges scoped to the **active** habit.
- **Daily log:** habit-aware (`metricsForHabit`) two sliders (break=urge/resistance,
  build=progress/quality, prayer=delay+sunnah, water=cups+spread), **track-aware** slip/done
  question, mood (localized), note, and **per-habit HRT checklists** from generated
  `habit_content.dart` (fallback to generic seeded fields). **Suggested-solutions card** =
  secret-habit واعي channel OR a scholar-video YouTube **search** (4 scholars), **hidden when
  offline** (`onlineProvider`, connectivity_plus).
- **Profile** (badges/top shield + email + change-password + sign-out), Stats charts, Badges
  grid, History, Pomodoro (tap dial to start/pause), Fields Manager, Settings.
- **Notifications (local, mobile only; web no-op):** per-habit per-time reminders (ids 3000+),
  daily Ibrahimic-prayer **dhikr** (verified Sahih Muslim 405, `core/content/dhikr.dart`),
  badge-earned congrats, one-off 3-day sign-up re-engage. Toggles in Settings.
- **Registration:** name/email/password, gender MANDATORY, optional country/birth_date/WhatsApp
  (Arabic/Persian digits normalized) + research-only notice. Writes to Supabase profiles.
- **UI:** dark theme, **iOS "liquid glass" translucent buttons** (`theme.dart`). Verified:
  analyze clean, 8 tests, web build OK.

### Website (Astro) — redesigned + MSA + blog
- Distinctive design (Reem Kufi headings, single teal accent #2dd4bf, ambient gradient, hover-lift cards, transform-only reveal). 111 pages. 0 em-dashes site-wide.
- Pages: home, break-habit, build-habit, privacy, terms, delete-account, blog index + **30 blog articles × 3 langs** (each with Article + FAQPage JSON-LD). hreflang/OG/canonical/sitemap/robots.
- "Volunteer effort" notice in footer. Verified: 101/101 routes return 200.

### Admin dashboard (`admin/`)
- Static page, noindex, signs in and reads admin RPCs. `admin/config.js` is gitignored
  (holds anon key); `admin/config.example.js` is the committed template.

### Backend — LIVE & E2E tested
- See sections 8 and 9. Database deployed (migrations 0001-0006 + seed), all 5 edge
  functions ACTIVE, signup pipeline + RLS verified against live cloud.

---

## 8. Backend: database & security model

**Deployed migrations (in `supabase/migrations/`):**
- `0001_extensions_and_helpers` — pgcrypto, `set_updated_at()`, `admin_users`, `is_admin()`.
- `0002_core_tables` — profiles, subscriptions, habit_catalog, habits, onboarding_survey, custom_field_defs/options, daily_entries, entry_events, entry_selections. RLS on all.
- `0003_gamification_and_devices` — badge_definitions, earned_badges (+ column-lock trigger), `award_badge()`, trusted_devices, `handle_new_user()` + `on_auth_user_created` trigger.
- `0004_analytics_and_admin` — analytics_events + 7 admin RPCs (all gated by `is_admin()`).
- `0005_security_hardening` — see gotcha #2 below. Revokes anon EXECUTE from all functions.
- `0006_registration_fields` — adds gender/country/birth_date/whatsapp to profiles; `handle_new_user` provisions them from signup metadata.

**Verified live:** 15 public tables, **36 habit_catalog rows** (18 break + 18 build, incl.
`secret_habit` + the 6 new ones; `gratitude`→«الحمد والدعاء», `voluntary_fasting`→«صيام النوافل»),
10 badges, RLS enforced (anon reads habit_catalog only, never profiles), signup auto-creates
profile + free subscription, cascade delete works. NOTE: the per-habit checklists, metrics,
reminder defaults, multi-habit, and notifications live **only in the app** (local catalog +
`habit_content.dart`); the DB `habit_catalog` is reference data kept in sync for title/desc/icon.

**Security model:** Row-based admin (a user in `admin_users` table), gated by `is_admin()`
inside SECURITY DEFINER RPCs. Clients cannot self-grant badges (`award_badge` is
service_role-only). To make someone admin:
```sql
insert into public.admin_users(user_id) select id from auth.users where email='OWNER_EMAIL';
```

---

## 9. Edge functions

All 5 deployed and ACTIVE (`supabase/functions/`):
- `login-guard` (verify_jwt=false; manual token+device-secret auth) — returns 401 without valid token.
- `register-trusted-device` (verify_jwt=true).
- `award-badges` (verify_jwt=true; calls `award_badge` RPC with service_role).
- `account-export-delete` (verify_jwt=false; supports logged-out email-OTP delete path).
- `send-engagement` (verify_jwt=false; cron; P1 no-op until FCM/device_tokens land in P4).
- `signup` (verify_jwt=true, deployed 2026-07-07): creates accounts CONFIRMED via
  admin.createUser so registration never depends on confirmation emails (no custom SMTP;
  built-in mailer ~2/hour). The app's `SupabaseService.signUp` invokes it then signs in with
  password. Returns GoTrue-style error codes. Retire when Brevo SMTP lands (revert to plain
  `auth.signUp`).

`service_role` is auto-injected into the edge runtime as `SUPABASE_SERVICE_ROLE_KEY`.

---

## 10. Hard-won gotchas (read before debugging)

1. **Web cloud build / passkeys (CRITICAL).** supabase_flutter pulls Corbado passkeys; on
   WEB, `Supabase.initialize` throws "Null check operator used on a null value" and the app
   never renders UNLESS `app/web/passkeys_bundle.js` (v2.4.0) is present and referenced by a
   `<script>` in `app/web/index.html`. Both exist - keep them. Use `anonKey` (not
   `publishableKey`) for the legacy JWT key. main() is offline-first + timeout-guarded.
2. **Supabase default privileges (SECURITY).** Supabase auto-grants EXECUTE on every new
   function to `anon` + `authenticated`. This SURVIVES `revoke ... from public`. So per-function
   `revoke from public` in a migration is INEFFECTIVE against anon. You must explicitly
   `revoke ... from anon` (done in 0005). Always run `get_advisors(security)` after DDL.
3. **Gradle / Android.** `app/android/gradle.properties` has two required fixes:
   `kotlin.jvm.target.validation.mode=warning` (flutter_timezone compiles Java 11 vs Kotlin 1.8)
   and `kotlin.incremental=false` (Windows .tab cache-close failures on rebuild). If an APK
   build fails on `:device_info_plus:compileDebugKotlin` cache, delete `app/build/<plugin>` dirs.
   Feeding sdkmanager `--licenses` needs bash `< yes.txt` stdin redirect (PowerShell piping does NOT reach its stdin).
4. **CanvasKit preview limit (NOT a bug).** The Claude desktop Electron preview has webgl1=false
   and CANNOT screenshot the Flutter CanvasKit canvas (`preview_screenshot` times out), and a
   reused/wedged preview instance may fail to mount the glass-pane. A FRESH preview instance
   mounts fine. Verify the app via `flutter analyze`/tests/build + glass-pane check on a fresh
   instance; it renders correctly in a real browser. HTML pages (the Astro site) can also wedge
   the screenshot if they use heavy GPU effects (feTurbulence grain, backdrop-filter) - avoided.
5. **Reveal animations must fail-open.** Never gate content visibility on opacity-0 + JS/IO
   reveal: if the compositor stalls, content stays invisible. Use transform-only reveal
   (content always opacity 1). The site uses a CSS-only transform reveal.
6. **Blog generation.** `web/src/content/posts.js` (30 articles) was generated by a workflow
   and assembled by `scratchpad/assemble_posts.js` (adds dates, strips em-dashes). To add/edit
   articles, edit posts.js directly; `[...path].astro` renders them automatically.
7. **Release APK needs INTERNET permission explicitly (CRITICAL, hit 2026-07-06).** Flutter
   injects `android.permission.INTERNET` into DEBUG builds only (via `src/debug/AndroidManifest.xml`).
   The RELEASE manifest comes from `src/main/AndroidManifest.xml` alone — without the permission
   there, every network call in a release APK/AAB dies with
   `SocketException: Failed host lookup ... errno = 7` (looks like a DNS problem; it is not).
   Fixed by adding the permission to the main manifest. After any release build, verify with
   `aapt dump permissions app-release.apk | grep INTERNET`.
8. **Gradle daemon OOM on this machine (16GB RAM).** `org.gradle.jvmargs` was `-Xmx8G` +
   `-XX:MaxMetaspaceSize=4G`; with a long-lived daemon this exhausted native memory and the
   daemon crashed mid-build ("Gradle build daemon disappeared unexpectedly", hs_err
   `arena.cpp:191` malloc failure). Now `-Xmx2048m -XX:MaxMetaspaceSize=512m` + 30-min daemon
   idle timeout in `app/android/gradle.properties`. A release build fits comfortably in 2GB.
9. **Never show raw exceptions to users.** Auth/sync/password errors are mapped to localized
   ar/en/fr messages (`_friendlyError` in `auth_screen.dart`; similar mapping in
   `profile_screen.dart` change-password and `settings_screen.dart` sync). Keep this pattern
   for any new network-touching UI.

---

## 11. Brand & content rules

- **Name:** عوّاد / Awwad. **Slogan:** «رفيقٌ مَن زانَ عُمرَه، وحُسُنُ عملَه» (note the
  tashkeel on حُسُنُ: ح, س, ن all carry damma). Set in `app_ar.arb` `slogan` + `site.js` ar `slogan`.
- **Colors:** dark theme. App accents: blue `#4f8ef7`, teal `#2dd4bf`, amber `#f59e0b`.
  Website redesign uses a SINGLE teal accent `#2dd4bf` + Reem Kufi display headings.
- **Tone:** supportive, MSA, Islamic-values-aligned, never preachy; rulings cite islamweb.net.
- **Two tracks:** break a habit / build a habit, both via HRT (awareness → competing response
  → environment control → maintenance).

---

## 12. Pending work / TODO

> Top two are the owner's queued priorities (see §0).

0a. **Deep per-habit appropriateness review (expert pass).** Make every habit's daily-log
   content fit it and be consistent with the others. Resolve via `metricsForHabit` +
   `kHabitChecklists`/`kHabitVideoQuery` (`habit_content.dart`) + `defaultReminderHours` +
   the track-aware slip/done question. Examples already done: water (cups/spread, 5 reminders),
   prayer (delay/sunnah), adhkar (Fajr+Isha). Many build habits still use the GENERIC
   progress/quality metrics and no checklists — design per-habit content via a Workflow, verify
   adversarially, then sync app + seed + live DB.

0b. **Phone-usage control for `phone_addiction` (owner-requested).** Goal: Awwad lets the user
   pick apps and limits/monitors time on them. **Feasibility & plan:**
   - **Android (doable):** read per-app usage via `UsageStatsManager` (needs the special
     `PACKAGE_USAGE_STATS` permission → send the user to Settings to grant; cannot be auto-
     granted). A Flutter package like `app_usage` / `usage_stats` or a platform channel exposes
     it. Show usage + fire a local notification / warning when over a user-set daily limit.
     Real *blocking* of apps needs an `AccessibilityService` or overlay (fragile, risks Play
     rejection) — treat as a later/optional phase; start with monitoring + alerts.
   - **iOS (hard):** the Screen Time / `FamilyControls` API requires a special Apple
     entitlement that is non-trivial to obtain; defer until there's a Mac + Apple account.
   - **Web:** impossible (no usage APIs) — feature must be Android/iOS-gated and a no-op on web,
     mirroring the `notifications` conditional-import pattern.
   - **Build it in a dedicated mobile session** (needs an APK + a real device to test); it
     cannot be verified in the web preview. Add UI under the `phone_addiction` habit's daily
     log / a new tab. NOT started.

1. **Language tap on onboarding does nothing** (reported 2026-06-27) - investigate
   `onboarding_flow.dart` language selection handler. (Open bug; may already be moot.)
2. **Google Sheets sink for registration** (needs user). User deploys the provided Apps Script
   (creates Males/Females sheets; columns: name, WhatsApp, email, country, date) and sends the
   Web App URL. Wire it best as a Supabase edge function `register-sheet` (keeps URL server-side)
   invoked after signUp, OR a `--dart-define SHEETS_WEBHOOK_URL` POST. Data ALREADY persists to
   Supabase profiles; Sheets is an extra sink.
3. ~~Add GitHub repo secrets so keep-alive runs.~~ DONE (2026-06-28): keep-alive.yml now
   embeds the public URL + anon key as defaults (no secrets needed); pushed (commit `0abb313`)
   and a manual run passed green. Secrets still override if ever set.
4. ~~Brevo SMTP~~ **DONE (2026-07-11 round 4): Brevo SMTP live.** Account moradarafa.business@
   gmail.com (company "Awwad", free 300/day), SMTP login `b1b09a001@smtp-brevo.com`, host
   smtp-relay.brevo.com:587 (key in local AI memory). Supabase auth config now: custom SMTP +
   sender «عوّاد | Awwad» + Arabic {{ .Token }} magic-link template + rate_limit_email_sent=30/h.
   GOTCHA solved: Brevo's "Blocking unauthorized IP addresses" was ACTIVE by default on the new
   account (Security -> Authorized IPs) and made every Supabase send fail with
   `525 5.7.1 Unauthorized IP address`; owner deactivated it for API+SMTP keys -> /otp returns
   200, email delivered. `kOtpLoginEnabled=true` again. REMAINING (owner): revoke the Supabase
   PAT at supabase.com/dashboard/account/tokens.
5. ~~**Push latest commits to GitHub.**~~ DONE (verified 2026-07-11): local `main` == `origin/main`
   at `042379d`; `git fetch` shows 0 ahead/behind, working tree clean, no stash, no other
   branches. All prior work is already on GitHub.
6. ~~Deploy the Flutter web-app + Astro site.~~ DONE (2026-07-04): live at
   https://awwad-app.netlify.app and https://awwad-habits.netlify.app (see §5). Remaining:
   buy the domain, then update `astro.config.mjs` site, `robots.txt`, `WEB_APP_URL` + Netlify
   custom domains.
7. **P4:** Firebase FCM push + Brevo email sequence.
7b. ~~EMAIL CONFIRMATION DECISION~~ **RESOLVED 2026-07-07 without owner action:** signup now
   goes through the `signup` edge function (§9), which creates accounts already confirmed -
   zero emails sent, no rate limit, works for every user immediately. Email confirmation can
   stay ON in the dashboard (it only affects the unused plain-signUp path). STILL RECOMMENDED
   LATER: Brevo SMTP (300/day free) to unlock the email-OTP login path at scale (currently
   ~2 OTP emails/hour via built-in mailer) - then optionally retire the signup function.
8. **P6: store submit (OWNER).** Everything is prepared: signed AAB + test APK built,
   listings in `docs/store/STORE_LISTINGS.md`, step-by-step guide in
   `docs/store/SUBMISSION_GUIDE.md`, Play graphics in `assets/store/`. Owner needs: Play
   Console account ($25) + screenshots from a phone; iOS additionally needs a Mac + Apple
   Developer ($99/yr). After each store goes live: flip `androidLive`/`iosLive` (+ real iOS id)
   in `web/src/content/site.js`, rebuild, redeploy.

---

## 13. Changelog

- **2026-07-11 round 4 (BREVO SMTP LIVE - email OTP login works end to end)** - Owner created
  the Brevo account (free 300/day) and connected a Brevo MCP (server d2d3d85a; account/senders
  readable in-session; SMTP keys are UI-only by design). Configured via Management PAT:
  smtp-relay.brevo.com:587, login `b1b09a001@smtp-brevo.com`, sender «عوّاد | Awwad»
  <moradarafa.business@gmail.com> (verified+active), rate_limit_email_sent 2/h -> 30/h; the
  free-tier template lock lifted once custom SMTP was set, so the Arabic magic-link template
  (subject «رمز الدخول إلى عوّاد», big {{ .Token }} code, 8 digits per mailer_otp_length) is now
  live. DEBUGGED: first sends failed `525 "5.7.1 Unauthorized IP address"` - root cause was
  Brevo's "Blocking unauthorized IP addresses" (Security -> Authorized IPs), ACTIVE by default
  on this new account for BOTH API and SMTP keys with an empty allow list = everything blocked;
  the empty-list page is misleading (the toggle rows sit ABOVE the list). Owner deactivated both
  -> `/auth/v1/otp` 200, Arabic code email delivered. `kOtpLoginEnabled=true` (the «إرسال رمز»
  button is back); analyze clean, 12/12 tests, web+APK+AAB rebuilt and web redeployed to Pages.
  If email breaks again: check Brevo blocking wasn't re-activated, then auth logs (get_logs).
  **FINAL E2E CONFIRMATION:** full live curl suite passed (signup 200, password login 200,
  duplicate -> user_already_exists, admin-generated OTP code verify -> real access_token session,
  real /otp send -> 200) and the **owner CONFIRMED the Arabic code email arrived in the inbox**.
  rate_limit_email_sent later raised to 100/h. Live web app boots with 0 console errors. Source
  pushed (private repo commit 6f3e241), Pages commit 809fc91 (byte-identical live). Login + signup
  are now fully working end to end. **REMAINING OWNER ACTIONS (non-blocking): (1) revoke the
  Management PAT at supabase.com/dashboard/account/tokens - no longer needed; (2) install the new
  release APK on the device.**
- **2026-07-11 round 3 (SERVER AUTH CONFIG via PAT + account-screen UX pass)** - Chrome-profile
  mismatch made the dashboard-session route unusable (two Chrome profiles; the connected
  extension lives in the one whose Supabase session expired), so the owner generated a
  Management API personal access token (stored ONLY in the local AI memory; revoke after the
  Brevo step). Via `PATCH /v1/projects/{ref}/config/auth`: **site_url** `http://localhost:3000`
  -> `https://moradarafa1.github.io/app/` and **uri_allow_list** = github.io + both netlify
  fallbacks (verified by re-GET) - dead-localhost email redirects are gone. **HARD LIMIT
  DISCOVERED: the free tier CANNOT modify email templates while on the default mailer**
  (PATCH -> 400 "Email template modification is not available for free tier projects using the
  default email provider") => **Brevo SMTP is a PREREQUISITE** for the Arabic {{ .Token }}
  code email (and the app's type-a-code OTP flow). Config facts: mailer_otp_length=8,
  rate_limit_email_sent=2/hr, smtp_host=null. Consequently the email-OTP entry («إرسال رمز»)
  is HIDDEN behind `kOtpLoginEnabled=false` (auth_screen.dart) until SMTP + template land.
  OWNER-REQUESTED UX: AuthScreen AppBar title is now dynamic «إنشاء حساب»/«تسجيل الدخول»
  (replaces «حساب ومزامنة»); Settings' signed-out row renamed to «إنشاء حساب» (syncTitle in all
  3 .arb) and both it and the post-first-log prompt open the screen in CREATE mode (new
  `startInSignUp` param; AuthChoice/Profile keep sign-in mode); the research/optional-info
  notice paragraph («إضافة هذه المعلومات اختيارية...») REMOVED (existed only in auth_screen
  _regStrings x3; two stale internal docs updated too). Verified: gen-l10n, analyze clean,
  12/12 tests, web+APK+AAB rebuilt (INTERNET perm re-verified), web app redeployed to Pages
  (commit 4035700, live main.dart.js byte-identical). NEXT: owner creates a free Brevo account
  -> SMTP key; then one PATCH sets smtp_* + Arabic code template (+ raise rate_limit_email_sent),
  flip kOtpLoginEnabled=true, rebuild, redeploy, and REVOKE the PAT.
- **2026-07-11 round 2 (AUTH RELIABILITY: signup retries + sync-failure UX + email-config diagnosis)** -
  Owner hit "تعذّر الاتصال بالخادم" / "خطأ غير متوقع" on the register screen, plus OTP emails
  landing in spam containing a LINK (not a code) that redirected to a dead localhost:3000.
  LIVE-LOG DIAGNOSIS (auth+api logs, 15:50-16:44 UTC): the owner's first signup at 15:51:58
  actually SUCCEEDED end-to-end (admin/users 200 -> password /token 200 -> 3 pull GETs 200);
  the FAILURE was the post-auth PUSH request never reaching the server (network drop) - the app
  wrapped auth+sync in one try/catch, reported the whole thing as "cannot reach server", and the
  retry then hit user_already_exists (422 at 15:52:13). The clicked email link was an EXPIRED
  9-Jul magic link; /verify 303-redirected to the DEFAULT Site URL http://localhost:3000.
  APP FIXES (analyze clean, 12/12 tests): (1) SupabaseService.signUp - on user_already_exists
  the app now tries signInWithPassword with the entered credentials and signs the user in
  seamlessly (retry-after-partial-failure is no longer a dead end); wrong password -> localized
  "already registered" message. (2) auth_screen._syncAfterAuth - sync errors are caught
  separately: user sees "تم تسجيل الدخول... المزامنة لاحقاً من الإعدادات" toast and the screen
  closes signed-in (auth success is never reported as failure). (3) New errNoAccount mapping:
  otp_disabled/"signups not allowed" (shouldCreateUser=false, unknown email) now says "لا يوجد
  حساب بهذا البريد" instead of the misleading bad-code message; + syncLater/errNoAccount strings
  ar/en/fr. VERIFIED live via curl: fresh signup 200, duplicate -> 400 user_already_exists,
  password login 200 (test user cleaned). Deployed signup fn v1 confirmed to have proper CORS.
  Rebuilt web + release APK (62MB, INTERNET perm verified) + AAB; web app pushed to GitHub
  Pages (github.io repo commit eb6fc92). Server config was resolved in round 3 (next entry)
  via an owner-provided Management API token.
- **2026-07-11 (git sync verified - nothing to push)** - Owner asked to push local commits.
  Checked the private source repo: `git fetch` then compared - local `main` is fully in sync with
  `origin/main` at `042379d` (0 commits ahead/behind), working tree clean, no stash, no other
  branches. Nothing to push; all work through the 2026-07-07 signup/networking round was already
  on GitHub. Corrected the stale §5 + TODO #5 that still claimed local-only work.
- **2026-07-07 round 3 (SIGNUP EDGE FUNCTION - registration no longer needs emails)** - Owner
  delegated the email-confirmation decision ("do what's best/cheapest"). Dashboard toggle and
  Brevo both need owner accounts/access we don't have (no CLI token, MCP has no auth-config
  tool), so implemented the cleaner zero-cost fix entirely in-session: new `signup` edge
  function (repo: supabase/functions/signup/index.ts; deployed self-contained via MCP,
  verify_jwt=true) validates email/password, whitelists metadata keys, and admin-creates the
  user with email_confirm=true. Live-tested: signup -> immediate password login OK, profile
  trigger fired, duplicate email -> user_already_exists, bad email -> email_address_invalid,
  test users cleaned. `SupabaseService.signUp` now invokes the function then
  signInWithPassword (FunctionException re-thrown with the error code so the localized
  mapping works). APK+AAB+web rebuilt and redeployed with this flow.
- **2026-07-07 round 2 (E2E-verified backend + confirmation UX + full redeploy)** - Ran a live
  11-check E2E against the real Supabase project (admin-create user, password login via public
  endpoint, profiles+subscriptions triggers, habit/daily-entry upserts with the exact app
  payloads incl. Arabic+emoji, pull-back, RLS isolation between two users, anon blocked,
  cleanup): ALL PASSED. Discovered via testing: (a) GoTrue rejects fake email domains
  (email_address_invalid) - good; (b) EMAIL CONFIRMATION IS ON and the project hit
  over_email_send_rate_limit (built-in SMTP ~2/hour; Brevo still unconfigured) - see TODO;
  (c) the app used to pop back silently when signup returned no session (confirmation
  pending) - now shows a localized "open the confirmation email, then sign in" toast and
  switches to the sign-in form (auth_screen). Also: extracted shared isNetworkError()
  (core/cloud/net_errors.dart) used by auth/profile/settings screens; settings sync/export
  feedback now localized ar/en/fr and follows the RESOLVED UI locale instead of
  settings.locale. Rebuilt everything (analyze clean, 12/12 tests): release APK+AAB
  (~9:41 PM, INTERNET + Awwad cert re-verified) and Flutter web (--base-href /app/) + Astro
  site, redeployed BOTH to GitHub Pages (commit d80ba4e) and confirmed the live main.dart.js
  serves the new code. Site<->app linkage verified live: root links to /app/, base href
  correct, supabase URL baked in.
- **2026-07-07 (RELEASE APK could not reach Supabase - missing INTERNET permission)** - Owner
  tested `app-release.apk` on a real Android device; sign-up failed with
  `AuthRetryableFetchException ... Failed host lookup ... errno = 7`. Root cause: Flutter only
  injects `android.permission.INTERNET` into debug builds; `src/main/AndroidManifest.xml` lacked
  it, so EVERY release build (APK + the store AAB) shipped without network access (verified in
  the packaged release manifest). Fixed: permission added to the main manifest; release APK+AAB
  rebuilt WITH the Supabase --dart-defines and re-verified. Two more fixes in the same pass:
  (a) Gradle daemon was crashing with a native OOM (`-Xmx8G`+4G metaspace on a 16GB machine) -
  heap cut to 2GB + 30-min daemon timeout in `gradle.properties`; (b) raw exception strings were
  shown to users in snackbars - auth/sync/change-password errors now map to localized ar/en/fr
  messages (gotchas §10.7-9).
- **2026-07-06 (HOSTING MOVED to GitHub Pages - Netlify blocked by owner's ISP)** - The owner
  could not open either Netlify site. Diagnosed: the ISP blocks Netlify's edge IPs at the TCP
  level (`Test-NetConnection awwad-habits.netlify.app:443` = False, IP 63.176.x; while
  google/cloudflare/pages.dev/vercel.app/github.io all = True; api.netlify.com works, which is
  why deploys succeed). The Netlify deploys are healthy and reachable worldwide, just not from
  the owner's network. FIX: mirrored both onto **GitHub Pages** (github.io is reachable). Created
  the public user-page repo **github.com/moradarafa1/moradarafa1.github.io** (contains only the
  built static output - safe; the Flutter build ships only the public anon key). Layout: the
  marketing site at the ROOT and the Flutter web app under **/app/** = one domain, "linked
  together". LIVE + verified 200 from the owner's machine:
  - Site: **https://moradarafa1.github.io/**
  - Web app: **https://moradarafa1.github.io/app/**
  Config changed for this: `web/astro.config.mjs` site -> `https://moradarafa1.github.io`,
  `web/public/robots.txt` sitemap, `web/src/content/site.js` `WEB_APP_URL` ->
  `https://moradarafa1.github.io/app/`; the Flutter web app is built with `--base-href /app/`
  (needs `MSYS_NO_PATHCONV=1` in Git Bash or the `/app/` arg gets path-mangled) + a `404.html`
  copy of index.html for SPA fallback; a root `.nojekyll` is REQUIRED (Astro's `_astro/` folder
  starts with `_`, which Jekyll would drop). Deploy = assemble (site dist at root, app build/web
  at /app/, .nojekyll) into a staging dir and push to the github.io repo's main branch. Netlify
  sites are kept as a global fallback but are the owner's-ISP-blocked path. TODO if wanted:
  Cloudflare Pages (cleaner *.pages.dev URLs) needs the owner to `wrangler login`.
- **2026-07-06 (FINAL logo: owner-supplied plant design)** - Owner delivered a finished logo
  design (`تصميم لوجو عواد.zip`, added to the repo at `assets/brand/`: `awad-app-icon.svg`,
  `awad-plant.svg`, `awad-plant-mono.svg`, README + design doc). It is a bright, organic sprout:
  two lime veined leaves (#8FBF44 / #9FCE57 with #C6E58C/#CBE892 veins) on an olive stem
  (#5E8A31), on a dark rounded square (#12161F). Installed everywhere: rewrote
  `assets/icons/icon-full.svg` (full 1024 icon) + `icon-foreground.svg` (transparent plant,
  adaptive-safe), regenerated `icon-1024.png` / `icon-foreground-1024.png` / `splash-logo.png`,
  all Android/iOS/web launcher icons (flutter_launcher_icons), native splash, site
  favicon/apple-touch/192/512, og-image + Play feature graphic (plant + عوّاد + Awwad),
  play-icon-512, the in-app `app/assets/logo/sprout.png` (shown on Language + AuthChoice with the
  appName text, Cairo), and the site header + 404 mark (`web/public/logo-mark.png`, replaces the
  🌱 emoji). The earlier hero-heading removal + flat onboarding buttons are kept. Verified:
  analyze clean, tests pass, web/AAB/APK rebuilt, site 112 pages 0 em-dashes, site + web app
  redeployed. (Supersedes the sprout/Kufi/Salma-wordmark logo experiments; those SVG drafts
  remain in the repo but unused.)
- **2026-07-05 (FINAL logo: Salma wordmark with leaf-shadda)** - Owner iterated once more:
  the logo is now the WORDMARK «عواد» set in Salma Arabic Black (the site's own curvy display
  font - matching the hero screenshot), with NO sharp edges (glyphs drawn as a path and stroked
  with a round-join/round-cap pen so every terminal is soft), in the distinctive green gradient
  (#4ade80 -> #16a34a), and the shadda over the و drawn as a creative two-leaf sprout (bezier
  leaves + tiny stem growing straight out of the waw head). Renderer:
  `scratchpad/make-wordmark.ps1` (params for font size / word Y / leaf base; -SkipBg for the
  transparent master). Assets regenerated from it: icon-1024 / adaptive foreground / splash,
  all launcher icons, site favicon/apple-touch/192/512, og-image + Play feature graphic (now
  wordmark + tashkeel slogan in Salma, like the site hero), play-icon-512, and a tight-cropped
  `app/assets/logo/wordmark.png` used on the Language + AuthChoice screens (replaces the emoji
  AND the appName text - the wordmark IS the name; wrapped in Semantics(label: appName)).
  Flat onboarding buttons from the previous entry kept. Verified: analyze clean, tests pass,
  web/AAB/APK rebuilt, site rebuilt + redeployed.
- **2026-07-05 (owner revert: sprout logo + flat onboarding buttons)** - Owner asked to undo
  the new Kufi wordmark logo (back to the previous green sprout) and to make the onboarding
  buttons simple instead of the puffy liquid-glass style. Done: restored
  `assets/icons/icon-1024.png` + `icon-foreground-1024.png` + `splash-logo.png` from git
  (pre-rebrand sprout), regenerated ALL launcher icons / splash / site favicons / og-image /
  Play graphics from the sprout; reverted the in-app welcome + auth-choice marks and the site
  header + 404 mark back to the 🌱 emoji; removed the transient `logo-mark.png` assets (+ their
  pubspec asset entry). `GlassButton` rewritten as a FLAT pill (accent-tint fill + thin colored
  border, no BackdropFilter / specular / heavy shadow), matching the habit-switcher chip look;
  it is used only on the language + sign-in screens. The rest of the liquid-glass UI (glass nav
  dock, ambient glow, dark/light mode) is unchanged. NOTE: `logo-master.svg`/`logo-mark.svg`
  (the Kufi masters) are kept in the repo but no longer referenced. Verified: analyze clean,
  12 tests, web/AAB/APK rebuilt, site 112 pages 0 em-dashes, site + web app redeployed.
- **2026-07-05 (rebrand + liquid glass + light mode + evidence-based content)** -
  **(1) NEW LOGO**: professional Kufi wordmark of عوّاد where the shadda above the و IS the
  sprout (two gradient leaves on a stem growing from the waw head); baseline = soil, waw root
  dips below it, alef = tallest stem, geometric ع with open eye + hook. Designed via a
  5-concept parallel workflow, visually judged, hand-refined. Vector masters:
  `assets/icons/logo-master.svg` (full icon) + `logo-mark.svg` (transparent mark). ALL assets
  regenerated from them: launcher icons (android/ios/web via flutter_launcher_icons), native
  splash, site favicon/apple-touch/icon-192/512/og-image, Play icon 512 + feature graphic
  1024x500, site header brand + 404 + in-app brand (`app/assets/logo/mark.png`, replaces 🌱 on
  Language/AuthChoice screens). **(2) LIQUID GLASS UI**: GlassButton now uses a real
  BackdropFilter (blur 18 + saturation-boost color matrix, Apple's recipe) + specular top
  highlight + springy press-scale; floating glass bottom dock (blur 24, translucent, hairline
  border, MediaQuery.removePadding); AmbientBackground radial glows behind every screen (cheap,
  gradient-only); translucent cards; Cupertino page transitions everywhere. **(3) DARK/LIGHT
  MODE**: `AppColors` converted from const fields to palette-backed getters (`Palette` +
  `kDarkPalette`/`kLightPalette`, light accents darkened for WCAG AA on white);
  `settings.darkMode` (default true) + Settings toggle; `buildAwwadTheme(dark:)`;
  136 invalid-const sites de-consted via 5 parallel agents; analyze clean. **(4) SUPABASE
  PAUSE FIX** (email 2026-07-04 "insufficient activity" DESPITE green 3-day pings - a single
  REST SELECT per 3 days is not enough): migration `0007_ops_heartbeat` adds a locked table +
  SECURITY DEFINER `heartbeat()` RPC (anon-callable, only bumps a timestamp; advisor-checked);
  keep-alive.yml now DAILY with 3 signals (REST read + rpc/heartbeat WRITE + edge-function
  invocation); independent local backup pinger `ops/keep-alive-local.ps1` registered as Windows
  task `AwwadSupabaseKeepAlive` (every 2 days, logged, tested green). **(5) CURATED VIDEOS
  (owner rule)**: the suggested-video card now exists ONLY for habits with REAL verified videos
  (<30 min, trusted source: واعي / الشيخ مصطفى العدوي), programmatically verified twice
  (find + adversarial re-fetch of lengthSeconds/author). 10 habits qualified (secret_habit,
  gossip, pray_on_time, adhkar, keeping_ties, daily_charity, istighfar, gratitude,
  honor_parents, dua); all others show NO card; the generic YouTube-search fallback removed.
  Generated into `habit_daily_content.dart` `kHabitVideos`. **(6) EVIDENCE-BASED PROGRESSIVE
  TRACKING**: new `habit_stages.dart` - 4 recovery stages for break (HRT: awareness ->
  competing response -> environment control -> maintenance/relapse-prevention) and 4 commitment
  stages for build (foundation -> consistency -> consolidation -> established), thresholds 0/7/
  30/60 aligned with shields; daily log shows a stage card (X of 4 + focus + 3 tips + progress
  bar to next stage) for BOTH tracks (replaces the old week-based `_phaseBanner`), and
  checklist order adapts to the stage (environment leads from stage 3). Per-habit content for
  ALL 36 habits designed + adversarially verified via workflow: 34 custom slider pairs
  (`kHabitMetricsOverrides`), 36 tailored daily questions (`kHabitQuestions`, e.g. anger:
  "هل انفجرت غضباً اليوم؟"), 18 new BUILD checklists (`kExtraCompeting`/`kExtraEnvironment`,
  rendered with build-specific group titles "خطوات اليوم"/"تهيئة البيئة"; build habits without
  tailored lists show none instead of the break-oriented seeded fallback). Assembled
  programmatically (`assemble_daily_content.mjs`), em-dash-stripped. New `habit_stages_test`
  (4 tests). Verified: analyze clean, 12/12 tests, site 112 pages 0 em-dashes, site redeployed.
- **2026-07-04 (DEPLOY + store-ready release kit)** - Full review pass on all four surfaces,
  then shipped: **(1) Netlify deploys** - marketing site → https://awwad-habits.netlify.app
  (site id `0b65cc50-...`), Flutter web app (cloud build) → https://awwad-app.netlify.app
  (site id `ffa150f7-...`); both verified `state=ready` via API (the netlify.app edge was
  unreachable from the owner's ISP that day - documented in §5). **(2) Site SEO/UX** - canonical/
  hreflang/sitemap/robots switched from the unowned `awwad.app` to the live Netlify URL;
  og:image (1200×630, generated from the app icon) + twitter meta + favicon set + theme-color;
  branded trilingual 404 page; `_headers` caching; `WEB_APP_URL` → the live web app; STORE got
  `androidLive`/`iosLive` flags - while false every download CTA routes to the web app with a
  trilingual "coming soon on the stores" note (no dead store links). Build: 112 pages, 0
  em-dashes. **(3) Android store-ready** - real upload keystore generated
  (`app/android/app/upload-keystore.jks`, alias `upload`, passwords in gitignored
  `key.properties`, both patterns already gitignored), release signing wired in
  `build.gradle.kts` (falls back to debug when key.properties is absent); signed release
  **AAB 56.3MB** + **APK 58.4MB** built (cloud keys embedded). Exact-alarm permission NOT
  needed (all notifications use `inexactAllowWhileIdle`). **(4) iOS prepared** -
  `CFBundleDisplayName` → «عوّاد», `CFBundleLocalizations` ar/en/fr,
  `ITSAppUsesNonExemptEncryption=false`; build/submit requires a Mac (guide written).
  **(5) MSA/em-dash cleanup** - old colloquial tagline («دايماً بالخير») + em-dashes purged from
  `pubspec.yaml` description, `app/web/manifest.json` (+ lang/dir added), `app/web/index.html`
  (title/description, `lang="ar"`); `onGenerateTitle` now localizes the app title; `_redirects`
  SPA fallback added to `app/web/`. **(6) Store kit** - trilingual ASO listings drafted +
  adversarially verified (char limits checked programmatically) in `docs/store/STORE_LISTINGS.md`;
  Arabic submission guide `docs/store/SUBMISSION_GUIDE.md`; Play icon 512 + feature graphic
  1024×500 generated in `assets/store/`. Verified: analyze clean, 8/8 tests, web+AAB+APK+site
  builds green, live-URL spot checks 200 (via API state; local ISP blocked direct fetch).
- **2026-06-30 (onboarding reorder + glass buttons)** — First-run flow is now **language →
  account-choice → onboarding** (was account-choice first). New `LanguageScreen` (gated on
  `settings.locale == null`) with floating glass language buttons; `AuthChoiceScreen` (gated on
  `authChoiceMade`) now uses the new `GlassButton`; `OnboardingFlow` dropped its welcome+language
  step (now 4 steps: survey→track→habit→setup; indices/progress-bar updated). New reusable
  `core/widgets/glass_button.dart` (iOS "liquid glass": translucent gradient + luminous border +
  float shadow, no BackdropFilter). NOTE: on the offline web build the "Sign in" button is
  hidden (`SupabaseService.configured == false`); build with the anon key
  (`ops/build-app-cloud.ps1`) to show it + enable sync. To re-see onboarding in a browser, clear
  the origin's localStorage / use a private window (SharedPreferences persists there). Verified:
  analyze clean, 8 tests, cloud web build OK.
- **2026-06-28 (appropriateness + glass + docs)** — Renamed «الامتنان اليومي»→«الحمد والدعاء»
  and «صيام النفل»→«صيام النوافل» (catalog + seed + live DB). adhkar reminders → after Fajr +
  after Isha ([6,21]). Daily-log content made track-aware: build habits now ask "هل أدّيت العادة
  اليوم؟" (Yes = good; the slip/done mapping no longer inverted), and water got its own metrics
  (cups + spread) via `kWaterMetrics`. Buttons restyled to **iOS "liquid glass"** (translucent
  fill + luminous border) in `theme.dart`. **Docs overhauled**: README rewritten (programmer
  quickstart, current architecture) and this file got a §0 "FOR THE NEXT CLAUDE CODE SESSION"
  directive block + refreshed §1/§7/§8/§12 (incl. the phone-control feature plan and the deep
  per-habit appropriateness review as the two queued priorities). Verified: analyze clean, web
  build OK.
- **2026-06-28 (per-habit reminder times + tweaks)** — Each habit can now have
  MULTIPLE reminder times (`Habit.reminderHours`; `times` getter falls back to the legacy
  single hour). Catalog `defaultReminderHours` suggests sensible defaults (water = 5/day,
  adhkar = morning+evening). New `ReminderTimesPicker` widget in onboarding + AddHabit +
  HabitsScreen (alarm icon → edit + reschedule). Notifications now schedule per habit per
  time (ids 3000..3059 via `scheduleHabitReminder` + `cancelHabitReminders`; the old single
  id-1001 reminder is retired); `applyNotificationSchedule` takes a `List<HabitReminderSpec>`
  built by `habitRemindersFor(habits, loc)`. Settings' global reminder-time dropdown removed
  (now per-habit); `setHabitReminderHours` added. Renamed the gratitude habit «الامتنان اليومي»
  → «الحمد والدعاء» (catalog + seed + live DB). Removed the first-open notification rationale
  dialog: the OS permission is now requested directly on first open (AuthChoiceScreen, with a
  home-shell fallback). Verified: analyze clean, 8 tests, web build OK.
- **2026-06-28 (content + per-habit tailoring)** — Added 6 new habits (3 build: `salawat`,
  `honor_parents`, `dua`; 3 break: `late_nights`, `binge_watching`, `anger`) to the catalog +
  seed.sql + live DB (now 36 catalog rows). Per-habit HRT checklists (tailored competing
  responses + environment) for all break habits live in GENERATED `core/catalog/habit_content.dart`
  (`kHabitChecklists`); the daily log uses them with the generic seeded fields as fallback. The
  "suggested solutions" card now also shows a **scholar-video search** (YouTube search scoped to
  the habit topic + the 4 requested scholars via `kHabitVideoQuery` / `habitVideoSearchUrl`);
  secret-habit keeps the واعي channel. The whole solutions/video card is **hidden when offline**
  (new `connectivity_plus` + `core/connectivity/online.dart` `onlineProvider`). Pomodoro dial is
  now tappable to start/pause (the start button complaint). Profile/account gained
  **change-password** (`SupabaseService.changePassword`) + sign-out. Web (Astro): hero h1 →
  «لليوم فقط، خطوة واحدة لنتغير»; nav gained «تسجيل الدخول» (right) + «حسابي» (far left) linking to
  the web app; footer «حذف الحساب» removed; contact email → moradarafa600@gmail.com; new habits
  added to home examples. NOTE: scholar videos ship as relevance-scoped YouTube *search* links
  (robust, no link-rot); the workflow also found specific candidate videos (see summary) for
  optional curation. Verified: analyze clean, 8 tests, both builds, 0 em-dashes.
- **2026-06-28 (activation/retention + notifications)** — First-open `AuthChoiceScreen`
  (sign in vs continue-as-guest; gated by `settings.authChoiceMade`, migration auto-sets it
  true for existing users). Post-first-log account popup now fires once via
  `settings.firstLogPromptShown`; on decline it schedules a one-off 3-day sign-up nudge
  (cancelled if the user signs up). Notification permission now asks with an in-app rationale
  (once, `notifPromptShown`) before the OS prompt; `ensureNotificationPermission()` split from
  scheduling. New notifications: daily Ibrahimic-prayer **dhikr** (id 1002, verified Sahih
  Muslim 405 / Abu Mas'ud text in `core/content/dhikr.dart`, Arabic body in all locales,
  gated by dhikr + religious-content toggles), badge-earned tray congratulations (id 2000+),
  and the 3-day re-engage (id 1003). Shared `notif_scheduler.dart` keeps Home + Settings in
  sync. Settings gained Notifications + Daily-dhikr toggles and Profile + العادات entries.
  New `ProfileScreen` (aggregate badges/top shield across habits) and `HabitsScreen` (add via
  AddHabitScreen / delete via removeHabit, blocks deleting last). `HabitSwitcher` now shows the
  active-habit chip even with a single habit (bug fix). All notification fns are no-ops on web
  via the stub. Verified: analyze clean, 8 tests pass; adversarial review workflow run.
- **2026-06-27 (habit-aware metrics)** — The two daily-log sliders are now per-habit
  via `HabitMetrics` on the catalog + `metricsForHabit(catalogKey, track)`. Break = urge/
  resistance (`kBreakMetrics`); build = progress/quality (`kBuildMetrics`); prayer habits
  (`pray_on_time`, `wake_fajr`) = delay + early/sunnah (`kPrayerMetrics`). Daily log and
  Stats (chart title + averages) resolve labels from the active habit. No data-model change
  (still stored in `DailyEntry.urge`/`resistance`). To give a habit custom sliders, set
  `metrics:` on its `CatalogHabit`. (didSlip wording left as-is for now.)
- **2026-06-27 (multi-habit)** — App now supports MULTIPLE concurrent habits: up to
  3 break + 3 build at once (`kMaxHabitsPerTrack`). `AppState.habit` (single) became
  `AppState.habits` (list) with an active-habit pointer in `AppSettings.activeHabitId`;
  all stats/entries/badges are scoped to the active habit; one-time migration wraps any
  legacy single habit into the list. New `HabitSwitcher` (chips to switch + "+", on
  Today/Stats/History/Badges) and `AddHabitScreen` (track + picker excluding owned
  catalog keys + per-track cap + a 90-day "focus on one goal" advisory dialog; the cap is
  the real rule, the advisory is informational). Added the **secret-habit** (`secret_habit`,
  «العادة السرية») break habit + a curated **واعي** YouTube recommendation (15-min suggestion,
  `kWaaiUrl`) shown as a resource card in the daily log and as a callout on the web
  break-habit page (ar/en/fr). Cloud sync (`SyncService`) now pushes/pulls all habits.
  seed.sql + live `habit_catalog` updated (now 15 break + 15 build). Web: `WAAI_URL` +
  `resource` block rendered in `[...path].astro`. Verified: analyze clean, 8 tests pass
  (incl. new multi-habit scoping), flutter web build OK, site builds 111 pages, 0 em-dashes.
- **2026-06-27 (batch 2)** — Onboarding survey reworked: gender mandatory, age = 18-24/25-34/35-44/45+, country = searchable all-countries picker (`countries.dart`, localized), removed referral/consent/skip/optional-wording. Onboarding "Next" is now always-visible (wide button) with validation toast (fixed invisible disabled button). Daily-log save now auto-navigates to Stats (via `homeTabProvider`) and, on first log, suggests creating an account (sync) for not-signed-in users. Site heading font lightened (Salma Bold 700, more line-height). Site CTA now dual: smart "download" (OS-detect → store, else Android/iOS popup) + "use web version" (→ WEB_APP_URL); store URLs in site.js STORE are PLACEHOLDERS until published. Credit link (Morad Arafa) → Facebook (https://www.facebook.com/MoradArafaOfficial/) in site + app. Badge `logged_30` → "مواظب — ١٠٠ تسجيلة" threshold 100 (to distinguish from the 30-day streak shield); updated in app + seed + live DB. Verified: analyze clean, 5 tests, web+app build, site 111 pages, app mounts.
- **2026-06-27** — Backend deployed to cloud (migrations 0001-0006 + seed) via MCP; security
  hardened (0005); E2E tested. Website redesigned (taste-skill) + fully converted to MSA;
  30-article trilingual SEO blog added (111 pages). Pomodoro feature added. Registration UI
  collects mandatory gender + optional country/birth_date/WhatsApp + privacy notice; DB
  migration 0006. "متلازمة نتف الشعر" added to catalog. New brand slogan set. App l10n
  converted to MSA. Android SDK installed; debug APK builds. Open bug: onboarding language tap.
- **2026-06-27 (earlier)** — P0 + P1 app, backend code, Astro site (30 pages), admin dashboard,
  icons/splash. Initial GitHub push.
