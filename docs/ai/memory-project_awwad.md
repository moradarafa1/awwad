---
name: project-awwad
description: "Awwad habit app (Flutter + Astro + Supabase) — zero-cost, trilingual, Islamic-aligned. Lean pointer; full state on disk."
metadata: 
  node_type: memory
  type: project
  originSessionId: 87c12a4d-bd34-4362-ab39-8ca88a65a8e3
---

**عوّاد — Awwad** — trilingual (ar-RTL/en/fr) habit-change app at `D:\Claude\awwad` (monorepo: app/ Flutter, web/ Astro, supabase/, admin/, ops/, docs/). Break/build a habit via HRT; Islamic-values-aligned; zero operational cost.

**>>> CANONICAL STATE IS ON DISK: read `D:\Claude\awwad\docs\PROJECT_STATE.md` when resuming — it has the full handoff (state, decisions, accounts, gotchas, build commands, TODO, changelog). `README.md` = programmer quickstart. Keep PROJECT_STATE.md updated, not this file. <<<**

**Hard rules:** zero paid deps (free tiers only; never create 2nd Supabase project); Arabic = MSA فصحى; NO em-dash (—) user-facing; Islamic rulings cite islamweb.net + disclaimer; service_role key NEVER in repo/client; offline-first app. Slogan: «رفيقٌ مَن زانَ عُمرَه، وحُسُنُ عملَه».

**Toolchains (this machine):** Flutter `D:\flutter\bin\flutter.bat` (3.44.4, NOT on PATH); JDK17 `D:\jdk17\jdk-17.0.19+10`; Android SDK `D:\Android\Sdk`; Supabase CLI `D:\supabase\supabase.exe`. Supabase MCP (server `ef4e3dc4-...`) is live in-session (apply_migration/execute_sql/get_advisors).

**SECRETS (local only — never write these into the repo):**
- Android upload keystore: `app/android/app/upload-keystore.jks`, alias `upload`, store+key password `«REDACTED, see _local/memory-project_awwad.FULL.md»` (also in gitignored `app/android/key.properties`). Owner must back it up.
- Supabase project ref: `kdczbzzjezyhfxgpegqc` · URL `https://kdczbzzjezyhfxgpegqc.supabase.co`
- anon (public, shippable): `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkY3pienpqZXp5aGZ4Z3BlZ3FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MzUxNzcsImV4cCI6MjA5ODExMTE3N30.U1EEeJ_kCauZnXWVTlb-Whm5DyEIgGqkwEUpG8pI2vQ`
- service_role (SECRET): `«REDACTED, see _local/memory-project_awwad.FULL.md»`
- Supabase Management PAT (SECRET, owner-provided 2026-07-11 in-chat): `«REDACTED, and it should be REVOKED, see _local»` - full-account Management API access (PATCH /v1/projects/{ref}/config/auth works). Kept for the pending Brevo SMTP step; ask owner to REVOKE it at https://supabase.com/dashboard/account/tokens once SMTP + email template are done.
- GitHub: https://github.com/moradarafa1/awwad.git (private); owner email olenshop.sa@gmail.com.

**Update (2026-07-12, power features):** SOS «لحظة ضعف» screen (urge surfing, break habits, Today-tab button) + DNS content shield (Private DNS guided setup `family.cloudflare-dns.com` + live verification via MethodChannel `awwad/dns_shield` in MainActivity.kt - FIRST native Kotlin, untested on device yet, fail-open). Source PUSHED `e68e639`. Roadmap waves 3-8 in PROJECT_STATE §12 item 0c (next: usage monitoring in a dedicated mobile session; system-wide blur = infeasible, documented). IF SESSION DIED before deploy: build output may exist in app/build; redeploy = copy build/web → github.io repo /app/ + rebuild APK for owner.

**Update (2026-07-11 night, AUTH MODEL CHANGED + calendar):** owner wants OTP at SIGNUP (email verification) + FORGOT-PASSWORD flows, not passwordless login. Rebuilt: plain `auth.signUp` (Confirm-email ON) → Arabic code (Confirmation template) → `verifyOTP(type: signup)`; reset = `resetPasswordForEmail` → code (Recovery template) → `verifyOTP(type: recovery)` → `updateUser(password)`. Existing-confirmed email detection = `identities?.isEmpty ?? false` (GoTrue obfuscated anti-enum user). `signup` edge fn RETIRED from client (still deployed as emergency fallback). AuthChoice first-open = THREE buttons (إنشاء حساب primary / تسجيل الدخول / زائر). New `features/home/month_heatmap.dart` calendar heatmap in Stats (RTL-aware, locale week start via MaterialLocalizations, theme-role colors, per-day bottom sheet). Full E2E verified live incl. recovery loop + unconfirmed-login redirect. Brevo MCP = server d2d3d85a (account/senders readable; SMTP keys are UI-only).

**Update (2026-07-11, auth - RESOLVED end to end):** signup/login hardened (already-exists retry now auto-signs-in; sync failure no longer masks a successful login). Via PAT: `site_url` fixed localhost:3000 → `https://moradarafa1.github.io/app/` + allow list. **Brevo SMTP LIVE** (account moradarafa.business@gmail.com, login `b1b09a001@smtp-brevo.com`, host smtp-relay.brevo.com:587; SMTP key `«REDACTED, see _local/memory-project_awwad.FULL.md»`; sender «عوّاد | Awwad»; rate 30/h; free-tier template lock lifts only AFTER custom SMTP): Arabic {{ .Token }} magic-link template live, `kOtpLoginEnabled=true`. **GOTCHA: Brevo new accounts have "Blocking unauthorized IP addresses" ACTIVE by default (API+SMTP) → every Supabase send = `525 5.7.1 Unauthorized IP`; owner deactivated both at Security → Authorized IPs.** A Brevo MCP is connected (account/senders/campaigns; SMTP keys not exposed by API). UI: «حساب ومزامنة» → «إنشاء حساب» (+ startInSignUp), research notice removed. 2 real users in auth.users (owner + Menna) - never casually wipe. mailer_otp_length=8. Owner still to revoke the Supabase PAT when told everything is done.

**Update (2026-07-05):** NEW logo (Kufi عوّاد wordmark, shadda-sprout over الواو; masters `assets/icons/logo-master.svg`+`logo-mark.svg`, all assets regenerated). Liquid-glass UI (real BackdropFilter) + ambient glows + glass dock. Dark/LIGHT mode toggle in Settings (`AppColors` now palette getters — NEVER use inside `const`). Supabase pause email fixed: single 3-day REST ping was "insufficient activity" → daily 3-signal GH cron + `heartbeat()` RPC (migration 0007) + Windows task `AwwadSupabaseKeepAlive`. Video card now ONLY for 10 habits with verified <30min scholar videos (`kHabitVideos`). Progressive 4-stage tracking tied to shields (`habit_stages.dart`) + per-habit metrics/questions/build-checklists for all 36 (`habit_daily_content.dart`, generated).

**Status (2026-07-04): DEPLOYED + store-ready.** Site LIVE https://awwad-habits.netlify.app · web app LIVE https://awwad-app.netlify.app (Netlify team `morad-vxjyb3y`, CLI logged in; site ids in PROJECT_STATE §5). Signed release AAB+APK built (upload keystore above). iOS configured, needs Mac. Store kit: `docs/store/STORE_LISTINGS.md` + `SUBMISSION_GUIDE.md` + `assets/store/`. Old language-tap bug obsolete (new LanguageScreen works). NOTE 2026-07-04: `*.netlify.app` edge unreachable from owner's ISP (api.netlify.com fine) — if sites don't open locally it's the network, not the deploy. **Pending (owner):** store submit (Play $25 / Apple $99+Mac) + screenshots, domain purchase, Supabase auth email/Brevo, Google Sheets sink, FCM (P4). After stores go live: flip `androidLive`/`iosLive` + iOS id in `web/src/content/site.js`, rebuild, redeploy.

**Cross-session note:** two AI sessions worked Awwad in parallel today; coordinate via `docs/PROJECT_STATE.md` now (single source of truth). Don't edit the same file or run `flutter build` simultaneously.

A reusable Claude skill **"Awwad"** (`~/.claude/skills/Awwad/SKILL.md`) captures the build playbook for spinning up similar zero-cost trilingual Flutter+Astro+Supabase projects.
