# عوّاد — Awwad

> **رفيقٌ مَن زانَ عُمرَه، وحَسُنَ عملُه**
>
> A mobile + web habit-change platform: break a bad habit or build a new one, using the
> evidence-based Habit Reversal Training (HRT) method with a supportive,
> Islamic-values-aligned tone. Trilingual (Arabic default RTL / English / French).

Non-profit, built entirely on free tiers (zero operational cost except the domain).

> **This README is the programmer quickstart. The single source of truth for project
> state, decisions, conventions and the working methodology is
> [`docs/PROJECT_STATE.md`](docs/PROJECT_STATE.md). A fresh AI session should read that file
> first.**

---

## What the product does

A user picks one or more habits to **break** (smoking, phone, the secret habit, late nights,
anger…) or **build** (prayer on time, Qur'an, salawat, water, exercise…). Each day they open
the app and log that habit: two habit-aware sliders, a "did you slip / did you do it?"
question, mood, optional notes, and (for break habits) HRT checklists tailored to that habit.
Progress feeds streaks, stats charts, and earnable **shields** (badges). The app is
**offline-first**; an optional free account syncs across devices.

## Monorepo layout

```
awwad/
  app/        Flutter app (Android + iOS + Web) — THE PRODUCT
  web/        Astro marketing site (ar/en/fr) — SEO + 30-article blog + legal pages
  admin/      Static admin dashboard (reads Supabase admin RPCs)
  supabase/   migrations/ (SQL + RLS) + functions/ (Edge) + seed.sql
  ops/        keep-alive Action + cloud build script + icon generator
  assets/     icons / splash / store screenshots
  docs/       PROJECT_STATE.md (handoff) + content & tracking guidelines
```

## App architecture (Flutter, `app/lib/`)

- **State:** Riverpod. `core/state/app_state.dart` holds `AppState` (settings, **habits list**,
  entries, badges, fields) + `AppController`. Everything is scoped to the **active habit**.
- **Persistence:** offline-first via `core/data/local_store.dart` (SharedPreferences, JSON).
  Optional cloud via `core/cloud/` (Supabase auth + sync). The app never blocks on the cloud.
- **Catalog:** `core/catalog/habit_catalog.dart` (habits + per-habit metrics, reminder defaults,
  resources), `habit_content.dart` (GENERATED per-habit HRT checklists + scholar-video queries),
  `badge_catalog.dart`, `default_fields.dart`.
- **Notifications:** `core/notifications/` — web-safe facade (`notifications.dart` conditional
  export → real `*_mobile.dart` / no-op `*_stub.dart`). `notif_scheduler.dart` builds the
  schedule from the habits. Local only (no server push yet).
- **Screens:** `features/onboarding/`, `features/auth/` (auth-choice + sign-in/up),
  `features/home/` (Today/Stats/Badges/History/Pomodoro/Settings + HabitSwitcher, AddHabit,
  Habits manager, Profile), `features/pomodoro/`.
- **UI:** `app/theme.dart` (dark theme, iOS "liquid glass" buttons). Trilingual strings are
  inline `Map<String,Map<String,String>>` per screen (NOT ARB) by convention, except the
  gen-l10n base strings in `lib/l10n/app_{ar,en,fr}.arb`.

## Tech stack (all free tier)

| Layer | Service | Notes |
|---|---|---|
| Backend / Auth / DB | **Supabase** (Postgres + RLS + Edge Functions) | LIVE; pauses after 7d idle → keep-alive Action (now secret-free) |
| Site / app-web hosting | **Netlify / Cloudflare Pages** | not deployed yet (blocks the web-app buttons) |
| Push | **Firebase FCM** | not wired (local notifications only for now) |
| keep-alive + CI | **GitHub Actions** | working (public anon key embedded) |

## Prerequisites

- **Flutter** 3.44+ (this machine: `D:\flutter\bin\flutter.bat`, not on PATH).
- **Node.js** 20+ (site + admin).
- Native Android: **JDK 17** (`D:\jdk17`) + **Android SDK** (`D:\Android\Sdk`).
- Backend changes via the Supabase MCP or CLI (`D:\supabase\supabase.exe`).

## Quick start

```bash
# Marketing site
cd web && npm install && npm run build      # -> web/dist (111 pages)

# Flutter app
cd app
flutter pub get
flutter analyze && flutter test             # must be: No issues + 8 tests pass
flutter build web                           # -> app/build/web (offline mode)
flutter run -d chrome                       # local dev (offline)

# Flutter app with cloud (auth + sync):
ops\build-app-cloud.ps1                      # has the public anon key wired

# Android debug APK (needs JAVA_HOME=JDK17, ANDROID_HOME set; see PROJECT_STATE §6)
flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Local preview servers (static): serve `app/build/web` and `web/dist` with any static server,
e.g. `npx serve -s app/build/web -l 8085` and `npx serve web/dist -l 8095`.

## Conventions (do not break)

- **Zero paid dependencies** (free tiers only). Never create a 2nd Supabase project.
- **Trilingual, no hard-coded user strings.** Arabic = Modern Standard Arabic (فصحى), never
  colloquial. **No em-dash (—)** in user-facing text (use a hyphen, comma, or `·`).
- **Islamic-values aligned.** Rulings cite islamweb.net; never issue a fatwa.
- The Supabase **`service_role` key never appears** in the repo or client; only the public
  `anon` key ships.
- **Offline-first:** cloud must never block startup; every feature degrades gracefully offline
  (e.g. the suggested-video card hides when offline).

## Verify any change

`flutter analyze lib` (No issues) · `flutter test` (all pass) · `flutter build web` · for the
site `npm run build` then confirm `grep -r "—" web/dist` is empty. The CanvasKit web preview
cannot screenshot the Flutter canvas (known limitation) — verify via analyze/tests/build and a
real browser.

---

© All rights reserved, [Morad Arafa](https://www.linkedin.com/in/moradarafa/)
