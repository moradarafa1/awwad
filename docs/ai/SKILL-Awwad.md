---
name: Awwad
description: >
  Playbook for building a zero-cost, trilingual (Arabic-default RTL / English / French),
  Islamic-values-aligned product like Awwad: a Flutter app (Web/iOS/Android) + an Astro
  marketing site with an SEO blog + a Supabase backend (Postgres + RLS + Edge Functions),
  all on free tiers. Use when starting or extending such a project, or when you need the
  conventions, build commands, and hard-won gotchas that make these projects go smoothly.
  Triggers: "build something like Awwad", a free-tier Flutter+Supabase+Astro habit/wellness
  app, trilingual MSA content, or zero operational cost requirements.
---

# Awwad build playbook

Reusable conventions and workflow distilled from the Awwad project. Follow this to spin up
a similar product without re-discovering the same problems. Keep outputs production-grade.

## 1. The seven non-negotiable rules

1. **Zero operational cost.** Free tiers only; the only paid item is a domain. Never add a
   paid dependency. With Supabase free, never create a 2nd project (org cap = 2).
2. **Trilingual, no hard-coded strings.** Arabic (default, RTL), English, French. Flutter →
   gen-l10n `.arb`; Astro → one content module (e.g. `src/content/site.js`).
3. **Arabic = Modern Standard Arabic (فصحى).** Never colloquial in user-facing text.
4. **No em-dash (—) anywhere user-facing.** Use hyphen, colon, or comma. Audit the built
   output: `grep -rl "—" dist` must return nothing.
5. **Islamic-values-aligned content.** Source halal/haram rulings from islamweb.net with a
   standing disclaimer; never issue your own fatwa.
6. **Offline-first app.** Cloud auth/sync must never block startup (timeout-guard it).
7. **Secrets discipline.** The backend `service_role` key never appears in the repo or the
   client. Only the public `anon`/publishable key ships to clients.

## 2. Architecture (monorepo)

```
<project>/
  app/        Flutter (Web + iOS + Android) — the product. Offline-first; cloud optional.
  web/        Astro static marketing site (ar/en/fr) — SEO + blog + legal pages.
  admin/      Static admin dashboard (reads admin RPCs; noindex; config gitignored).
  supabase/   migrations/ (SQL + RLS) + functions/ (Edge) + seed.sql + config.toml.
  ops/        keep-alive Action, cloud build script, icon generator.
  docs/       PROJECT_STATE.md (canonical handoff) + content/tracking guidelines.
```

Key patterns:
- **Flutter:** `LocalStore` over `shared_preferences` is the offline source of truth; cloud
  sync (Supabase) is a gated layer enabled only when build-time keys are present
  (`String.fromEnvironment('SUPABASE_URL'/'SUPABASE_ANON_KEY')`). main() runs offline-first;
  cloud init is wrapped in try/catch + a short timeout.
- **Astro site is content-driven:** one `site.js` holds all copy (per-locale objects); one
  `posts.js` holds blog articles; a single `[...path].astro` generates every page. To change
  text, edit content modules - not markup.
- **Supabase:** RLS on every table; admin is row-based (`admin_users` table) gated by an
  `is_admin()` SECURITY DEFINER function inside admin RPCs; privileged writes happen only in
  Edge Functions with the service_role.

## 3. Free-tier stack

Supabase (Auth+Postgres+RLS+Edge) · Brevo SMTP (300 emails/day) · Cloudflare Pages or Netlify
(hosting) · Firebase FCM (push) · GitHub Actions + a 3-day cron keep-alive (Supabase free
pauses after 7 idle days - the keep-alive needs repo secrets SUPABASE_URL + SUPABASE_ANON_KEY).

## 4. Phased plan

- **P0 scaffold:** monorepo, i18n wiring, content/values guideline, keep-alive, catalog seed.
- **P1 offline app:** onboarding (language → optional survey → mandatory track → item pick),
  the core daily loop, customization, stats, gamification, settings. Verify offline.
- **Backend code:** migrations + RLS + seed + edge functions (do NOT rely on static review;
  see §6 - deploy and run advisors to catch real errors).
- **Site + blog:** Astro pages + a large trilingual SEO blog (Article + FAQPage JSON-LD).
- **Cloud wiring:** enable auth/sync via dart-define; live-test signup pipeline.
- **Deploy + store:** hosting + domain; store screenshots, signing, submission (iOS needs Mac).

## 5. Build & verify commands (template)

```bash
# Flutter (use full path if not on PATH, e.g. D:\flutter\bin\flutter.bat)
flutter analyze lib                 # must be: No issues found
flutter test                        # all green
flutter gen-l10n                    # after editing .arb files
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter build apk --debug --dart-define=...   # needs JAVA_HOME=JDK17 + ANDROID_HOME

# Site
cd web && npm install && npm run build        # then: grep -rl "—" dist  (expect nothing)

# Backend: apply each migration, run seed, then ALWAYS run the security advisor.
```

## 6. Hard-won gotchas (apply proactively)

1. **Flutter web + supabase_flutter passkeys.** On web, `Supabase.initialize` throws
   "Null check operator used on a null value" unless the Passkeys Web SDK bundle is present:
   add `web/passkeys_bundle.js` and reference it with a `<script>` in `web/index.html`. Use
   `anonKey:` (legacy JWT) not `publishableKey:`.
2. **Supabase default privileges (SECURITY).** Supabase auto-grants EXECUTE on every new
   function to `anon` + `authenticated`, and this SURVIVES `revoke ... from public`. So you
   must explicitly `revoke ... from anon` on functions that must not be public RPCs (e.g. any
   self-grant/award function). Run `get_advisors(security)` after every DDL change.
3. **Deploy to verify, do not trust static review.** Actually applying migrations caught a
   real SQL error (`order by <alias>` with no select alias) and the anon-privilege hole that a
   read-through missed. Always apply + advisor + a live E2E signup test (admin-create a
   confirmed user, assert the trigger created profile+subscription, then delete).
4. **Android Gradle.** Add to `app/android/gradle.properties`:
   `kotlin.jvm.target.validation.mode=warning` (plugins mix Java 11 / Kotlin 1.8) and
   `kotlin.incremental=false` (Windows .tab cache-close failures). Feed sdkmanager licenses
   via bash `< yes.txt` (PowerShell piping does not reach its stdin).
5. **CanvasKit preview limit.** The Electron preview cannot screenshot a Flutter CanvasKit
   canvas and a reused instance may not mount; use a FRESH preview instance and verify via
   analyze/tests/build + a glass-pane check. It renders fine in a real browser. Heavy CSS GPU
   effects (feTurbulence grain, backdrop-filter) also wedge HTML screenshots - avoid them.
6. **Reveal animations must fail-open.** Never hide content with opacity-0 that only JS/an
   IntersectionObserver un-hides; if the compositor stalls, content vanishes. Animate
   transform only (content stays opacity 1).
7. **Large content generation.** Generate a big blog (e.g. 30 articles x 3 languages) with a
   fan-out workflow, then assemble into the content module with a small Node script that adds
   dates and strips em-dashes. Do not paste megabytes into context.
8. **Android RELEASE builds need INTERNET permission explicitly.** Flutter injects
   `android.permission.INTERNET` into the DEBUG manifest only. Add it to
   `android/app/src/main/AndroidManifest.xml` from day one, or every release APK/AAB ships
   with no network access and fails with `SocketException: Failed host lookup ... errno = 7`
   (masquerades as a DNS problem). Verify each release artifact:
   `aapt dump permissions app-release.apk | grep INTERNET`. Also pass the same
   `--dart-define` keys to release builds as to debug, or the app silently ships offline-only.
9. **Size Gradle heap to the machine.** An oversized `org.gradle.jvmargs` (e.g. `-Xmx8G` +
   4G metaspace on 16GB RAM) makes a long-lived daemon crash mid-build with a native OOM
   ("daemon disappeared unexpectedly"). 2GB heap builds a Flutter release fine; set a 30-min
   `org.gradle.daemon.idletimeout` so stale daemons do not linger.
10. **Never surface raw exceptions in UI.** Wrap every network-touching action and map
    exceptions to localized messages (network / bad-credentials / already-registered / weak
    password / bad OTP / rate-limit / generic). Raw `e.toString()` leaks internal URLs and
    reads as broken English to users.

## 7. Security checklist

- RLS enabled on every user table; child tables also verify parent ownership in WITH CHECK.
- Admin RPCs are SECURITY DEFINER with a pinned `search_path` and an internal `is_admin()` gate.
- `revoke execute from anon` on trigger/award/service-only functions (see gotcha #2).
- service_role only in: dashboard, edge runtime env, local AI memory. Never in repo/client.
- `.gitignore` excludes `.env*`, `admin/config.js`, keystores, build dirs.

## 8. Content & i18n discipline

- One content module per surface; per-locale objects; never inline UI strings.
- Arabic MSA; remove colloquialisms (يلا/إزاي/عايز/أكتر/النهاردة/مش → لنبدأ/كيف/تريد/أكثر/اليوم/غير).
- Blog SEO: each article = keyword title + meta description + intro + ~7 H2 sections + FAQ,
  emitting Article + FAQPage JSON-LD. hreflang + canonical + sitemap + robots on every page.

## 9. Docs & memory discipline (so context loss costs nothing)

- Maintain `docs/PROJECT_STATE.md` as the canonical, TOC'd, section-self-contained handoff
  (state, decisions, accounts [public values + secret locations], gotchas, TODO, changelog).
- `README.md` = the easy programmer version (overview + run commands), pointing to PROJECT_STATE.
- Keep the AI auto-memory LEAN: a short pointer to PROJECT_STATE.md + secrets (which cannot go
  in the repo) + critical toolchain paths. Update PROJECT_STATE.md, not the auto-memory.
- If multiple AI sessions touch the project, the on-disk PROJECT_STATE.md is the single source
  of truth; do not edit the same file or run `flutter build` simultaneously.

## 10. Definition of done (per change)

`flutter analyze` clean · tests pass · web build OK · `grep -rl "—" dist` empty · backend
advisor clean (or only by-design warnings) · PROJECT_STATE.md changelog updated · no
service_role in the repo.
