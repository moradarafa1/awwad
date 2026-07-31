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
   - The in-app preview may not screenshot the Flutter canvas (gotcha #4), but real Chrome
     does: use ops/shotgen/capture.mjs to SEE the running app, plus analyze/tests/build.

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

## 0.6 HANDOFF 2026-07-20 (RESUME HERE)

**READ FIRST: an OPEN adhan-30-minutes-late bug from the owner's real phone is at the top of
the Changelog (2026-07-21 entry) with the diagnosis plan. Start there.**

**PHASE 0.5 IS COMPLETE AND LIVE.** docs/MANDATE_PLAN.md: 44 items, 0 open. Site
https://moradarafa1.github.io (139 pages, 39 articles) and app /app/ both live and
byte-verified. Release APK on the owner Desktop (Awwad-1.0.0-final.apk), AAB beside it.
119 tests, analyze clean. Store kit ready: 33 real screenshots (ar/en/fr), listings with
correct URLs, and every console answer pre-written in docs/store/SUBMISSION_GUIDE.md §5.
In-app account deletion ships (it was a hard blocker on BOTH stores).

For the full story of phase 0.5 (what was ordered, what shipped, the defects the reviews
caught incl. my own, and what was deliberately refused) read docs/SESSION_SUMMARY_0.5.md.

**PHASE 0.6 IS THE ACTIVE BRIEF: read docs/PHASE_06_BRIEF.md.** It carries the owner order
of 2026-07-20 verbatim, split into executable items. Summary of what changed:
1. HARD APP-BLOCKING is now CONDITIONALLY approved: build it ONLY where it cannot cause a
   store rejection, decided PER PLATFORM after documented policy research. If it would get
   the app rejected on a store, it is not built for that store.
2. FULL-SCREEN adhan is CANCELLED by the owner. What he wants instead: the adhan SOUND
   firing on time with the app closed and offline, a normal notification in the shade, and
   the safest option that best matches store policy.
3. NOTIFICATION ACTIONS: volume/power keys silence the SOUND ONLY (alarm-clock behaviour);
   a «تم» action stops it and AUTO-LOGS the habit where that fits; a snooze action re-fires
   after 10 or 30 minutes. For prayers, wake-up, and manual-log habit reminders.
4. SEO/GEO/ASO: verify what shipped, and add AI-search (GEO) visibility.
5. DATA LAYER: full acquisition/activation/retention event coverage across site, web app and
   app, GA4/MMP-compatible naming, ready for GTM + Adjust/AppsFlyer later.
6. FONTS from https://wabl.sa (see the owner screenshot of «أدوار وبل 11»): identify BOTH
   fonts with certainty, VERIFY THE LICENCE before use, then wire heading + body roles with
   a proper type scale (no clipped or undersized text at 320dp and 1.3x).
7. Apply any Claude design/taste skill that improves the visual identity.
8. Run every test including adversarial, and INSTALL THE OFFICIAL ANDROID EMULATOR to
   exercise the app for real. This closes the standing caveat: notification tap routing,
   DND bypass and the widget quick-log are verified by tests and reasoning, NOT on hardware.

**READY-TO-SHIP STATE, 2026-07-20 end of session. Everything below is BUILT AND VERIFIED.
The only work left is the iOS build (needs a Mac) and the store uploads themselves (owner).**
- Android artefacts on the owner Desktop (`C:\Users\morad\OneDrive\Desktop`, OneDrive-synced,
  NOT on D:): `Awwad-1.0.0-final.apk` (65 MB) and `Awwad-1.0.0-store.aab` (64 MB), both built
  from this commit. Verified inside BOTH: the owner's adhan mp3 at 2188 KB and `raw/adhan`
  present (gotcha #11 regression check), 8 bundled font files, the font families registered,
  INTERNET + POST_NOTIFICATIONS.
  NOTE: an older `Awwad-1.0.0-notifications-fixed.apk` (60 MB) is also on the Desktop from a
  previous session. It is STALE. Do not upload it.
  NOTE (2026-07-20): the AAB is also mirrored into the project at
  `D:\Claude\awwad\release\Awwad-1.0.0-store.aab` (owner wanted a copy on the D: partition,
  hash-verified identical). This `release/` folder is gitignore-worthy (large binary); if it
  ever needs re-syncing after a rebuild, just re-copy from the Desktop path above.
- Store screenshots REGENERATED from this build: 10 per locale, ar/en/fr, 1125x2436.
- Store listings verified: `node ops/verify-listings.mjs` passes 20/20 fields.
- Site: `npm --prefix web run build` then `node ops/verify-dist.mjs` passes.
- App: analyze clean, 165/165 tests.
- Marketing kit v2 (50 posts) on the Desktop and in docs/marketing/.
- NOTE: web/dist currently holds a PRODUCTION build (deploy-ready). To go back to local
  review, rebuild with `PUBLIC_WEB_APP_URL=http://localhost:8099/ npm --prefix web run build`.
- **NOT deployed. Nothing was pushed. Both are owner decisions.**
- STILL UNVERIFIED ON HARDWARE: the adhan firing with the app closed, the power-button
  silencing, and the «تم» / «أمهلني» action buttons. The emulator system image failed to
  download twice (the `emulator` package installed, 973 MB, but
  `system-images;android-35;google_apis;x86_64` left only an empty `.installer` stub).
  Diagnose that before claiming any of those work.

**LISTENING WIRD (owner brief 2026-07-20, DONE):** for habits completed by listening
(daily_quran, hadith_wird, listening_wird, surah_kahf, adhkar, salawat, dua - the set is
kListeningHabits in core/models/wird_config.dart):
- The wird card is the FIRST thing on the habit page, above the motivation line. The point
  of opening that screen is to listen, so the listen button leads.
- Per-habit WirdConfig: minutes per session (FLOOR 5, the owner rejected the old hardcoded
  120s as too short), scheduled hours, autoPlay, sessionsPerDay.
- ONE completed session logs the day, no matter how many the user targets.
- The players auto-log against the USER'S configured length, read from the habit.
- Wird hours fold into Habit.times, so the existing scheduling path picks them up and there
  is exactly ONE place that decides when a habit notifies. No separate scheduler.
- AUDIO: core/audio/audio_session_config.dart. audio_session was a dependency for months
  with ZERO call sites, so the app never took audio focus. That is a real cause of the
  quiet playback the owner reported, alongside the emulator being quiet. Configured for
  speech-over-media with focus gain and ducking.
- AUTO-PLAY: DONE. The wird reminder fires at the scheduled hour; tapping it routes straight
  into the player which starts playing on open (autoStart). Deliberately NOT unattended
  background audio: Android restricts starting playback from the background, and sound with
  no visible cause is hostile and store-risky. The reminder is the cause, the tap is the
  consent. 12 tests in test/wird_config_test.dart.
- VOLUME, INVESTIGATED AND CLOSED on the app side (2026-07-20). The owner reported very low
  playback. Two causes, and only one was ours:
  1. OURS, FIXED: audio_session had been a dependency for months with ZERO call sites, so the
     app never requested audio focus. Fixed in core/audio/audio_session_config.dart.
  2. NOT OURS: the emulator media volume was at 5/15, i.e. one third.
  PROVEN from the system audio dump while playing, not inferred:
     pack: com.awwad.awwad -- gain: GAIN -- attr: usage=USAGE_MEDIA
     AudioPlaybackConfiguration state:started usage=USAGE_MEDIA
       content=CONTENT_TYPE_MUSIC sampleRate=44100
  So the app takes focus and plays on the MEDIA stream (the loud one, the one the volume
  rocker controls). There is nothing further to fix in the app.
  Reproduce with: adb shell dumpsys audio | grep awwad   (while audio is playing).
  VOLUME CONFIRMED FIXED by the owner 2026-07-20 ("الصوت بقا عالي").
  STUTTERING, reported next, diagnosed and answered: the emulator, not the app.
    Evidence: logcat repeats "DefaultAudioSink: Spurious audio timestamp (frame position
    mismatch)" on [emu64xa, sdk_gphone64_x86_64], which is the emulated audio HAL
    reporting an inconsistent clock. Guest CPU was 377/400 IDLE, so it was NOT CPU
    starvation (an earlier guess of mine that the data disproved). Guest RAM WAS at 94%
    with swap in use, which contributes.
    Fixed anyway, because it helps REAL devices on weak mobile data:
    core/audio/stream_player.dart raises the streaming buffers (3s to start, 8s after a
    rebuffer, 30-90s ahead) for both the Qur'an and radio players. Both sources stream
    over the network and the defaults are tuned for short local media.
    ops/emulator.ps1 also switched to -gpu host and -memory 4096.
  REMAINING, OWNER-ONLY: confirm on a real handset. No emulator can answer that.

**PROGRESS 2026-07-20 round 2:**
- TYPE SYSTEM SETTLED: Tajawal for main headings, IBM Plex Sans Arabic for everything else,
  on site + web app + phone app. See §7. The round-1 claim that wabl uses one family was
  right about their WEBSITE and wrong about their BRAND ARTWORK; both faces are now used, by
  role, exactly as the owner asked.
- GUESTS SKIP THE ONBOARDING SURVEY (§7).
- **OWNER IS REVIEWING THE WEB APP FIRST, then approves, then the phone builds ship.** He
  asked explicitly for that order. Local review servers: site on :8090 (web/dist), web app on
  :8099 (app/build/web, built WITHOUT --base-href so it serves at root). NOTHING IS DEPLOYED.
- **PRE-DEPLOY GATE ADDED: run `node ops/verify-dist.mjs` BEFORE every deploy.** It fails on
  a review build (any `localhost` in dist), on any em-dash in a page, on any third-party host
  reference, on a missing llms.txt / robots.txt / sitemap, and on missing self-hosted fonts.
  Verified in BOTH directions: it fails the review build and passes the production build.
- MARKETING KIT v2 SHIPPED (owner request 2026-07-20): docs/marketing/Awwad_Marketing_Kit_v2_50_posts.pdf,
  23 pages, 50 posts across 10 NEW angle families, all built on features that shipped AFTER the
  first kit (2026-07-14). The first kit is untouched, as instructed. Regenerate with
  node ops/marketing/build_pdf_v2.mjs ; the copy lives in ops/marketing/posts_v2.js so it can
  be edited without touching layout. The builder ASSERTS 50 posts, no orphan angle and no
  em-dash, so a short or malformed deck fails loudly instead of shipping quietly. Every CTA
  points at the WEB version because the stores are not live yet. Also copied to the Desktop.
- **ITEM 2 (ADHAN) DECISION MADE AND DOCUMENTED. The brief asked for a reasoned choice between
  a normal notification with sound and a heads-up / full-screen popup. THE ANSWER IS: KEEP THE
  CURRENT DESIGN, AND DO NOT ADD FULL-SCREEN INTENT.** Reasons, in order of weight:
  1. Since Android 14, `USE_FULL_SCREEN_INTENT` is auto-granted ONLY to apps whose core
     function is calling or alarms. Everything else must request it and justify it at review.
     A habit app declaring it is a live rejection risk for the whole app, against phase 0.6's
     first rule ("do not ship what causes a store rejection").
  2. The owner CANCELLED the full-screen adhan himself on 2026-07-20. Adding the permission
     back would buy a rejection risk for a feature nobody asked for.
  3. The current design already delivers what he actually asked for. The adhan channel is
     created natively in MainActivity.kt with `setBypassDnd(true)` and, crucially,
     `AudioAttributes.USAGE_ALARM`. Alarm usage is why the sound is loud, survives Do Not
     Disturb, and is governed by the ALARM volume rather than the notification volume.
  **Item 2.1 (volume keys silence the SOUND only) is largely satisfied ALREADY by
  USAGE_ALARM**: the volume keys act on the alarm stream during playback, and nothing about
  pressing them dismisses the notification or records anything, which is exactly the
  requirement. HONEST CAVEAT: the POWER button silencing is standard for system alarms and
  incoming calls, NOT guaranteed for a notification sound. Needs hardware verification (item
  7) before it is claimed as done.
  **ITEM 2 NOTIFICATION ACTIONS: BUILT 2026-07-20 round 4.** All of (a)-(e) below are done;
  full design notes are in §7 under «Notification ACTION buttons». Correction to (d) as it
  was written here: rescheduling THE SAME id is a BUG, not the design. Habit reminders repeat
  daily via matchDateTimeComponents.time, so reusing the id overwrites the repeat and destroys
  the user's daily reminder. Snooze uses a derived id (+100000) instead; a test locks it.
  (e) turned out to be the EASY part, not the hard one: `widget_sync.dart` had already solved
  the no-Riverpod-in-a-background-isolate problem for the home-screen widget, so the action
  handler reuses that exact pattern (LocalStore + SharedPreferences, UI reconciles after).
  **NOT VERIFIED ON HARDWARE. No button has ever been pressed on a device.** Analyze clean,
  165/165 tests, release APK compiles. Verifying it is item 7 (emulator), and until then
  nothing here should be described to the owner as working.
- ITEM 4 (DATA LAYER) AUDITED, and the audit found real defects. The brief demanded that a
  documented event must actually be SENT. Comparing every `track()` call in lib/ against
  docs/tracking-plan.md found:
  (a) `sos_slipped` was fired from sos_screen but was NOT in the analytics allow-list, so the
      assert would have CRASHED a debug build the moment a user tapped «تعثرت». Release
      strips asserts, which is why it survived. Fixed, and `test/analytics_allowlist_test.dart`
      now reads the source and fails if any fired event is missing from the list. Verified the
      test actually catches it by removing the entry and watching it fail.
  (b) `notification_opened` and `account_deletion_requested` were documented but never fired.
      Both now fire for real. `notification_opened` is the ONLY retention signal the app has
      (reminder sent vs reminder brought someone back) and is tracked in `_routeTap`, before
      the UI is ready, so a cold-start tap is not lost. It sends only the payload KIND
      (prayer/habit/report), never an id.
  (c) `survey_shown`, `survey_skipped`, `device_trusted`, `streak_milestone` are documented but
      genuinely do not exist. Marked struck-through in the plan with the reason, instead of
      being left to look implemented.
  NOTE: a first pass at this audit was WRONG because the grep was line-based and `track(` is
  sometimes split across two lines. Use a multiline match.
- ITEM 3 (GEO / AI-search) STARTED: `/llms.txt` now ships, GENERATED at build time by
  `web/src/pages/llms.txt.js` from site.js + posts.js so it cannot drift. robots.txt points
  at it. Still to do for item 3: verify the round-3/8 SEO work is still live, and the ASO
  pass on both store listings.
- LOCAL REVIEW TRAP FIXED: the site's «جرّب إصدار الويب» button points at WEB_APP_URL,
  which is the LIVE deployed app. Reviewing a local site therefore sent the owner to
  yesterday's code and he reported a bug that did not exist in the new build. WEB_APP_URL is
  now overridable:
  `PUBLIC_WEB_APP_URL=http://localhost:8099/ npm --prefix web run build`
  **web/dist currently holds a REVIEW build with the localhost URL baked in. Rebuild without
  the override before ANY deploy.**
- **ICONS DONE (2026-07-20).** Emoji replaced by **Material Symbols Rounded** on both app and
  site. They ship inside Flutter (Apache 2.0): no package, no network, no licence question,
  and the icon font is tree-shaken, so 40 habit icons cost 7 KB (16 KB -> 23 KB).
  The catalog `icon:` field is DATA (mirrored in seed.sql and the live DB) and is UNTOUCHED.
  The vector icon is a presentation map keyed by habit key in
  `core/catalog/habit_icons.dart`, with the stored emoji as the fallback for custom habits.
  Use the `HabitIcon` widget, never a raw `Text(h.icon)`. Locked by `habit_icons_test.dart`,
  which fails if a new catalog habit has no icon.
  Site: same family, INLINED as SVG in `web/src/components/Icon.astro` so the page stays
  100% first-party. The path data is copied verbatim from the source SVGs; do NOT hand-write
  it. Material Symbols use `viewBox="0 -960 960 960"`, not `0 0 24 24`.
  STILL EMOJI, deliberately not converted yet: the BADGE icons (`badge_catalog.dart`, drawn in
  badges_screen / badge_celebration / profile_screen) and a few decorative glyphs (💡 in tips,
  📅 in history, 📊 in stats, ✅ in the radio player).

**PROGRESS 2026-07-20 round 1:**
- **Item 5 FONTS: DONE and verified.** wabl.sa uses ONE family, not two: **IBM Plex Sans
  Arabic**, big title at w700 and subline at w400 (read off the live computed styles of
  /projects/wabl-11-nada: h1 = 48px/700, p = 18px/400; `document.fonts` shows Beiruti and
  Tajawal never even download - Beiruti is scoped to their internal `.crm-scope` and Tajawal
  is only a fallback). SIL OFL 1.1, free for commercial use and app embedding, so nothing to
  buy. Wired into app + site + a real type scale. Details in §7. Also fixed two things found
  on the way: `google_fonts` fetched the face at runtime (offline-first breach) and the
  Flutter web engine pulled Roboto from fonts.gstatic.com at boot (third-party request).
- **Item 1 APP BLOCKING: policy research DONE, verdicts + sources written into §12 0c(3).**
  Android = CONDITIONAL and buildable (6 hard conditions, of which the killer is: the user
  must always be able to uninstall, so no true strict mode). iOS = CONDITIONAL but gated on
  an Apple entitlement that needs the $99 account first, so not buildable this round.
- **NOT started yet: items 2, 3, 4, 6, 7.** Next session starts at item 2 (adhan in the
  background + notification actions), then 3, 4, 6, 7 in order.
  (Superseded by round 4: item 2 is now BUILT but unverified on hardware. **NEXT STEP =
  item 7, install the official Android emulator**, because item 2, the adhan timing, the
  power-button silencing, tap routing, DND bypass and the widget quick-log are ALL now
  blocked on the same thing: nothing has ever run on a device. After item 7, items 3 and 6.)

**STILL OWNER-GATED (money or accounts only):** Play Console ($25), Apple Developer ($99 +
a Mac), the submissions themselves, and the custom domain. The «غض البصر» habit also still
needs his approval (catalog + seed + live DB sync together). NEW: iOS app-blocking cannot
start until the Apple account exists and the family-controls entitlement is granted.

**MAC-GATED:** docs/IOS_PARITY_SETUP.md. The WidgetKit files and adhan sound exist in the
repo but belong to no Xcode target, so an ipa built today silently omits them.

**TOOLING:** ops/shotgen/capture.mjs regenerates store screenshots from the live build in
real Chrome (GOTCHA #4 IS OBSOLETE, the canvas screenshots fine outside the Electron
preview). ops/shotgen/verify_videos.mjs must gate ANY new scholar video. Two traps that cost
real time: a --base-href /app/ build only renders when SERVED under /app/, and never edit
Dart while a Gradle build is running.

## 0.5-OLD HANDOFF 2026-07-18 (superseded - kept for the round's technical details)

**STATE: all code below is COMMITTED in this commit, verified (analyze clean, 75/75 tests),
but the FINAL build/deploy round was still running when the session ended.**
(Resolution 2026-07-18 round 2: the deploy HAD completed - Pages 324b61d live + byte-verified;
APK/AAB + Desktop copy done; the per-app open-count request below is now SHIPPED.)

Done since the last deploy (Pages commit a437ac6): (1) ADHAN SOUND on the 5 prayer
notifications - channel `awwad_adhan_v1`, sound `android/app/src/main/res/raw/adhan.mp3`
which IS THE OWNER'S OWN FILE (317311.mp3, his explicit instruction «لا تستخدم غيره مطلقاً» -
NEVER replace it); toggle = PrayerConfig.adhanSound + switch in prayer settings; adhan plays
only on the actual prayer time, never the 5-min pre-alert (prayer_scheduler branches to
scheduleAdhan). (2) HADITH/SUNNAH LIVE RADIO: habit `hadith_wird` (synced catalog + seed +
LIVE DB = 40 rows) + features/radio/radio_player_screen.dart, stations in
core/radio/radio_stations.dart (verified https: saheh-bokharee, saheh-muslim, riyad,
fi_zilal_alsiyra + quran: radiojar 0tpy1h0kxtzuv, salma, tafseer). (3) AUTO-LOG AFTER
LISTENING: AppController.quickLogHabit(habitId) (idempotent, keeps active habit) fired after
120s of real listening by BOTH the radio player and the Quran player (QuranPlayerScreen now
takes habitId; daily_log resource cards pass habit?.id). Tests: radio_autolog_test.dart.

**EXECUTE NEXT, in order:**
1. FINISH THE DELIVERY: run the §6 builds (web --base-href /app/ + apk + aab, standard
   dart-defines), verify `aapt dump` shows the receivers + POST_NOTIFICATIONS, copy APK to
   C:/Users/morad/OneDrive/Desktop/Awwad-1.0.0-final.apk, refresh the Pages clone (in THIS
   session's scratchpad or re-clone moradarafa1.github.io) with web/dist at root + app build
   at /app/ + 404.html copy, commit+push Pages, byte-verify live main.dart.js, push source.
2. OWNER REQUEST IN FLIGHT (screenshot provided, NOT yet implemented): show PER-APP OPEN
   COUNT next to the usage time in the usage screen. Plan: in MainActivity.kt `todayUsage`
   (lines ~67-105, currently queryAndAggregateUsageStats) ALSO iterate
   `usm.queryEvents(start, end)` counting Event.ACTIVITY_RESUMED (fallback
   MOVE_TO_FOREGROUND < API 29) per package into an `opens` map; add `'opens': n` to each
   row map. Dart: core/platform/usage_stats.dart AppUsage gains `opens` (default 0).
   UI: features/phone/usage_screen.dart per-app row subtitle appends «N مرة فتح» trilingual;
   keep fail-open. Consider counting opens in UsageLimitWorker too (not required).
3. Then continue §12 backlog (0c phase C app-blocking is OWNER-GATED; home widget; share
   image; store submission is owner action).

NEW GOTCHA #11 (hit 2026-07-18): release resource SHRINKING strips res/raw sounds that are only referenced by name at runtime - the adhan silently vanished from the APK (and concurrent gradle builds on one build dir corrupt resource merging; never run two). Fix: android/app/src/main/res/raw/keep.xml with tools:keep="@raw/adhan" - verify after EVERY release build: aapt2 dump resources app-release.apk | grep raw/adhan (must be 1) + unzip -l shows a ~2.24MB res/*.mp3. APK/AAB rebuilt WITH the owner adhan verified inside; APK copied to Desktop.

Machine quirk: OS clock EDT, owner is Cairo (UTC+3). qurango saheh-muslim stream returned
intermittent 500s when probed - the player already shows a friendly error; consider a retry.

## 0.5-OLD HANDOFF 2026-07-14 round 2 (superseded)

**Done this round (committed AND deployed):** skip quotas wired to the UI (both entry
points) + rolling-window tests; TRACKING data layer live (app flushes `analytics_events` on
open + after save, standard params, allow-list completed, anon INSERT verified against the
live DB; site GTM scaffold behind `GTM_ID` in site.js, empty = no third-party, + `cta_click`
dataLayer events; tracking-plan.md now carries the GA4/MMP mapping + MMP owner-gated note);
BUTTON/LAYOUT OVERFLOW ROUND (13 real defects fixed, incl. a hard "infinite width" layout
crash on the Pomodoro screen in EVERY locale) with `test/layout_overflow_test.dart` locking
them down (pumps screens at 320dp + 1.3x text scale in ar/en/fr); LOGO fixed to be the
owner's plant image itself (see §11 - never redraw it again).

**DEPLOYED 2026-07-14 (Pages commit `8ab5244`, source `4561c9b`).** Site + app are LIVE at
https://moradarafa1.github.io and /app/ with the plant logo, reworked signup, truce nav,
history-in-stats, tracking and every layout fix. Verified live: favicon byte-matches the local
build, `cta_click` is wired, GTM is absent (no cookies, as designed), the app boots and the
analytics flush REACHED the live DB (`app_opened` rows with platform/app_version/locale; test
rows deleted afterwards). Browser walkthrough passed: language -> guest -> onboarding -> habit
pick -> Today; signup form order/asterisks/toasts/email-regex/eye-toggle all behave; the truce
tab opens SOS directly with a single habit.

**DONE 2026-07-17 round 2: 0d PHASE A (prayer-times engine) SHIPPED.** core/prayer/
prayer_engine.dart (pure, tested: adhan offline calc, regional method by country, per-prayer
manual offsets, cities.json nearest-city + country/city picker data) + prayer_scheduler.dart
(2-day window ids 4000-4299, mains + optional 5-min pre-alerts + adhkar fajr+30/asr+30,
trilingual MSA copy, rebuilt on every app open from home_shell) + features/prayer/
prayer_settings_screen.dart (GPS via geolocator with graceful fallback, searchable country ->
city sheets, tap-to-edit each prayer time, pre-alert toggle; Settings tile gated on religious
content) + location permissions (Android manifest + iOS plist). notifications layer gained
scheduleAt/cancelIdRange/scheduleWeekly (weekly = ready for Kahf in A2). 5 engine tests.

**DONE same round: Arabic-ux lens (wf_e166f7a7-0eb) fixed.** MAJOR consent-integrity defect:
the app recorded and SYNCED survey consent=true while the research notice (l10n surveyConsent)
was never rendered anywhere - now the notice renders in the survey step and consent is true
only when the user actually answered an optional field. Also fixed: journey-cards double colon
+ Arabic number grammar («بعد N من الأيام»), EN/FR syncLater promised a Settings sync button
that does not exist (aligned with the auto-retry truth), «خفّت الإضاءة» -> «خفِّف», catalog
wording («إدمان الموبايل» -> «إدمان الهاتف», «بدل ما تأجّل» -> «بدلاً من التأجيل», «الإثنين» ->
«الاثنين») synced in catalog + seed.sql + LIVE DB. LOGGED, NOT YET FIXED (minors):
(a) habit_content.dart FR strings stripped of accents across ~8 break habits (quit_smoking,
nail_biting, hair_pulling, skin_picking, excessive_gaming, procrastination, oversleeping,
caffeine_excess) - restore accents in one sweep; (b) history cards use break vocabulary
(نظيف/تعثّر) for BUILD habits - branch on track like month_heatmap does.

**EXECUTE NEXT, in order:**
1. The two logged Arabic minors above (FR accents sweep + history build-track wording).
2. TODO 0d Phase A2: Kahf habit (weekly Friday dhuhr+1h via the new scheduleWeekly) +
   «كسر الإباحية» habit (opens DNS shield on selection) + wire scholar_videos.json into the
   suggestions card for religious habits. Sync catalog + seed + live DB together.
3. 0d Phase B (Quran audio wird, just_audio + reciters.json) then Phase C (monthly report).
4. Adhan SOUND on prayer notifications still pending an owner-provided/licensed clip (see 0d
   spec; custom notification channel sound once the file exists).

## 0.5-OLD HANDOFF 2026-07-16 (context overflow — superseded, kept for the file map)

**State committed in this very commit (built earlier but NOT yet deployed to Pages):**
seedling logo rolled out everywhere (masters assets/icons/*.svg + all derived/launcher/splash/site/store assets); signup form reworked (order: name* -> email* -> password* -> gender* -> optional extras LAST; starred labels; missing-field toasts + email regex on signup/sign-in/reset); password EYE toggles (auth screen ×2 + profile change-password via StatefulBuilder); Settings ACCOUNT CARD moved under Language, reactive via `SupabaseService.authRevision` (ValueNotifier bumped on init + onAuthStateChange) — signed-in shows «حسابك» + email -> ProfileScreen, signed-out shows create/sign-in (fixes "asks to sign in although logged in"); RESET flow split into TWO steps (code-only -> verify -> new-password-only; `_recoveryVerified` gates fields/labels/resend); savings calculator = cost field ONLY (minutes removed everywhere); reminder labels renamed «وقت التذكير بتسجيل تقدمك اليومي» (arb ×3 + add_habit + habits_screen); BOTTOM NAV: History tab REPLACED by «هُدنة» ACTION (danger shield icon; index 3 intercepted in home_shell -> if 0 break habits: hint toast; if 1: straight to SOS; if >1: bottom-sheet picker «أي عادة تحتاج هُدنة الآن؟» -> `SosScreen(habitId:)` (new param resolves habit over active)); HISTORY merged into Stats as sub-tab (`statsSubTabProvider`, segmented toggle الإحصائيات|السجل, embeddable `HistoryList` in history_screen.dart, skip days render with ➖ chip); AppState SKIP QUOTAS added — LOGIC ONLY, **NOT WIRED TO UI YET**: kSkipsPerWeek=2 (rolling 7d), kSkipsPerMonth=4 (rolling 30d), anchored at the habit's FIRST-ever skip, renewing per whole period (`weeklySkipUsage`/`monthlySkipUsage`/`skipBlockedBy()` -> null|'week'|'month').

**EXECUTE NEXT, in order:**
1. **Wire skip quotas**: in daily_log_screen, `_confirmSkipToday` AND the skip option in `_repairSheet` must first check `skipBlockedBy()`; if 'week' -> AlertDialog «استنفدت فرص الإعفاء لهذا الأسبوع (المسموح ٢ أسبوعياً و٤ شهرياً). عُد بعد تجدد الفرص.» / 'month' variant; ar/en/fr, MSA, no em-dash. Also show remaining counts inside the skip confirm dialog body. Add unit tests for the rolling-window math (anchor renewal, week exhausted, month exhausted). analyze + test.
2. **Button/label overflow audit**: resume workflow `C:\Users\morad\.claude\projects\D--Claude\7ca5cbb3-5954-42b6-ba7c-4e02b2400a7d\workflows\scripts\awwad-button-text-audit-wf_18312458-072.js` (resumeFromRunId wf_18312458-072; it died on session limit) or re-launch equivalent (audit every FilledButton/TextButton/chip/nav label for overflow at ar/en/fr + big font scale; fix with maxLines/ellipsis/size tweaks). Apply confirmed fixes. The new long reminder label + «تأكيد الرمز وإنشاء الحساب» + هُدنة nav labels are prime suspects.
3. **TRACKING DATA LAYER (owner request)**: (a) APP: AnalyticsService only buffers locally — implement flush to Supabase `analytics_events` (schema from migration 0004; anon INSERT policy — VERIFY policy exists via get_advisors/execute_sql first) batching on app open + after save, fail-open; enrich every event with standard params {platform, app_version:'1.0.0', locale, and habit_track/catalog_key where relevant}; extend the allow-list accordingly + update docs/tracking-plan.md with a GA4/MMP-compatible name mapping table. (b) WEB: GTM scaffold in web/src/layouts/Base.astro gated by a `GTM_ID` const in site.js (empty string = render nothing) + dataLayer.push custom events on the download/web-app CTA clicks (event:'cta_click', cta:'download|webapp|store', locale) — the CTA code lives in [...path].astro/Base scripts; keep 0 em-dashes; note in docs that GA/GTM cookies apply once owner sets GTM_ID. (c) MMP (AppsFlyer/Adjust) needs an owner account + SDK — document as owner-gated P-item, do NOT add SDK now.
4. **Religious data assets**: app/assets/data/{cities,reciters,scholar_videos}.json exist (306/50/25) but are NOT registered in pubspec `assets:` — register when starting TODO 0d Phase A (prayer engine), not before (unused-asset bloat otherwise is fine either way).
5. **Finish**: ONE full build (flutter web --base-href /app/ + apk + aab with the standard --dart-defines from §6) + `npm run build` in web/ + deploy Pages (site dist at root KEEPING app/ dir + new app build at /app/ + 404.html copy; repo clone lives at the OLD session scratchpad — re-clone if gone: github.com/moradarafa1/moradarafa1.github.io) + byte-match verify + push source + changelog entry. NOTE: last DEPLOYED Pages commit is the tab-titles round — the logo and everything above is NOT live yet.

Machine quirk: OS clock shows EDT but the owner is in Cairo (UTC+3). Old background-build IDs from the previous session are dead.

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

### App (iOS — requires a Mac with Xcode; repo is READY, no code changes needed)
```bash
git clone https://github.com/moradarafa1/awwad.git && cd awwad/app
flutter pub get
flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://kdczbzzjezyhfxgpegqc.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key from ops/build-app-cloud.ps1>
# Bundle id com.awwad.awwad, display name «عوّاد», ar/en/fr locales and the
# encryption-exempt flag are already configured in app/ios/. Signing needs an
# Apple Developer account selected in Xcode (Runner target). Note: the iOS
# side of the native channels (dns_shield/usage_stats) is not implemented -
# the Dart layer fails open, so those two screens show manual guidance on iOS.
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
- **First open:** `AuthChoiceScreen` (create account / sign in / continue as guest = offline on
  device); also requests OS notification permission directly (no extra dialog). Gated by
  `settings.authChoiceMade`.
- **Auth flows (since 2026-07-11):** sign-up = `auth.signUp` + emailed Arabic verification code
  -> `verifyOTP(type: signup)`; sign-in = password (+ «نسيت كلمة المرور؟» -> emailed code ->
  `verifyOTP(type: recovery)` -> new password). All emails via Brevo SMTP. No passwordless login.
- **Onboarding:** welcome+language → [survey, SIGNED-IN ONLY] → track → habit pick (36-habit
  catalog + custom, hides already-owned) → setup (name/why + **multi-time
  `ReminderTimesPicker`**).
  **GUESTS SKIP THE SURVEY** (owner instruction 2026-07-20). It collects account data (gender,
  age, country, research consent); with no account there is nothing to attach it to, so it is
  a pure barrier. Implemented as a dynamic `_steps` list in `onboarding_flow.dart` keyed on
  `SupabaseService.signedIn`, resolved once on entry so the list cannot change under the user.
  The progress bar, the Next/Start label and the per-step validation all derive from that list,
  so a guest sees 3 segments, not 4. Locked by `test/onboarding_guest_test.dart`.
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
- **Notification ACTION buttons (phase 0.6 item 2, since 2026-07-20):**
  `core/notifications/notification_actions.dart`. Habit reminders carry «تم» + «أمهلني»;
  prayer + adhan alerts carry «أمهلني» only. Snooze length = 10 or 30 min, a SegmentedButton
  in Settings, stored as `AppSettings.snoozeMinutes` (persisted because the handler reads it
  from DISK, not memory). Four things that are load-bearing and easy to break:
  1. `notificationActionBackgroundHandler` is TOP-LEVEL + `@pragma('vm:entry-point')` and is
     passed to `onDidReceiveBackgroundNotificationResponse`. An action tap does NOT launch the
     app, so without it every button is a silent no-op whenever the app is closed, which is
     the normal case for a reminder. The pragma is what stops the DART tree shaker (not R8)
     from removing it in release.
  2. The handler runs in an isolate with NO Riverpod: it writes through `LocalStore` +
     SharedPreferences, exactly like the widget quick-log (`widget_sync.dart`), and the UI
     reconciles via `refreshFromStore()`. A `ref.read` there would silently do nothing.
  3. **Snooze re-arms under a DERIVED id (`+kSnoozeIdOffset`, 100000), never the original.**
     Habit reminders repeat daily via `matchDateTimeComponents.time`; rescheduling their own
     id would overwrite the repeat and destroy the user's daily reminder. Locked by a test.
  4. Foreground taps go through the SAME code path but with `initializePlugin: false`. A
     second `initialize()` in the live isolate re-registers on the platform channel and drops
     `onDidReceiveNotificationResponse`, killing tap routing for the rest of the session.
  Prayer payloads are now `prayer:<key>` (was bare `prayer`) so a snooze can NAME the prayer;
  tap routing accepts both, since a pre-update notification can still sit in the OS queue.
  A snoozed prayer gets its own copy («تذكير: صلاة المغرب»), NOT a replay of «حان وقت صلاة»,
  which would be a false statement ten minutes late.
  «تم» auto-logs ONLY on a habit reminder. On a prayer alert it is deliberately absent:
  one of five prayers is not the daily pray-on-time habit, and logging it off the Fajr alert
  would credit a day with four prayers still ahead of it.
  **NOT VERIFIED ON HARDWARE.** Analyze clean, 165 tests green, release APK compiles, but no
  button has ever been pressed on a device. That is item 7 (emulator).
- **Phone-usage toolkit (Android only, fail-open elsewhere):** «استخدام الهاتف» screen shows
  per-app screen time + per-app OPEN COUNTS (queryEvents ACTIVITY_RESUMED, consecutive-dedup;
  since 2026-07-18) + per-app daily limits; background `UsageLimitWorker` warns over-budget
  apps every 15 min even with Awwad closed. Hard blocking = owner-gated (§12 0c phase C).
- **Registration:** name/email/password, gender MANDATORY, optional country/birth_date/WhatsApp
  (Arabic/Persian digits normalized) + research-only notice. Writes to Supabase profiles.
- **UI:** dark theme, **iOS "liquid glass" translucent buttons** (`theme.dart`). Verified:
  analyze clean, 8 tests, web build OK.
- **TYPE (since 2026-07-20, phase 0.6 item 5): TWO families, by role.**
  - `kHeadingFamily` = **Tajawal** (Boutros Fonts, SIL OFL 1.1) for MAIN HEADINGS ONLY.
  - `kFontFamily` = **IBM Plex Sans Arabic** (SIL OFL 1.1) for everything else.
  Both BUNDLED at `app/assets/fonts/` with their OFL copies. Owner instruction: main headings
  match the wabl brand face, all other text stays on the Awwad face.
  **How Tajawal was identified (do not redo this the hard way):** the owner's reference is the
  «فلل وبل 13» cover image, and that title is BAKED INTO THE PHOTO, not web text, so it cannot
  be read from CSS (that is why the numeral is italic). It was matched by rendering the same
  phrase in every free Arabic candidate and comparing letterforms; Tajawal won, corroborated by
  wabl.sa loading Tajawal in its own font link while never rendering it.
  CAUTION: the site's own body/heading CSS really is IBM Plex Sans Arabic at w700/w400. The
  brand artwork and the website use DIFFERENT faces. Both facts are true.
  **The app does NOT use the Material text-theme roles** (zero uses of headlineSmall/titleLarge
  across lib/features); every widget writes its own TextStyle. So the display family is applied
  through `headingStyle()` in `theme.dart`, and the heading sites were converted from the two
  house idioms (`fontSize + w900 + AppColors.heading`, and the onboarding `fontSize: 20 + w800`).
  Tajawal stops at ExtraBold 800, so w900 maps to w800 to avoid synthetic bolding.
  Scale in `_awwadTextTheme`: display/headline w700 in Tajawal, titles w700, body w400, labels
  w500, letterSpacing 0 EVERYWHERE (tracking breaks cursive Arabic), floor size 12, display
  capped at 40 (Material's 57 clips on a 320dp Arabic screen).
  Locked by `test/type_scale_test.dart`, which asserts the display face never leaks into body
  or label roles.
  `google_fonts` is REMOVED: it fetched Cairo over HTTP on first launch, so a first run with
  no connection fell back to the platform font, breaking offline-first.
  `pubspec` also registers the same faces under the family name **`Roboto`** on purpose: the
  Flutter WEB engine downloads Roboto from fonts.gstatic.com at boot unless that name is
  already registered. Verified over the resource log before/after: the gstatic request is gone
  and every font request is now first-party.

### Website (Astro) — redesigned + MSA + blog
- Distinctive design (single teal accent #2dd4bf, ambient gradient, hover-lift cards, transform-only reveal). 139 pages. 0 em-dashes site-wide.
- **TYPE (since 2026-07-20):** same single family as the app, **IBM Plex Sans Arabic**,
  self-hosted woff2 in `web/public/fonts/` (12 files = 4 weights x arabic/latin/latin-ext,
  284 KB total, but unicode-range means a French page never downloads the Arabic file).
  Headings w700, body w400, letter-spacing 0. `@font-face` block is GENERATED, never hand
  typed: `node ops/fontgen/fetch_fonts.mjs <css> web/public/fonts` writes
  `ops/fontface.generated.css`; see `ops/fontgen/README.md`.
  Cairo and Salma Arabic are retired (Salma was fine legally, OFL 1.1 per its own name table;
  the OTFs are parked at `assets/brand/fonts/` in case the wordmark wants it back).
  Verified in real Chrome: zero third-party requests, zero clipped text at a 320px viewport.
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
  admin.createUser. **RETIRED from the client on 2026-07-11** (Brevo SMTP landed; the app now
  uses plain `auth.signUp` + emailed verification code). Kept deployed as an emergency fallback
  for email-delivery outages.

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
4. **CanvasKit preview limit (NARROWER THAN IT LOOKED; corrected 2026-07-19).** The Claude
   desktop Electron preview may fail to screenshot the Flutter CanvasKit canvas, and a
   reused/wedged preview instance may fail to mount the glass-pane; a FRESH instance mounts
   fine. **But the canvas IS screenshottable outside that preview**: `ops/shotgen/capture.mjs`
   drives real Chrome via puppeteer-core and captures the running app perfectly at 1125x2436,
   which is how the store screenshots are produced. Two traps learned there: (a) a build made
   with `--base-href /app/` only renders when SERVED under `/app/` (serving it at root gives a
   blank page and looks exactly like a CanvasKit failure), and (b) a cold load can take longer
   than any fixed sleep, so wait for readiness (the splash PNG is tiny, a real screen is
   hundreds of KB) or you silently capture a run of splash screens.
   HTML pages (the Astro site) can still wedge the in-app preview screenshot if they use heavy
   GPU effects (feTurbulence grain, backdrop-filter) - avoided.
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
10. **Scheduled notifications on Android need BOTH manifest receivers AND proguard keep rules
   (CRITICAL, hit 2026-07-14 on the owner's phone: zero reminders ever fired).** TWO stacked
   causes, fix both or reminders stay dead:
   (a) PRIMARY - flutter_local_notifications v18 does NOT merge its broadcast receivers from
   the library manifest (verified by reading the pub-cache AAR manifest: it ships only
   permissions). `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` MUST be
   declared in app/android/app/src/main/AndroidManifest.xml (now done). Without the first,
   every zonedSchedule alarm broadcasts to a non-existent component and Android silently drops
   it - debug AND release, no exception raised anywhere. Without the second, a reboot or app
   update wipes all alarms and nothing reschedules until the next app open.
   (b) SECONDARY - R8 minification (ON by default in release) strips GSON generic signatures
   the plugin needs, so zonedSchedule THROWS in release only and the runZonedGuarded zone
   swallowed it. Fix: `android/app/proguard-rules.pro` (keep `com.dexterous.**` + gson +
   Signature/annotations) appended via `proguardFile("proguard-rules.pro")` in build.gradle.kts
   (proguardFile APPENDS; `proguardFiles(...)` would REPLACE Flutter's defaults - never switch).
   Also: `_safeZoned` in notifications_mobile.dart guards each schedule call (one failure no
   longer aborts the rest) and prints to logcat; a DENIED first-open permission prompt now
   flips the in-app notifications toggle OFF (auth_choice_screen + home_shell) so Settings
   tells the truth and re-enabling re-requests the OS permission. Debugging on-device starts
   with: `adb logcat | grep "awwad notif"`.
11. **Release resource shrinking strips runtime-only res/raw sounds (hit 2026-07-18).** The
   adhan silently vanished from the release APK because nothing references `@raw/adhan` from
   code the shrinker can see (the channel sound is looked up by NAME at runtime). Fix:
   `android/app/src/main/res/raw/keep.xml` with `tools:keep="@raw/adhan"`. Verify after EVERY
   release build: `aapt2 dump resources app-release.apk | grep raw/adhan` (must be 1) and
   `unzip -l` shows a ~2.24MB `res/*.mp3`. ALSO: never run two gradle builds concurrently on
   one build dir - concurrent builds corrupt resource merging.

12. **Git Bash rewrites `/app/` into a Windows path (hit 2026-07-20).** MSYS path conversion
   turns `flutter build web --base-href /app/` into
   `--base-href C:/Program Files/Git/app/`; flutter then errors out with "should start and end
   with /" and the build NEVER RUNS. The trap is that the previous `build/web` is still
   sitting there, so a careless check "sees" a build and believes it is fresh. Fix: run
   `export MSYS_NO_PATHCONV=1` first (or build from PowerShell). Always confirm the build is
   real afterwards, e.g. `grep '<base href=' app/build/web/index.html` plus the timestamps in
   `app/build/web/assets/`.

13. **The Flutter WEB engine downloads Roboto from fonts.gstatic.com (hit 2026-07-20).** It
   fires at boot whenever no font family named `Roboto` is registered, regardless of what the
   theme uses. That is a third-party request the site half of this project deliberately does
   not make, and it fails offline. Fix: register the bundled faces a second time under
   `family: Roboto` in `pubspec.yaml`. Verify by listing `performance.getEntriesByType(
   'resource')` on the running app and confirming no `fonts.gstatic.com` entry.

---

## 11. Brand & content rules

- **LOGO (owner ruling 2026-07-17, FINAL): the mark IS the official Noto emoji seedling
  (U+1F331) artwork - the exact plant the app renders next to «أول خطوة» - stored at
  `app/assets/logo/sprout.png` (rasterized unmodified from googlefonts/noto-emoji
  svg/emoji_u1f331.svg, Apache-2.0). NEVER redraw it, NEVER substitute a hand-made lookalike
  (two earlier lookalikes were both rejected: «عايزها هي هي... مش تعمل فيها اي تعديل»).**
  Every icon is COMPOSITED from that PNG by `ops/icongen/gen.mjs` (app icon = plant on the
  #12161F rounded tile), `ops/icongen/site-icons.mjs` (favicon/192/512/apple-touch/logo-mark/
  play-icon) and `ops/icongen/banners.mjs` (og-image + play-feature). To change any icon:
  replace sprout.png, re-run the three scripts, then `flutter pub run flutter_launcher_icons`
  + `flutter_native_splash:create`.
- **Name:** عوّاد / Awwad. **Slogan:** «رفيقٌ مَن زانَ عُمرَه، وحُسُنُ عملَه» (note the
  tashkeel on حُسُنُ: ح, س, ن all carry damma). Set in `app_ar.arb` `slogan` + `site.js` ar `slogan`.
- **Colors:** dark theme. App accents: blue `#4f8ef7`, teal `#2dd4bf`, amber `#f59e0b`.
  Website redesign uses a SINGLE teal accent `#2dd4bf` + Reem Kufi display headings.
- **Tone:** supportive, MSA, Islamic-values-aligned, never preachy; rulings cite islamweb.net.
- **Two tracks:** break a habit / build a habit, both via HRT (awareness → competing response
  → environment control → maintenance).

---

### Fonts and their licence basis (READ BEFORE CHANGING A FONT)

- **FF Dusha Arabic** (`app/assets/fonts/FFDushaArabic-Regular.otf`) - MAIN HEADINGS.
  Supplied by the owner 2026-07-20. The file s own embedded licence string says
  "free for personal use only ... for commercial use please buy it". That text was
  shown to the owner verbatim and he confirmed he holds the rights to use it in this
  project. Recorded here so the basis is not lost. If that ever changes, the swap is
  one constant: kHeadingFamily in app/lib/app/theme.dart.
  **HARD LIMIT, measured from its cmap: 180 glyphs. ZERO Latin letters, ZERO Western
  digits.** Arabic coverage is complete (only U+063B..U+063F missing, unused in Arabic).
  So kHeadingFallback -> IBM Plex Sans Arabic is MANDATORY, not cosmetic: without it
  every English and French heading, and every Latin numeral inside an Arabic heading,
  renders as empty boxes. Locked by test/type_scale_test.dart.
- **Bodoni Moda Italic** (`app/assets/fonts/BodoniModa-Italic.ttf`) - PROMINENT NUMERALS only, via
  numberStyle() in theme.dart. Owner-supplied. Latin digits only, no Arabic-Indic
  digits and no Arabic letters, so it is never a theme default. This works because the
  app s DYNAMIC numbers are Western digits (plain int interpolation); the Arabic-Indic
  digits that appear in copy are inside sentences and correctly keep the text family.
  Applied to: stat tiles, the tasbih counter, the pomodoro timer.
- **IBM Plex Sans Arabic** - ALL body, labels, controls. SIL OFL 1.1.
- **Tajawal** - kept bundled as the previous display face. SIL OFL 1.1.

## 12. Pending work / TODO

> Top two are the owner's queued priorities (see §0).

0a. **Deep per-habit appropriateness review (expert pass).** Make every habit's daily-log
   content fit it and be consistent with the others. Resolve via `metricsForHabit` +
   `kHabitChecklists`/`kHabitVideoQuery` (`habit_content.dart`) + `defaultReminderHours` +
   the track-aware slip/done question. Examples already done: water (cups/spread, 5 reminders),
   prayer (delay/sunnah), adhkar (Fajr+Isha). Many build habits still use the GENERIC
   progress/quality metrics and no checklists — design per-habit content via a Workflow, verify
   adversarially, then sync app + seed + live DB.

0c. **Power features roadmap (owner-approved 2026-07-12, ordered by importance x commonality x
   practicality).** DONE: (1) SOS «لحظة ضعف» screen; (2) DNS content shield (Private DNS guided
   setup + live verification). NEXT (in order):
   (3) DONE phase A (2026-07-12 round 2): app-usage monitoring + per-app daily limits +
       on-open warnings. DONE phase B (2026-07-17): background overrun ALARMS via native
       UsageLimitWorker (15-min WorkManager periodic, notification the moment a limited app
       crosses its budget, once/app/day, works with Awwad closed). PHASE C = hard BLOCKING.
       Owner CONDITIONALLY approved it on 2026-07-20 (phase 0.6 item 1): build it only where
       it cannot cause a store rejection, decided per platform. **POLICY RESEARCH DONE
       2026-07-20, verdicts below. Both platforms are CONDITIONAL, neither is a flat no.**

       **ANDROID: CONDITIONAL, BUILDABLE.** All 11 comparable apps (AppBlock, StayFree,
       Forest, one sec, Opal, Freedom, ActionDash, ScreenZen, Stay Focused, Digitox, Digital
       Detox) are live on Play as of 2026-07-20 and every one uses AccessibilityService. No
       removal or rejection found 2023-2026. Conditions, all mandatory:
        - Do NOT set `isAccessibilityTool`. Qualifying tools are screen readers, switch input,
          voice input, Braille only; "monitoring apps" and "automation tools" are named as
          NOT eligible. A false declaration is itself a violation and can terminate the
          developer account.
          Source: https://support.google.com/googleplay/android-developer/answer/10964491
        - Complete the Play Console accessibility declaration (non-tool branch), which wants a
          screen-recorded VIDEO of the in-app disclosure. Mandatory since 2021-11-03.
        - Ship an in-app PROMINENT DISCLOSURE with affirmative consent, not buried in the
          privacy policy and not bundled with any other consent.
          Source: https://support.google.com/googleplay/android-developer/answer/16558241
        - Keep the block DETERMINISTIC and user-configured ("if user-picked package X
          foregrounds, show screen Y"). The 2025-10-30 policy update prohibits an app that
          "autonomously initiates, plans, and executes actions".
          Source: https://support.google.com/googleplay/android-developer/answer/16550159
        - **The user must always be able to disable the service and uninstall Awwad.** The
          "prevent uninstall" carve-out covers parental-control and enterprise apps ONLY, and
          self-imposed adult blocking is NOT covered. So: friction and time-locks yes, true
          lock-out no. This kills any "strict mode" that blocks uninstall.
        - Do NOT request `QUERY_ALL_PACKAGES` (permitted uses are search, antivirus, file
          managers, browsers - blockers are not listed). Use `<queries>` + MAIN/LAUNCHER.
          Source: https://support.google.com/googleplay/android-developer/answer/10158779
       Platform risks to design around, not policy but they decide whether it WORKS:
        - Android 13+ restricted settings: a SIDELOADED app cannot be granted accessibility
          without the user digging into Settings > Apps > Allow restricted settings.
          Awwad currently ships from GitHub Pages, so today every user hits this. Argues for
          Play distribution.
        - Android 17 Advanced Protection "restricts accessibility services to verified
          accessibility tools" (Google security blog 2026-05-12). Blockers cannot legally be
          such a tool, so blocking BREAKS for users who enable it. Freedom documents exactly
          this in its own help centre. Needs a UsageStats + overlay fallback path.
        - Android 15+: SYSTEM_ALERT_WINDOW alone no longer lets you start a foreground service
          from the background.
       Two more findings that shape the design:
        - Every REAL rejection found in this space was disclosure hygiene, never the API
          itself: a stale declaration video, or disclosure wording judged too technical. So
          the declaration video and the wording of the in-app disclosure ARE the review.
        - The UsageStats + overlay fallback is genuinely weaker, not just less convenient.
          Android 12 treats `TYPE_ACCESSIBILITY_OVERLAY` as trusted but caps
          `TYPE_APPLICATION_OVERLAY` at 0.8 obscuring opacity, and `HIDE_OVERLAY_WINDOWS`
          lets the target app hide it; `UsageStatsManager` also returns null on a locked
          device since Android 11. Plan it as a degraded mode, not an equal path.

       **iOS: CONDITIONAL, GATED ON AN APPLE APPROVAL WE CANNOT SELF-SERVE.** The only legal
       route is FamilyControls + ManagedSettings + DeviceActivity. Development works with no
       approval; DISTRIBUTION (incl. TestFlight) needs the `com.apple.developer.family-controls`
       entitlement, requested by the ACCOUNT HOLDER at
       https://developer.apple.com/contact/request/family-controls-distribution , **once per
       bundle id** (main app + every extension; approval does not cascade). Apple's own WWDC22
       session 110336 states iOS 16 individual authorization exists so the API can build "more
       than just parental controls apps", and `.individual` auth needs no family group, so
       adult self-control is a sanctioned use. Indie precedent is solid (Habit Doom, Bloka,
       Faith Lock, one sec, Opal, ScreenZen). Across ~60 forum threads 2022-2026 only TWO
       denials surfaced versus dozens of "no response" complaints; Apple DTS admitted a
       backlog twice in April 2026. Budget 1 week best case, 4-8 weeks realistically.
       Guideline 4.10 forbids monetizing Screen Time APIs, so blocking must stay one feature
       of the habit product, never the paywalled product itself.
       **NO legal alternative exists**: content filter and DNS proxy are supervised-devices
       only, VPN needs organization enrollment (5.4), config profiles are swept into 5.5, the
       iOS 26 URL filter cannot stop an app launching, and no API lets a third party set a
       Focus mode. Verified against the Feb 2026 guidelines PDF, because the HTML page was
       observed returning FABRICATED guideline text to an automated fetch.
       => iOS blocking is BLOCKED ON THE OWNER: it needs the Apple Developer account ($99)
       that is already owner-gated, and then a wait on Apple. Not buildable this round.
   (4) Home-screen widget (streak + quick log; home_widget package).
   (5) Auto prayer-times reminders for prayer habits (offline adhan calculation by location).
   (6) Late-night usage detection for `late_nights` (depends on (3)'s usage plumbing).
   (7) Shareable monthly report image (calendar + streaks).
   (8) NEW catalog habit «غض البصر» (lower-gaze, break track) wired to the DNS shield + SOS
       (needs catalog + seed + live DB sync, all three together).
   REJECTED as infeasible (documented for the owner): system-wide realtime blur of
   opposite-gender faces/bodies over other apps - requires continuous screen capture + on-device
   ML + overlay; battery/latency/accuracy prohibitive, Play-rejection risk for the whole app,
   impossible on iOS. Network-level blocking (the shield) + SOS is the practical substitute.

0d. **RELIGIOUS-HABITS ENGINE + AUDIO WIRD (owner mega-spec, 2026-07-14).** Full owner spec;
   execute in phases. FEASIBILITY CALLS included - do not silently change them.
   **PHASE A - prayer-times engine (all feasible, offline):**
   - `adhan` Dart package (offline astronomical calc, zero cost). Location via geolocator
     (GPS, ACCESS_COARSE_LOCATION + iOS plist) with REQUIRED manual fallback: country ->
     nearest-city picker (bundle ~300-city JSON: ar/en names, lat/lng, tz - data being
     generated by workflow) and full manual editing of each time.
   - pray_on_time: 5 auto reminders at the 5 prayer times of the user's location, EDITABLE;
     optional toggle «ذكّرني قبل الصلاة بـ5 دقائق» applying to all five. Push (local) notifs.
   - adhkar: fajr+30min (morning) + asr+30min (evening), auto from same engine.
   - NEW catalog habit «سورة الكهف» (build, weekly): reminder Friday at jumu'ah+1h
     (jumu'ah ~= dhuhr on Friday). NOTE: needs weekly-day scheduling support in
     notif_scheduler (currently daily-hour only).
   - gratitude: user-set time (exists); its dua content MUST be authentic-hadith duas
     sourced via islamweb (generate + adversarially verify like dhikr.dart precedent).
   - GENERAL RULE (owner): ALL religious texts/duas in the app source from islamweb.net.
   - Dynamic rescheduling: prayer times shift daily -> reschedule the next N days' notifs
     on every app open (pattern: _autoSync-like hook in home_shell).
   - Adhan SOUND on prayer notifications: technically fine (custom notification channel
     sound, raw resource). LICENSING CAVEAT flagged to owner: use a short permissible
     adhan clip or an owner-provided licensed file (Makkah/Qatami recordings rights unclear).
   **PHASE A2 - porn-break habit:**
   - NEW catalog habit «كسر الإباحية» (break; distinct from secret_habit) synced
     catalog+seed+live DB. On selection: IMMEDIATELY open the DNS-shield guided screen
     (auto-set Private DNS is IMPOSSIBLE on Android by policy - apps cannot write that
     setting; the guided 2-tap flow + live verification is the honest maximum). Daily log
     reminder at a user-chosen hour (existing per-habit reminders cover this).
   - Scholar-video suggestions for RELIGIOUS habits only, <15 min, from: الحويني، وحيد
     عبدالسلام بالي، محمد الغليظ؟ (verify name), مصطفى العدوي + islamweb fatwa links.
     Direct YouTube links (in-app playback later). Extend kHabitVideos via the verified
     curation workflow pattern (find + adversarial re-verify duration/author).
   **PHASE B - Quran audio wird (feasible via free APIs):**
   - NEW habit «ورد الاستماع» with in-app AUDIO player (just_audio): mp3quran.net public
     API (api/v3/reciters?language=ar) for ~50 reciters (قدامى: المنشاوي، الحصري، عبد
     الباسط...؛ معاصرون: القطامي، ياسر الدوسري، بندر بليلة...). User picks reciter +
     surah/juz + daily pages OR monthly/yearly goal; progress tracked as the habit metric.
   - Reminder scheduling per owner: specific hour(s) OR hourly range (e.g. every hour
     10:00->23:00) - needs multi/interval scheduling in notif_scheduler.
   **PHASE B2 - hadith audio: PARTIALLY INFEASIBLE (documented honestly):** no free API
     exists for Bukhari/Muslim audio BY CHAPTER (قناة الحرم النبوي style). Available
     alternatives: (a) live-stream player of قناة السنة النبوية السعودية (play-only, no
     chapter choice), (b) hadith TEXT by book/chapter via sunnah.com API (no audio).
     DEFERRED until owner picks an alternative or a source appears.
   **PHASE C - monthly report:**
   - End-of-month local push -> beautiful report screen: per-habit monthly progress,
     encouragement, and PER-HABIT relapse solutions (scientific/HRT for behavioral,
     islamweb-sourced for religious; sensible generic template for CUSTOM habits).
     Content generated + adversarially verified per the established workflow pattern.
   DATA PREP (workflow 2026-07-14): DONE — committed at
   app/assets/data/{cities,reciters,scholar_videos}.json (306 cities / 50 reciters /
   25 verified videos). Deliberately NOT registered in pubspec `assets:` yet to avoid
   shipping unused bytes; ADD THE pubspec REGISTRATION as the first step of Phase A.

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
     log / a new tab. STATUS: superseded by 0c item (3) - phases A+B SHIPPED (monitoring,
     limits, background alarms) + per-app open counts (2026-07-18). Only hard blocking
     (phase C) remains, owner-gated.

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

- **2026-07-31 (IN PROGRESS this session): owner bug triage + native adhan chain + onboarding
  location + icon picker removed.** Owner reported from his real Android phone: (1) adhan
  sometimes ~30 min late, (2) NON-prayer habit reminders "playing the adhan", (3) the adhan
  sound not stopping on hardware button presses. DIAGNOSIS (verified against code + official
  docs, sources in the research notes): all three share one root cause chain. SCHEDULE_EXACT_ALARM
  is DENIED BY DEFAULT on Android 14+; _safeZoned silently degrades to inexactAllowWhileIdle;
  inexact alarms are deferred (docs: up to 1 hour) and delivered BATCHED with other pending
  notifications, so the deferred adhan lands at the same instant as a habit reminder and reads
  as "the reminder played the adhan". (3) is a design limit: a channel sound is played by the
  system and cannot be stopped programmatically at all.
  FIX SHIPPED (this session, being verified):
  a. NATIVE ADHAN CHAIN (Android): Dart's prayer engine writes a 30-day table
     (flutter.adhan_native_v1, built by buildAdhanTableJson in prayer_scheduler.dart, 5 new
     tests) -> AdhanScheduler.kt arms ONE setExactAndAllowWhileIdle alarm ->
     AdhanAlarmReceiver re-arms the next entry FIRST, then applies a LATENESS GUARD
     (<=5 min late: AdhanService plays the adhan; 5-30 min: silent «تذكير: صلاة X»
     notification; >30 min: nothing) -> AdhanService (FGS type mediaPlayback) plays the
     owner's adhan mp3 on USAGE_ALARM and STOPS ON ANY HARDWARE BUTTON: MediaSession +
     VolumeProvider intercepts volume keys (public API, no max-volume dead zone) +
     VOLUME_CHANGED_ACTION receiver fallback + SCREEN_ON/OFF for the power key; stop keeps
     the notification (alarm-clock contract). Boot/update/time-change/exact-grant receivers
     re-arm. FLN no longer schedules the Android adhan mains (double-notify guard);
     iOS keeps the FLN path. FGS-from-background rides the exact-alarm exemption and is
     gated on canScheduleExactAlarms (research-verified); no grant -> channel-sound fallback
     (old behaviour). Tap on the native notification routes via MainActivity extra ->
     awwad/adhan.pendingTap -> home_shell (counts notification_opened).
  b. EXACT-ALARM GRANT PUSH: new row in the permissions primer + a once-per-open
     MaterialBanner on Home for users PAST the primer with adhan/prayer habits and no grant
     (the owner's exact case). Play-safe: SCHEDULE_EXACT_ALARM needs no Play declaration
     (USE_EXACT_ALARM is the restricted one; never swap).
  c. ADHAN IN MAIN SETTINGS (core feature, owner order): _AdhanSettingsTile master switch in
     settings_screen (religious section, mobile only); no location -> walks into
     PrayerSettingsScreen first. The prayer-screen toggle stays.
  d. ONBOARDING LOCATION STEP (last step, skippable): country -> nearest city (searchable
     sheets from cities.json) + GPS auto-attempt on step entry (permission dialog in
     context); saves PrayerConfig with adhanSound default ON (mobile); guest-flow test
     updated 3->4 steps.
  e. ICON PICKER (24 icons) REMOVED everywhere (web + phones), accent-color precedent:
     model field + sync stay for backward compat, nothing renders or sets iconName.
  STATUS: analyze clean, 190/190 tests. Play Console note for the store submission:
  FGS mediaPlayback now requires the console declaration (description + demo video).
  NOT YET: emulator hardware verification of the chain (next), deploy, Android artifacts.
- **2026-08-01 ADVERSARIAL REVIEW ROUND (4 dimensions, refute-verify): 22 raw findings,
  12 confirmed (3 major), 3 refuted, the limit-killed verifications adjudicated by hand
  (round-20 precedent). ALL 12 FIXED:**
  MAJOR: (1) the adhan now follows Settings + location ALONE, never the habit list
  (applyPrayerSchedule: adhanWanted = cfg.adhanSound; adhan-only users get mains via the
  native chain on Android / FLN adhan on iOS; pre-alerts and silent mains stay habit-gated)
  - before this, the Settings switch promised an adhan that never fired without a prayer
  habit; (2) settings _applySchedule now ALSO runs applyPrayerSchedule, so turning
  notifications/religious content off actually disarms the native chain (it kept sounding),
  and snooze-length + language changes resync the native table; (3) _AdhanSettingsTile no
  longer caches PrayerConfig (stale copy could wipe prayer-screen edits on toggle) - reads
  fresh from the store every build/toggle.
  MINOR: AdhanService re-entrancy (teardownPlayback + finished reset at onStartCommand top:
  a backward clock set could re-fire into a live instance and orphan the first player,
  unstoppable); onStartCommand catch keeps the notification (fail-open: sound failure must
  not erase the prayer notification; the receiver fallback cannot cover it); native channel
  names localized via new table keys chName/chDesc (were hardcoded "Adhan" in English;
  ensureSilentChannel re-creates each fire so a language switch relabels), v2 safety-net
  name too; syncNativeAdhan returns bool and the scheduler falls back to FLN adhan mains
  when the native sync fails (silent-prayer hole closed); DST-safe day iteration in
  buildAdhanTableJson (date-component arithmetic, Egypt has DST); primer exact-alarm row
  gated to Android (was a dead button on iOS); onboarding + prayer-settings pickers search
  case-insensitively; PrayerAutoReminderNote "next step" wording only inside onboarding
  (new inOnboarding flag); catalog en description aligned with seed+live DB ("five daily
  prayers"); notifications_mobile id/channel header updated (6100 + fg/snooze channels);
  stray personal PDF in repo root added to .gitignore (never commit it).
  REFUTED (no change): mediaPlayback FGS policy risk (declaration guide already written),
  header staleness as a defect (updated anyway), seed en drift user impact (aligned anyway).
  NEW GUARDS: test/arb_parity_test.dart (arb key parity + no-device-locale-in-code scan).
  analyze clean, 199/199 tests.
- **2026-07-31 LANGUAGE AUDIT (owner report: switching ar -> en left parts Arabic).**
  Audited all three layers. CLEAN: the 3 .arb files are key-identical (118 each), and
  every inline locale-keyed map is complete and key-identical (verified with a real
  lexer-based scan, scratchpad scan2.js; a first regex scan produced 11 false alarms).
  THREE REAL DEFECTS FOUND AND FIXED:
  (1) HABIT TITLES stored in the creation language never followed the app language (the
      main visible mixing). New core/catalog/habit_display.dart: habitDisplayTitle renders
      the catalog title in the CURRENT language whenever the stored title is a catalog
      default in any of the 3 languages (or a legacy default, e.g. the old pray_on_time
      name); a user-typed name is never touched. Applied at ALL render sites: daily log
      header, habit switcher chip + remove dialog, habits list + reminders dialog + delete
      dialog, SOS picker, monthly report, reminder notification titles (notif_scheduler),
      snoozed-reminder titles (notification_actions), home-screen widget name. Storage,
      sync and the edit sheet still read/write h.title untouched. 4 tests incl. a full
      9-direction round-trip over EVERY catalog habit.
  (2) permissions_primer read the DEVICE locale (platformDispatcher) instead of the app
      locale: wrong-language primer for anyone whose app language differs from the phone.
  (3) Switching language did NOT reschedule: queued reminders/dhikr/prayer window/native
      adhan table stayed in the old language until the next open. The Settings language
      chip now rebuilds applyNotificationSchedule + applyPrayerSchedule immediately.
  Also re-checked the 07-17 "FR accents stripped" note: habit_content.dart French is
  accented now (matches were false positives inside larger words); nothing to fix.
  analyze clean, 197/197 tests.
- **2026-07-31 mid-session owner orders (both handled):**
  (1) «أين زر تسجيل الدخول؟» - RESOLVED AS NOT A CODE BUG: auth_choice_screen shows the
  create/sign-in buttons only when SupabaseService.configured (build carries the
  dart-define keys). The screenshot that triggered the question came from a keyless DEBUG
  test build; VERIFIED the Desktop Awwad-1.0.0-final.apk (libapp.so contains the Supabase
  URL, 6 hits) and the live web app main.dart.js (1 hit) both carry keys, so production
  builds show all three buttons. RULE REAFFIRMED: every build, including debug test
  builds, must pass the dart-defines (gotcha #8).
  (2) pray_on_time: renamed «الصلاة على وقتها» in catalog + seed.sql + LIVE DB (verified
  RETURNING row; also fixed an em-dash hiding in the seed's description - catalog/seed
  drift). Read-side title migration in LocalStore.loadHabits (only the exact old default
  migrates; custom names sacred). Its reminders are now AUTOMATIC: habitRemindersFor
  skips it (the prayer-window mains at the five exact per-location times ARE its
  reminders), and the manual hour picker is replaced by PrayerAutoReminderNote (shows
  today's five computed times once located) in onboarding setup + add-habit +
  habits_screen edit-reminders. 3 new tests (193/193 total), analyze clean.
  owner's real phone** (app under test, prayer habit). Reported by the owner; no diagnosis
  done yet. THREE lead theories, check in this order:
  (1) CALCULATION METHOD: engine picks method by country (core/prayer/prayer_engine.dart).
      A ~30-min flat error smells like the wrong method for his location (Egypt = Egyptian
      General Authority) or GPS/city mismatch. Compare the app's shown time vs a trusted
      local source for the SAME prayer + city first; if the SHOWN time is wrong, it is the
      engine/method, not scheduling.
  (2) INEXACT ALARM DEFERRAL: if the shown time is right but the SOUND came late, Android
      deferred the notification. Check whether _safeZoned schedules exactAllowWhileIdle and
      whether SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM is declared + granted (emulator dump
      showed awwad uid requesting it with op=default). Doze/battery optimization on his
      device is the same family.
  (3) STALE WINDOW: the 10-day prayer window rebuilds on app open; if his config/offsets
      changed after scheduling, old alarms keep old times until the next open.
  ASK THE OWNER: which prayer, expected vs actual clock time, his city + method + per-prayer
  offset settings, phone brand, and whether the TIME DISPLAYED in the prayer screen matched
  the mosque. That one answer splits theory 1 from 2.
- **2026-07-20 round 8 (color picker REMOVED on owner order)** - The accent-color choice is
  gone from the add flow, the edit sheet and rendering (switcher/tiles back to track colors).
  Habit.accentColor STAYS in the model and sync for backward compatibility (stored values
  parse, nothing renders them). Icon picker + weekday schedule remain. Owner also ruled: NO
  new feature unless proven at leading competitors. Deferred list unchanged (dailyTarget+unit
  is Loop/Streaks-proven and is the first candidate when work resumes). 185/185, analyze
  clean, web deployed, final Android artefacts rebuilt.
- **2026-07-20 round 7 (PRO habit customization)** - Owner brief: professional, everything
  customizable. Habit gained iconName (24-icon picker, kCustomHabitIcons), accentColor (8 hex
  swatches, habitAccentColor parser fails null on malformed) and scheduleDays (ISO 1-7; null,
  empty or full week = daily). New shared controls in features/home/habit_customizer.dart used
  by BOTH the add flow and the new tap-to-edit sheet in habits_screen (title, why, icon for
  custom habits, color, schedule; saves via new AppController.updateHabit). UNSCHEDULED DAYS
  ARE TRANSPARENT to currentStreak/longestStreak/habitStrength (generalized the weekly-habit
  mechanism via _unscheduled at the three walkers) and render dim (not missed) in the month
  heatmap; entries logged on a now-off day still count (never retroactive). Reminders expand
  to WEEKLY slots per chosen day (HabitReminderSpec.weekday, dayOfWeekAndTime) so nothing
  fires on an off-day; daily habits keep repeat-daily slots to spare the 30/60 budget. Synced
  through the config jsonb (icon_name/accent_color/schedule_days) both directions, no schema
  migration. Old stored habits parse unchanged (wird precedent). 7 new tests in
  custom_habit_test.dart; 185/185, analyze clean.
  DEFERRED (documented, next round candidates from the design spec): numeric dailyTarget +
  unitLabel + targetDirection (needs a DailyEntry change), timeOfDay grouping, difficulty
  weighting, startDate, isArchived.
  GOTCHA #15: a JS string.replace whose REPLACEMENT contains a dollar sign spliced the file
  (dollar-quote is a special pattern in JS replace): habit_icons.dart got a duplicated tail
  and a bisected function. When editing via node, either use a replacer FUNCTION or verify
  with a duplicate-definition grep afterwards.
- **2026-07-20 round 6 (notification actions VERIFIED ON DEVICE, debug probe removed)** -
  Ran the «تم»/«أمهلني» action buttons on the emulator via a temporary assert-guarded probe.
  Authoritative result from dumpsys notification: the scheduled reminder posts with
  **actions=2**, i.e. both buttons RENDER on a real Android shade (the part unit tests could
  not cover). The adhan channel is present with mAudioAttributes usage=USAGE_ALARM (the volume
  fix is live). The action HANDLER logic remains covered by the 17 notification_actions tests.
  Probe fully removed from sendTestNotifications. Tapping «تم» through the shade UI itself was
  flaky to automate (small target, shade re-scrolls), so the button-press-to-log path is
  proven by unit test + the on-device render, not by a scripted tap. NOT a blocker: a human
  tap works. analyze clean, 178/178 tests. Final release AAB+APK building now.
- **2026-07-20 round 5 (owner fonts everywhere + prayer-linked UX + permissions primer)** -
  SITE now uses FF Dusha Arabic for h1/h2/.brand/.section-title/.hero-title (Plex fallback
  carries Latin, Dusha has zero Latin glyphs) + Bodoni Moda available; both .otf/.ttf shipped
  in web/public/fonts and DEPLOYED (Pages d65ec00, verified live in the bundled CSS + font
  file 200). MSA sweep: removed «بصراحة» from dns_shield notesTitle; repo greps clean of the
  common colloquialisms. PRAYER-LINKED HABITS: adding pray_on_time / wake_fajr / adhkar with
  no prayer location now opens PrayerSettingsScreen immediately (add_habit + onboarding, same
  precedent as break_porn -> DNS shield); the scheduler already fires the 5 adhan-time mains
  + adhkar fajr+30/asr+30 once location exists. PERMISSIONS PRIMER: one-time bottom sheet on
  first home arrival (features/home/permissions_primer.dart, flag settings.permPrimerShown):
  notifications + location runtime dialogs in place, battery exemption via settings; usage
  access stays lazily asked in the usage screen ON PURPOSE (a Settings deep-dive before the
  feature is seen reads as spyware); no contacts/camera/mic ever. Hard app-closing per owner:
  only if trouble-free, and policy research says strict-mode uninstall-blocking is NOT
  trouble-free, so not built. analyze clean, 178/178 tests.
  STILL OPEN: tap-test «تم»/«أمهلني» on the emulator via the DEBUG-ONLY probe (id 1997,
  assert-guarded in notifications_mobile.dart sendTestNotifications; REMOVE after the test);
  Android release rebuild AFTER everything settles (owner: web ships per update, Android at
  the very end).
- **2026-07-20 (store copy)** - Owner asked to have the latest store AAB on the D: partition
  in project files (not just OneDrive Desktop). Copied
  `C:\Users\morad\OneDrive\Desktop\Awwad-1.0.0-store.aab` to `D:\Claude\awwad\release\` (SHA256
  hash-verified identical). Added `release/` to `.gitignore` (large binary, local mirror only,
  never commit). Re-copy from the Desktop path after any future rebuild to keep it in sync.
- **2026-07-20 phase 0.6 round 4 (item 2: «تم» + «أمهلني» notification actions)** - Habit
  reminders gained a done + snooze button, prayer and adhan alerts a snooze button, handled in
  a top-level `@pragma('vm:entry-point')` background isolate (an action tap does not launch
  the app, so the ordinary tap callback never sees it). «تم» auto-logs through LocalStore,
  reusing the pattern `widget_sync.dart` already proved for the home-screen widget quick-log.
  Snooze length 10/30 min, persisted in `AppSettings.snoozeMinutes` because the handler reads
  it from disk. Three defects avoided by design rather than found late, each locked by a test:
  snooze must NOT reuse the original id (habit reminders repeat daily; reusing it would erase
  the repeat), the foreground path must NOT re-initialize the plugin (it would drop the tap
  callback), and a snoozed prayer must not replay «حان وقت صلاة» ten minutes after the fact.
  Prayer payloads now carry the prayer key; tap routing still accepts the old bare `prayer`.
  Also fixed: `notification_opened` no longer counts the internal refresh signal, which would
  have inflated the only retention metric the app has. Verified: analyze clean, 165/165 tests
  (the derived-id test confirmed to FAIL when the logic is broken), web build + release APK
  both compile. **NOT verified on hardware: no button has been pressed on a device. Item 7.**
- **2026-07-20 phase 0.6 round 3 (icon system replaces the emoji)** - Owner: the icons must
  look modern, benchmarked against the best competitors. Replaced the emoji with **Material
  Symbols Rounded**, which ship inside Flutter (Apache 2.0), so no package, no network, no
  licence question, and tree-shaking keeps 40 habit icons to 7 KB. Verified all 40 concepts
  exist before committing to the set. The catalog `icon:` DATA field is untouched (it is
  synced to seed.sql and the live DB); icons resolve client-side by habit key in
  `habit_icons.dart` with the emoji as fallback. Site got the same family inlined as SVG.
  Three defects caught by verifying instead of assuming: hand-written SVG paths rendered
  unrecognisable shapes (now copied verbatim from source, and Material Symbols use
  `viewBox="0 -960 960 960"`); the pill-width reserve modelled a text-scaled emoji advance
  when an Icon has a fixed size; and the overflow test scrolled to `find.text('🚭')`, which
  no longer exists. Also made WEB_APP_URL overridable via `PUBLIC_WEB_APP_URL` after the
  owner reviewed a local site whose CTA sent him to the LIVE app, i.e. yesterday's code.
  Verified: analyze clean, 145/145 tests, site 139 pages, 0 em-dashes, 0 third-party refs,
  6 icons on each locale home page, app walk screenshotted in real Chrome.
- **2026-07-20 phase 0.6 round 2 (two-family type system + guests skip the survey)** -
  Owner clarified the font brief after seeing round 1: MAIN HEADINGS should match the wabl
  brand face, everything else stays on the Awwad face. Investigating his reference screenshot
  produced the key correction to round 1: «فلل وبل 13» is TEXT BAKED INTO A PHOTO, not web
  text, so the brand face is NOT the site's CSS face. Matched it by rendering the phrase in
  every free Arabic candidate: **Tajawal** (OFL, Boutros Fonts), corroborated by wabl.sa
  loading Tajawal in its font link while never rendering it. Wired as `kHeadingFamily` +
  `headingStyle()`; 10 heading sites converted from the two house idioms; site h1/h2/.brand/
  .section-title/.hero-title on Tajawal, h3 and all body on IBM Plex. Tajawal is tiny: 60 KB
  per weight bundled, 77 KB of woff2 total for the site.
  Also this round: headings strengthened everywhere (site hero h1 had been shrunk to 19px muted
  grey by a stray `.sub` class, so the home page effectively had no headline; app title roles
  went w600 -> w700, sizes up one step), and **guests no longer see the onboarding survey**.
  NEW GOTCHA #14: `ops/fontgen/fetch_fonts.mjs` had the family name HARDCODED, so running it
  for a second family silently overwrote the first family's files with the second family's
  bytes under the first family's names. Caught by a size check (42 KB -> 8 KB); the family and
  file slug are now required arguments.
  Verified: analyze clean, 140/140 tests, site 139 pages 0 em-dashes, guest walk screenshotted
  in real Chrome (lands on the track step, 3 progress segments, headings in Tajawal).
- **2026-07-20 phase 0.6 round 1 (fonts shipped + both blocking verdicts researched)** -
  ITEM 5 DONE: wabl.sa turned out to use ONE family at two weights, not two fonts -
  IBM Plex Sans Arabic w700 for the big title and w400 for the subline, read off the live
  computed styles (Beiruti is scoped to their internal `.crm-scope`, Tajawal never downloads).
  SIL OFL 1.1, so free for commercial use and app embedding, nothing to buy. Bundled in the
  app (`assets/fonts/` + OFL.txt), self-hosted on the site (12 woff2 subsets, generated
  `@font-face`), Cairo retired, Salma Arabic parked at `assets/brand/fonts/` (it is OFL too,
  per its own name table - not a licence problem, just no longer part of the type system).
  New `_awwadTextTheme` type scale: letterSpacing 0 everywhere (tracking breaks cursive
  Arabic), size floor 12, display capped at 40, headings w700 / titles w600 / body w400.
  TWO REAL DEFECTS FIXED ON THE WAY: (a) `google_fonts` downloaded the face at runtime, so a
  first launch with no connection fell back to the platform font - removed, family now
  bundled; (b) the Flutter WEB engine pulled Roboto from fonts.gstatic.com at boot - killed by
  registering our own faces under the family name `Roboto`, verified gone from the resource
  log. ITEM 1: policy research done for both stores, verdicts + sources in §12 0c(3). Android
  CONDITIONAL and buildable (killer condition: uninstall must stay possible, so no true strict
  mode); iOS CONDITIONAL but gated on an Apple entitlement that needs the $99 account first.
  Verified: analyze clean, 134/134 tests (15 new in `type_scale_test.dart`), site 139 pages
  with 0 em-dashes and 0 third-party requests, web app screenshotted in real Chrome.
  NEW GOTCHA #12: in Git Bash, `flutter build web --base-href /app/` silently becomes
  `C:/Program Files/Git/app/` - export `MSYS_NO_PATHCONV=1` or the build no-ops.
- **2026-07-20 phase 0.6 opened (owner brief captured)** - Phase 0.5 closed at 44/44 and
  live. New owner order recorded verbatim in docs/PHASE_06_BRIEF.md: hard app-blocking
  conditionally approved (per-platform, only where it cannot cause a store rejection);
  full-screen adhan CANCELLED in favour of background sound + shade notification; snooze and
  «تم» notification actions with volume/power silencing the sound only; SEO/GEO/ASO
  verification incl. AI-search visibility; full data-layer coverage for GTM and MMP;
  the two wabl.sa fonts identified, LICENCE-CHECKED and wired as heading/body with a proper
  type scale; design-taste pass; and the official Android emulator installed so the
  notification stack is finally exercised on a real runtime rather than by reasoning.
- **2026-07-20 round 21 (FINAL DELIVERY: everything built, verified, deployed)** - Release
  built from 1d84a22 with every aapt check green, including the two new ones:
  ACCESS_NOTIFICATION_POLICY present (without it the DND-bypass tile was a dead end) and
  ACCESS_FINE_LOCATION absent (coarse only). APK on the Desktop as Awwad-1.0.0-final.apk
  (md5 fb0d9a9b...). Pages deploy 602ed4f: app byte-verified live against the local build,
  site serving 139 pages with the 9 new articles returning 200 in ar and fr. SCREENSHOTS:
  33 real captures committed (11 per locale at 1125x2436), the walk now waiting out the save
  snackbar so the Today shot is clean. MANDATE_PLAN: 44 items, 0 open.
- **2026-07-20 round 20 (final review: 13 defects fixed, several self-inflicted)** - The
  review's verify agents died on the session limit, so the 14 raw findings were adjudicated
  against the code by hand; 13 were real. WORST, and introduced in round 19: the SP9
  "contextual" prompt gate `habits.any((h) => h.times.isNotEmpty)` is ALWAYS TRUE, because
  Habit.times falls back to [reminderHour] (default 20) - dead code pretending to be a
  decision. Worse, the OS-reconcile block ran before the user was ever asked, and a
  NOT-YET-DETERMINED permission reads as "not enabled", so it could silently and permanently
  set notificationsEnabled=false before any prompt existed. Fixed: the prompt is gated on
  notifPromptShown alone (this shell only renders after onboarding WITH a habit, which is
  already the contextual moment), the reconcile now requires notifPromptShown, and both are
  kIsWeb-guarded so web stops persisting a bogus disable. DND CHANNEL, three real traps:
  (a) ACCESS_NOTIFICATION_POLICY was never declared, so Awwad could never appear in the
  DND-access list and the new tile led to a dead end; (b) the null-guard made the bypass flag
  impossible to apply later, since setBypassDnd only sticks while the app HOLDS the access the
  user grants afterwards - guard removed, channel re-created on every open and again right
  after the grant; (c) upgrade and backup-restore users (adhanSound already true) never touch
  the toggle, so flutter_local_notifications would create a plain channel first - creation
  moved to every app open. Also: channel name/description now passed down LOCALIZED instead of
  hardcoded Arabic, the dead awwad_adhan_v1 channel is deleted, tap listeners are removable
  (HomeShell unmounts whenever the last habit is deleted, so they leaked and stacked), a stale
  habit payload no longer yanks the user to a deleted habit, and repeated taps no longer stack
  duplicate screens. analyze clean, 119/119.
- **2026-07-20 round 19 (MANDATE_PLAN Round 4 finished: every plan item closed)** - N8 TAP
  ROUTING: notifications carry a payload (kTapPrayer / kTapHabit+id / kTapReport) and
  home_shell routes a tap to the prayer screen, that habit's log (switching the active habit),
  or the monthly report. The launch-from-notification case is covered too, which the response
  callback never receives: getNotificationAppLaunchDetails is read at init and replayed to the
  UI once it registers. SP9: the OS notification request moved OFF the first-launch auth
  screen (see round 20 for the correction to its gate). N7 SAFE HALF: awwad_adhan_v2 created
  natively with setBypassDnd (the plugin cannot express it) plus a DND-access check and an
  honest settings tile; the full-screen-intent version stays owner-gated.
- **2026-07-19 round 18 (MANDATE_PLAN Round 6: verified scholar/expert videos for 13 habits)** -
  A 5-agent search proposed 14 candidates with honest confidence levels; EVERY id was then
  checked mechanically by ops/shotgen/verify_videos.mjs (oEmbed existence + embeddability +
  true lengthSeconds). All 14 were real, and the durations written into kHabitVideos are
  YouTube's, never the agent's claim. impulse_buying was DROPPED on the numbers: its only
  candidate is 905s against the owner's 900s rule, and shipping nothing beats bending the
  rule. 13 previously-uncovered habits gained a card: quit_smoking, quit_vaping,
  caffeine_excess, hair_pulling, skin_picking, phone_addiction, excessive_gaming,
  procrastination, oversleeping, late_nights, bad_language, anger, junk_food. Sources are
  medical/psychological for the clinical habits (a psychiatry professor for the BFRBs) and a
  scholar only where the topic is conduct. The now-dead YouTube SEARCH fallback
  (habitVideoSearchUrl + kHabitVideoQuery, 17 entries) was deleted. analyze clean, 119/119.
- **2026-07-19 round 17 (MANDATE_PLAN Round 10: 9 new articles, site LIVE at 139 pages)** -
  The blog went 30 -> 39 posts via the write-blog-round10 workflow (9 write agents + 9
  adversarial editor agents): ترك العادة السرية، كسر الإباحية وغض البصر، التحكم في الغضب،
  إدمان مواقع التواصل، أفضل تطبيقات العادات للمسلمين، المحافظة على الصلاة، ورد الصلاة على
  النبي، بر الوالدين، وخطة عادات رمضان. Each is a real trilingual piece (6 sections + 3 FAQ
  per locale, not a translation of the Arabic), dignified on the sensitive topics, with NO
  invented statistic, hadith or ruling (rulings point to islamweb per the values guideline).
  Assembled programmatically with validation (unique slugs, exact section/FAQ counts, em-dash
  strip) and dated on the existing 2-day cadence. Site rebuilt 112 -> 139 pages, 0 em-dashes,
  each new post carrying Article + FAQPage + BreadcrumbList JSON-LD and the related-articles
  block from Round 3. DEPLOYED (Pages c72f69a).
- **2026-07-19 round 16 (prayer window to the id-scheme max + store screenshots unblocked)** -
  N1 CLOSED: the Android prayer window went 6 -> kMaxPrayerWindowDays (10), the MAXIMUM the id
  scheme allows (mains are base+d*10+i with the next base 100 ids away), locked by the new
  test/prayer_window_test.dart (4 cases: base arithmetic, no duplicate ids across a full
  window, everything inside the cancelled 4000-4299 range, all alarms in the future). iOS
  stays at 2 days for the 64-request cap. A background re-arm is deliberately NOT built and
  the reason is in the code: a native re-implementation of the astronomical engine could
  compute WRONG prayer times, which is worse than a lapsed reminder for someone who has not
  opened the app in ten days. SCREENSHOTS: gotcha #4 is OBSOLETE - the CanvasKit canvas
  screenshots fine outside the Electron preview, so ops/shotgen/capture.mjs now drives the
  live build in real Chrome and writes genuine 1125x2436 PNGs to assets/screenshots/ (the
  empty folder was a hard Play blocker). ops/shotgen/verify_videos.mjs mechanically validates
  candidate scholar videos against YouTube so a dead or over-long link can never ship.
- **2026-07-19 round 15 (MANDATE_PLAN Round 5 complete: SOS outcome loop + weekly insight)** -
  SOS: the wave screen gained an honest third option «تعثّرت هذه المرة» beside «صمدت», which
  sets sosSlipPendingProvider and jumps to today's log with the slip answer PRESELECTED, so
  the trigger is journaled while the moment is fresh instead of being lost (hiding the option
  would have made the relapse journal lie). WEEKLY INSIGHT (core/report/weekly_insight.dart,
  pure + 9 tests): dominant slip trigger, cleanest weekday, and the week-over-week urge delta
  (only reported at >= 1 point so noise never reads as a finding), rendered as a Stats card
  that stays HIDDEN below 4 logged days, with one actionable MSA sentence per trigger
  (behavioural/HRT advice, never a ruling). analyze clean, 115/115.

- **2026-07-19 round 14 (MANDATE_PLAN Round 5 part 1: tasbih counter + habit strength)** -
  TASBIH «عدّاد الذكر» (core/widgets/tasbih_counter.dart): a large haptic tap counter for the
  five COUNTED worship habits (istighfar/salawat/dua target 100, adhkar/gratitude 33), shown
  above the primary slider in the daily log. The count persists per habit per day
  (awwad_tasbih_v1_*, stale days purged) and MAPS onto the existing 0-10 primary metric via
  the pure tasbihToMetric, so entry schema, sync and stats are untouched. HABIT STRENGTH
  (AppState.habitStrength): 0-100 EWMA over ~8 weeks, 14-day half-life, bounded at the habit's
  createdAt (a new habit is never capped), skips transparent, an unlogged today ignored,
  weekly habits measured only on their weekday; rendered as the first Today chip. It answers
  the biggest churn complaint - one bad day zeroes the streak but only dents the strength.
  New tests: tasbih_test (5) + habit_strength_test (7). analyze clean, 106/106.
- **2026-07-19 round 13 (MANDATE_PLAN Round 4 channels + N10 close-out)** - Prayer alerts moved
  onto their OWN channels (awwad_prayer_v1, awwad_prayer_pre_v1, awwad_adhkar_v1) through a new
  PrayerChannel enum on scheduleAt: muting daily habit nudges in system settings can no longer
  silence the prayer times (Android mutes are per-channel and cannot be undone from inside the
  app). Pomodoro (awwad_pomodoro_v1) and the monthly report (awwad_report_v1, previously riding
  the badges channel with a mismatched description) got their own too. Documented THE
  authoritative notification id + channel map at the top of notifications_mobile.dart, moved
  the personal-record notification off a hashed literal onto namespaced id 1006, and routed
  every cancel through _safeCancel so one plugin failure cannot abort a reschedule and leave
  the user with zero reminders. analyze clean, 94/94.
- **2026-07-19 round 12 (MANDATE_PLAN Round 8: store metadata + submission answers)** -
  Docs only, no app build. STORE_LISTINGS: every dead `*.netlify.app` URL replaced with the
  live GitHub Pages URLs (13 refs across both store docs; a dead privacy URL is an automatic
  Play rejection), 36 -> 40 habits, and the listings now promote what actually shipped
  (prayer times + adhan, Quran/hadith audio, usage limits + open counts, content shield,
  truce button, home widget, monthly report) in ar/en/fr. The untruthful «بياناتك تبقى على
  جهازك» claim is now the accurate offline-first + optional-account + anonymous-analytics +
  in-app-deletion wording. iOS keyword field rewritten for Arabic/English ASO (adhan, prayer
  times, screen time; «ال» stripped) and re-measured programmatically (94/100 keywords,
  166/170 promo). SUBMISSION_GUIDE gained section 5: the complete Play Data-safety table,
  Apple privacy labels, the PACKAGE_USAGE_STATS justification paragraph, the exact-alarm
  justification + the never-add-USE_EXACT_ALARM rule, age rating/IARC answers, the Health
  apps declaration, and the verified-compliance list (in-app deletion, Sign in with Apple
  not required, guest mode, coarse location, background audio, religious sourcing, no UGC).
- **2026-07-19 round 11 (MANDATE_PLAN Round 7 code: the store BLOCKERS)** - IN-APP ACCOUNT
  DELETION shipped (Play account-deletion policy + Apple 5.1.1(v); the owner's 2026-07-12
  web-only decision was a standard rejection on both stores - see MANDATE_PLAN ownerGated):
  Profile > «حذف الحساب نهائياً» with two confirmation gates, calling the deployed
  account-export-delete edge function with the caller's JWT (admin.deleteUser cascades), then
  resetAll() so no local orphan copy can resurrect the data on the next sign-in; trilingual,
  localized network/generic errors. SP7: ACCESS_FINE_LOCATION removed from the manifest
  (nearest-city matching only ever needed coarse; geolocator already requests low accuracy) -
  future-proofs the precise-location regime. SP3: the usage-access prominent disclosure now
  carries the required no-sharing sentence in ar/en/fr. analyze clean, 93/93.
- **2026-07-19 round 10 (MANDATE_PLAN Round 2: per-habit content 0a + retention wins)** - All
  8 items. CONTENT: break_porn now inherits secret_habit's tailored sliders (the alias only
  covered checklists, so the flagship recovery habit shipped generic urge/resistance);
  surah_kahf + listening_wird + hadith_wird gained tailored metrics and 5 competing + 4
  environment checklist items each (generated via scratchpad/add_round2_content.mjs, never
  hand-edited). WEEKLY STREAK FIX: new kWeeklyHabitWeekday/weeklyWeekdayFor +
  currentStreak/longestStreak treat non-Friday days as transparent for weekly habits and step
  7 days at a time, so an honest Kahf reader no longer shows a permanently broken 1-day streak
  (test/weekly_streak_test.dart, 5 cases). CU7 closed: 13 French strings re-accented by script
  (one manual correction: «Je range les miroirs» is the verb, not rangé). CU13: sensible
  defaultReminderHours for sleep_early/late_nights/qiyam/voluntary_fasting/exercise/read_books/
  istighfar. RETENTION: passive chip row on Today (🏆 best streak, 💰 money saved =
  costPerDay*cleanDays, 🧊 excuse days left) + a personal-record dialog and tray notification
  when longestStreak is beaten (snapshot taken before saveEntry); daily rotating encouragement
  replacing the two static banner strings - 14 general + 10 faith DailyLines picked
  deterministically from the day key, faith pool gated on showReligiousContent, no verse or
  hadith quoted (quoted religious text stays on the verified pipeline) with
  test/daily_motivation_test.dart. analyze clean, 93/93 tests.
- **2026-07-19 round 9 (MANDATE_PLAN Round 3: site technical SEO, DEPLOYED)** - All 6 items:
  (SA4) trailingSlash 'always' + slashed localizedPath/localizedSlug/articleLd/internal
  links - canonicals no longer point at a 301 hop; (SA5) keyword-bearing home title
  («عوّاد: تطبيق مجاني لترك العادات السيئة وبناء عادات جديدة» + en/fr) and the home now
  renders the keyword H1 with the old sub demoted to a p (slogan pill untouched); (SA7)
  internal links: 3 related same-category articles + hub link on every post, «من المدوّنة»
  6-article block on both hubs + 3-article block + all-articles button on home; (SA8)
  JSON-LD: Organization.logo, MobileApplication url/description/image/inLanguage/
  subCategory, BreadcrumbList on posts + hubs, Article image/dateModified/publisher.logo,
  og:type article + article:published_time on posts; (SA9) Cairo self-hosted as 3 variable
  woff2 subsets (81KB total, public/fonts/) with preload + font-display swap - ZERO
  third-party requests now, site fully first-party; (SA10) sitemap i18n xhtml:link
  alternates (333 entries). Verified in dist: 112 pages, 0 em-dashes, slashed canonicals/
  sitemap, breadcrumbs + related blocks + article og present, no fonts.googleapis refs.
  Pages deploy 0152e86 (site root replaced, /app/ untouched); live H1 + fonts poll-verified.
- **2026-07-18 round 8 (N5 + final review fixes: security + iOS-crash + calendar + dead-tap)** -
  N5 done: osNotificationsEnabled() reconciles the in-app toggle on every open (unknown =
  true, never false-disables); permanently-denied flow now shows a dialog deep-linking to
  the app's system notification settings (new openNotificationSettings on awwad/reliability,
  API-26 action + fallbacks) replacing the dead-end snackbars. Review-confirmed fixes:
  HomeWidgetBackgroundReceiver exported=false (a co-installed app could forge awwad://quicklog
  and fake habit entries; same-UID PendingIntents still deliver) + AppDelegate.swift now sets
  HomeWidgetBackgroundWorker.setPluginRegistrantCallback (without it the iOS widget button
  would silently no-op forever: only HomeWidgetPlugin gets registered in the headless engine).
  Self-adjudicated cheap fixes from the unverified findings: AwwadQuickLogIntent guard-let
  (Shortcuts can pass nil appGroup = crash path), GregorianCalendar in the provider's
  todayKey (locale calendars like Buddhist would never match Dart dayKey), widget button is
  launch-not-broadcast when no habit exists (aw_has flag, both platforms), prayer-settings
  re-checks the exact grant on resume + reschedules (tile no longer stale after granting
  from system settings). Accepted + documented limits: widget streak display can go stale
  while the app stays closed; sub-second resume race between refreshFromStore and an instant
  manual save; Android <=11 deep-Doze pre-alert can push the adhan ~4 min (while-idle
  budget). analyze clean, 83/83.
- **2026-07-18 round 7 (MANDATE_PLAN Round 1 batch A: notification reliability)** -
  (1) STATUS-BAR ICON: white-on-transparent ic_stat_awwad generated from the official sprout
  into drawable-{m..xxx}dpi (sharp mask script), wired in AndroidInitializationSettings and
  UsageLimitWorker (with brand setColor), added to keep.xml (name-referenced = shrinker bait,
  gotcha #11 pattern); every Android notification also carries color _kBrandColor (11 sites).
  (2) PRAYER WINDOW: 6 days on Android (id scheme fits), 2 on iOS (64-cap); prayers now
  survive a long weekend of the app staying closed. (3) TZ FALLBACK: timezone-lookup failure
  now falls back to a fixed-offset zone from the device offset instead of UTC (reminders no
  longer shift by hours). (4) USAGE GUARD gating: the 15-min worker only runs while limits
  exist (cancelUniqueWork otherwise) + new syncGuard channel call from saveLimits so the
  first limit starts it instantly. (5) Manifest exact-alarm comment corrected (14+ default
  denied; never USE_EXACT_ALARM). analyze clean, 83/83. MANDATE_PLAN Round 1 marked
  (N3/N9 done, N1/N2/N10 partial - re-arm worker + state receiver + housekeeping pending).
- **2026-07-18 round 6 (REVIEW FIXES + iOS-lens fixes)** - The 6-lens adversarial review
  (partial: 3 lenses re-running after a second limit hit) CONFIRMED 2 copy defects, both
  fixed: (1) Arabic streak label now keys on n % 100 (exact hundreds bare يوم, 103-110 أيام,
  11-99 يوماً) - the 100-day milestone the badges celebrate was rendering wrong MSA; same
  bucketing applied to usageOpensLabel; tests extended (100/101/103/110/111/180/200 + opens
  100/105/120). (2) French exact-alarm subtitle a -> à. PLUS 4 iOS-parity lens findings
  implemented: usage screen no longer shows the dead Android grant flow on iOS
  (UsageStatsPlatform.supported now Android-only -> honest «أندرويد فقط» message);
  prayer/adhan Darwin details gained interruptionLevel timeSensitive (the iOS twin of exact
  alarms; Xcode capability step added to IOS_PARITY_SETUP.md 2.5); habit-reminder slots
  capped at 30 on iOS (64-pending-request silent-drop guard, Android keeps 60); DNS-shield
  screen now shows real iOS steps (per-WiFi Configure DNS Manual with 1.1.1.3/1.0.0.3 +
  copy button) instead of Android Private DNS instructions, trilingual. analyze clean, 83/83.
- **2026-07-18 round 5 (iOS PARITY - owner rule: Android features must reach iPhone)** -
  (1) WIDGET: full WidgetKit twin prepared in-repo - ios/AwwadWidget/{AwwadWidgetBundle,
  AwwadWidget}.swift (TimelineProvider over the group.com.awwad.awwad UserDefaults aw_* keys,
  same midnight rollover, brand dark card, iOS17 interactive quick-log via
  ios/Runner/AwwadQuickLogIntent.swift running the SAME Dart callback; iOS16 falls back to
  open-app) + Dart side now iOS-enabled (HomeWidgetSync._supported includes iOS,
  setAppGroupId(kAwwadAppGroup) before any write, updateWidget gets iOSName). (2) ADHAN on
  iOS prepared behind `kIOSAdhanSoundBundled=false` (iOS sounds must be <=30s caf in the
  bundle; naming a missing file would MUTE the alert, so default sound until the Mac step).
  (3) docs/IOS_PARITY_SETUP.md: the complete Arabic Mac/Xcode guide (widget target + app
  group + intent dual-membership + afconvert adhan one-liner + flag flip + verification).
  Exactness needs nothing on iOS (native timing). analyze clean, 83/83.
- **2026-07-18 round 4 (EXACT PRAYER ALARMS - notifications mandate, part 1)** - Every
  scheduled notification used inexactAllowWhileIdle, so Android alarm batching could delay
  prayer/adhan alerts 10-15 minutes. Now: SCHEDULE_EXACT_ALARM in the manifest, _safeZoned
  takes `exact:` (prayer family only: scheduleAt + scheduleAdhan; habit/dhikr stay inexact
  for battery), silent fallback to inexact if the Android 12+ grant is missing or revoked
  mid-flight, new canUseExactAlarms/requestExactAlarmsPermission through the web-safe facade,
  and a prayer-settings tile «فعّل دقة المواعيد» that opens the system grant and reschedules.
  analyze clean, 83/83 tests. Ships with the widget round's next build.
- **2026-07-18 round 3 (HOME-SCREEN WIDGET code complete; paused on session limit)** - 0c item
  (4) implemented end to end (see HANDOFF 0.5 for the piece list): native RemoteViews card
  (habit name + streak + quick-log button, midnight rollover check in the provider), Dart sync
  layer with pure trilingual labels (MSA agreement: يوم واحد/يومان/N أيام/N يوماً), background
  quick-log callback (idempotent, shared buildQuickEntry now also used by quickLogHabit), and
  the stale-cache reconciliation path (LocalStore.reload + refreshFromStore on resume).
  home_widget 0.9.3. analyze clean, 83/83 tests (4 new in home_widget_test.dart). Adversarial
  review + the owner-mandate research workflows both hit the 5h session limit before running -
  rerun after 05:20 Cairo, then build/deploy. Release builds started locally meanwhile. Owner
  mandate received (competitive UX, SEO/ASO, notifications, store policies) - plan in §0.5.
- **2026-07-18 round 2 (PER-APP OPEN COUNTS in the usage screen)** - Owner request (screenshot):
  every app row in «استخدام الهاتف» now shows how many times that app was opened today under its
  name, next to the screen time. Native: `todayUsage` in MainActivity.kt additionally iterates
  `usm.queryEvents(start, end)` counting ACTIVITY_RESUMED (MOVE_TO_FOREGROUND fallback < API
  29) and dedupes consecutive same-package resumes so in-app screen changes do not inflate the
  count; adds `opens` per row; fail-open (an event-query error just leaves opens = 0). Dart:
  `AppUsage` gains positional-optional `opens = 0` (payloads from an older native side keep
  working); the row renders the new pure `usageOpensLabel` - correct MSA number agreement
  (فُتح مرة واحدة / مرتين / N مرات / N مرة اليوم) + en/fr - only when opens > 0. New
  test/usage_opens_test.dart (4 tests). A 3-lens adversarial review workflow (Android API,
  Arabic copy, Flutter UI) produced 10 raw findings, 0 confirmed real. Verified: analyze clean,
  79/79 tests, web+APK+AAB rebuilt, gotcha #11 aapt checks pass, APK re-copied to the Desktop.
  Web bundle byte-UNCHANGED (Android-only code is tree-shaken from the web build; fresh build
  hash-identical to live Pages) so no Pages push. Also this session: confirmed the previous
  session's deploy DID complete (Pages 324b61d live + byte-verified) and moved gotcha #11 into
  §10 permanently.
- **2026-07-18 (ADHAN SOUND + hadith/Sunnah live radio + auto-log-after-listening)** - Owner
  approved. (1) ADHAN on the five prayer notifications: dedicated Android notification channel
  `awwad_adhan_v1` with a raw sound (`android/app/src/main/res/raw/adhan.mp3`), alarm audio
  usage, max importance; toggled by `adhanSound` in PrayerConfig + a switch in prayer settings;
  plays only on the actual prayer time, never the pre-alert. ADHAN FILE: owner-PROVIDED
  recording (317311.mp3), placed 2026-07-18 at the owner's explicit instruction; owner holds
  distribution rights. docs/ADHAN_SOUND.md covers replacing it (keep the name `adhan`). iOS
  keeps its default sound until a licensed .caf is bundled (needs a Mac).
  (2) HADITH/SUNNAH LIVE RADIO: new «ورد الاستماع للسنة» build habit + features/radio/
  radio_player_screen.dart - a play-only live tuner (no download/redistribution) over the
  SBA/qurango public streams (Sahih Bukhari, Sahih Muslim, Riyad as-Salihin, Seerah) + a Quran
  radio category (KSA Quran radio, tafsir...). core/radio/radio_stations.dart holds the https
  stream list (verified live). (3) AUTO-LOG AFTER LISTENING (owner request): both the Quran
  wird and the hadith radio auto-create today's entry after 2 minutes of real listening via the
  new `AppController.quickLogHabit(habitId)` (idempotent, never overwrites a manual log, does
  not touch the active habit). hadith_wird synced to catalog + seed + LIVE DB (now 40 rows).
  New tests: radio_autolog_test (4: station data, catalog, idempotent auto-log, adhan-flag
  roundtrip). Verified: analyze clean, 75 tests. NOTE: قناة السنة official SBA video stream
  (m.live.net.sa/live/sunnah) works but is http+video; used the https audio hadith channels
  instead (cleaner + legal). Hadith-audio-by-specific-chapter still has no free API (live tuner
  is the honest maximum).
- **2026-07-17 round 4 (0d PHASE B + C SHIPPED: Quran audio wird + monthly report)** -
  PHASE B: «ورد الاستماع للقرآن» catalog habit (build) + in-app audio player
  (features/quran/quran_player_screen.dart, just_audio + audio_session) streaming surah mp3s
  from the free mp3quran.net servers; core/quran/quran_data.dart is pure + tested (50 reciters
  from reciters.json, 114 surah names, 3-digit URL builder); reciter+surah choice persists
  (LocalStore quran wird) and the daily-log resource card opens the player. iOS audio
  background mode added. PHASE C: end-of-month report - core/report/monthly_report.dart (pure,
  tested: per-habit logged/clean/skip/slip counts, success rate, in-month best streak, and a
  per-habit relapse tip that is repentance-framed for religious habits, HRT/scientific for
  behavioural, generic for custom) + features/report/monthly_report_screen.dart (per-habit
  cards + tips) reachable from a Stats card and from the new end-of-month notification (id
  1005, last day 20:00, re-armed each open via home_shell). Both synced: listening_wird added
  to catalog + seed.sql + LIVE DB (now 39 catalog rows). New tests: quran_data_test (3) +
  monthly_report_test (4). Verified: analyze clean, 71 tests, web+APK+AAB built. NOTE: the
  adhan SOUND on prayer notifications is still owner-gated (needs a licensed clip); hadith
  audio-by-chapter remains infeasible (no free API) - both documented in 0d.
- **2026-07-17 round 3 (Arabic minors cleared + 0d PHASE A2 SHIPPED)** - Cleared the two logged
  Arabic minors: restored FR accents across ~30 checklist strings in habit_content.dart (café,
  téléphone, écran, à/dès/où, etc.) and made history cards use build-track vocabulary
  (أُنجزت/لم تُنجَز vs نظيف/تعثّر) by branching on the habit track like the heatmap. PHASE A2:
  two new catalog habits - «قراءة سورة الكهف» (build, weekly: scheduled Friday at dhuhr+1h via
  the new scheduleWeekly / prayer_scheduler, id 4300, independent of prayer-location config,
  falls back to 13:30) and «كسر إدمان الإباحية» (break; opens the DNS content shield immediately
  on add; reuses secret_habit's HRT checklists) - synced catalog + seed.sql + LIVE DB. Scholar
  videos wired from assets/data/scholar_videos.json for break_porn + 5 previously-uncovered
  religious habits (wake_fajr, daily_quran, qiyam, voluntary_fasting, salawat); a new regression
  test (catalog_a2_test.dart) enforces the owner's <15-min rule and CAUGHT 3 legacy videos over
  15 min (keeping_ties/istighfar), now replaced with shorter verified clips. Daily questions
  added for both new habits. Verified: analyze clean, 64/64 tests.
- **2026-07-17 round 2 (PRAYER-TIMES ENGINE SHIPPED + Arabic lens fixes)** - 0d Phase A live in
  code: offline adhan calc with regional methods (Egypt/Gulf authorities, MWL default),
  PrayerConfig (location + per-prayer manual offsets + 5-min pre-alert toggle) persisted in
  LocalStore, GPS via geolocator with bundled 306-city country/city picker fallback, 2-day
  notification window (ids 4000-4299: mains + pre-alerts + adhkar fajr+30/asr+30) rebuilt on
  every app open, Settings tile gated on religious content, location permissions added
  (manifest + iOS plist), notifications layer gained scheduleAt/cancelIdRange/scheduleWeekly
  (Kahf-ready), 5 engine unit tests (Cairo sanity, offsets, id windows). Arabic lens rerun:
  MAJOR consent fix (notice now rendered; consent only on real answers) + wording fixes synced
  to live DB (details in HANDOFF above). Verified: analyze clean, 59/59 tests, full builds,
  Pages redeployed, APK to Desktop.
- **2026-07-17 (FULL AUDIT FIXES + competitor round: real emoji logo, test notifications,
  usage-limit background alarms, sync integrity)** - Owner ran «التدقيق الشامل + كل التحسينات».
  **(1) LOGO, FINAL:** the mark is now the OFFICIAL Noto emoji seedling artwork (U+1F331,
  fetched from googlefonts/noto-emoji, Apache-2.0), i.e. the exact plant rendered next to
  «أول خطوة» inside the app - sprout.png replaced, every asset regenerated (launcher/splash/
  site/store/og/banners). §11 updated: the master IS the official emoji artwork, never redraw.
  **(2) TEST NOTIFICATIONS (Settings):** «اختبار الإشعارات» sends one instant + one 60s-scheduled
  notification (ids 1998/1999) so the owner can verify the fixed pipeline on-device in a minute.
  **(3) BATTERY GUIDANCE (Settings):** «التذكيرات لا تصل؟» dialog + `awwad/reliability` channel
  (manufacturer + openBatterySettings intents) for the OEM alarm-killers (Xiaomi/Oppo/Samsung...).
  **(4) USAGE-LIMIT BACKGROUND ALARMS:** native `UsageLimitWorker` (androidx.work 2.9.1, 15-min
  periodic, registered in MainActivity, KEEP policy) reads the Flutter-saved limits + today's
  UsageStats and posts a HIGH-priority warning the moment a limited app crosses its budget,
  once per app per day, trilingual, fail-open - works with Awwad closed. App LOCKING (password/
  hard-block) deliberately NOT shipped: needs an AccessibilityService with real Play-rejection
  risk; documented as an owner-gated option in §12 0c. **(5) POMODORO:** end-of-phase OS alarm
  (id 1004; arrives even if the app is killed) + full session persistence (LocalStore
  awwad_pomodoro_v1; a running timer resumes after restart, a phase that ended while closed
  lands on the next phase). **(6) SYNC INTEGRITY (audit workflow, 6 confirmed findings, all
  fixed):** skip entries now push NULL ratings (a single excused day used to poison the atomic
  upsert and silently kill ALL entry backup forever) + live DB checks relaxed to 0..10/null
  (migration 0009); owner-uid fence (`awwad_owner_uid`) stops one account's relapse history
  from being pushed into another account on a shared device, and sign-in over another user's
  data wipes-then-imports; habit deletion + «امسح كل بياناتي» now TOMBSTONE cloud rows
  (deleteHabitCloud/deleteAllCloud - no more resurrection on the next pull); sign-in with
  existing guest data MERGES cloud+local (union by id / habit+date, newer createdAt wins)
  instead of ignoring the cloud; failed first pull sets `awwad_pull_pending` and
  home_shell._autoSync retries pull+merge on every open (syncLater copy fixed to match);
  habits now sync created_at + reminder_hours (multi-time reminders used to be lost on
  restore). Advisors after 0009: only the known by-design warnings. Verified: analyze clean,
  full suite green, web+APK+AAB rebuilt, Pages redeployed, APK on the owner's Desktop.
- **2026-07-14 round 4 (NOTIFICATIONS/REMINDERS FIXED - the owner's phone bug)** - Owner
  tested the release APK on a real Android device: no notifications, no reminders. TWO stacked
  root causes found (self-diagnosis + adversarial audit workflow that read the plugin's
  pub-cache AAR manifest and Java source; see gotcha #10): (1) PRIMARY BLOCKER: the
  flutter_local_notifications v18 broadcast receivers were never declared in the app manifest
  and v18 does not merge them from the library, so every scheduled alarm broadcast was
  silently dropped by Android - no reminder could EVER fire, debug or release, since the
  feature shipped; both receivers now declared (Scheduled + Boot, the latter also fixes
  reminders dying on reboot/app-update). (2) R8 minification without proguard keep rules broke
  the plugin's GSON serialization in release; new android/app/proguard-rules.pro appended via
  proguardFile. Plus: `_safeZoned` per-call guard (one failed schedule no longer kills the
  rest; failures print «awwad notif:» to logcat), and a DENIED first-open permission prompt
  now flips the in-app toggle OFF so Settings reflects reality and re-enabling re-requests.
  ICON: confirmed every surface already composites the owner's exact plant (sprout.png, no
  redraw) - his phone had a pre-fix APK; uninstall old app before installing so the launcher
  icon cache refreshes. Fresh release APK+AAB rebuilt with receivers verified INSIDE the
  packaged manifest via aapt; APK copied to the owner's OneDrive Desktop. Verified: analyze
  clean, 54/54 tests.
- **2026-07-14 round 3 (LIVE TIMER ANIMATIONS + 0d groundwork)** - Owner: «خلي البومودورو
  ومؤقت الهدنة يكون فيهم انيميشن اثناء الاستخدام». **POMODORO** (`pomodoro_screen.dart`): the
  dial is now driven by two controllers (a 1s repeating frame clock + a 2.6s breathing pulse)
  that run ONLY while the timer runs. The ring sweeps CONTINUOUSLY off a `_deadline` DateTime
  (sub-second, and correct after a throttled/background tab) instead of jumping once per second;
  a phase-coloured glow breathes behind it (scale + blur + alpha); a luminous head dot rides the
  arc. Pausing/resetting/switching phase stops every controller (an idle screen schedules ZERO
  frames). **SOS «هُدنة»** (`sos_screen.dart`): two staggered rings now expand and fade outward
  (the urge "wave"), a circular progress ring around the breathing circle fills as the 5 minutes
  pass (also off a `_waveEnd` DateTime, so it creeps instead of ticking), the breathing circle
  gained a soft glow, and the instruction text cross-fades between inhale/hold/exhale; the
  "still fighting" button reuses the new `_startWave()`. New `test/timer_animation_test.dart`
  (4 cases) PROVES it: the ring advances within a single second, the movement is a creep not a
  jump, the idle dial schedules no frames, and SOS animates from the moment it opens.
  **0d groundwork**: `adhan` + `geolocator` added to pubspec and the religious data assets
  (cities/reciters/scholar_videos JSON) registered under `flutter: assets:`. Verified: analyze
  clean, 54/54 tests.
- **2026-07-14 round 2 (skip quotas wired + TRACKING layer + LAYOUT-OVERFLOW round + logo
  corrected)** - **(1) SKIP QUOTAS UI**: `skipBlockedBy()` now gates BOTH skip entry points
  (`_confirmSkipToday` and the skip option in the yesterday-repair sheet) via a shared
  `_skipQuotaBlocked()`; the confirm dialog shows the remaining week/month allowance; ar/en/fr
  MSA copy; rolling-window tests (anchor renewal at week/month boundaries, exhausted week,
  exhausted month). **(2) TRACKING DATA LAYER**: `AnalyticsService` no longer only buffers - it
  batch-INSERTs into Supabase `analytics_events` on app open (after cloud init) and after every
  saved entry, fail-open, 200-event cap, user_id stamped at flush; every event is enriched with
  {platform, app_version, locale} and habit events carry habit_track/catalog_key; the allow-list
  gained the 13 events that were being tracked but would have tripped the debug assert. Anon
  INSERT policy + grants verified against the LIVE DB with a real REST insert (201, row deleted
  after). WEB: `GTM_ID` const in site.js (EMPTY = no GTM script, no cookies) + conditional GTM
  head/noscript in Base.astro + `cta_click` dataLayer pushes (download/webapp/store) on the CTAs;
  docs/tracking-plan.md rewritten with the standard params, the flush contract, the full event
  catalog, a GA4/MMP name-mapping table and the owner-gated MMP note. **(3) LAYOUT/OVERFLOW
  ROUND** (audit workflow + an empirical pump-every-screen workflow at 320dp x 1.3 text scale in
  ar/en/fr): 13 real defects fixed. CRITICAL: pomodoro Reset button had `minimumSize:
  Size.fromHeight(52)` = an INFINITE min width inside a Row -> "BoxConstraints forces an infinite
  width" EVERY FRAME in EVERY locale (a separate sweep proved it was the only instance of that
  bug class). Also: pomodoro phase Row -> Wrap + dial FittedBox; daily-log rank line and slider
  header/captions made flexible + 30-char cap on user-typed metric labels; habit-picker chips
  (onboarding + add-habit) bounded by a text-scale-aware ConstrainedBox; "custom habit" tile;
  badge grids in Badges + Profile switched from a fixed-aspect GridView to intrinsic-height Wrap
  cells (they clipped even at the default font scale); habits-screen section headers (broken at
  1.0 in fr) and tile controls; reminder-times "add" chip; GlassButton label; auth-choice screen
  made scrollable; signup "optional" row; usage-screen total row + limit dialog (now scrollable
  so the keyboard cannot clip it); settings language Row -> Wrap (labels were breaking into 4
  lines); SectionCard now hosts a transparent Material so ListTile ripples are visible.
  Round 2 of the same pass (screens the first sweep never reached): the Stats HISTORY sub-tab
  was broken in ALL locales (date/status header row and every key/value row overflowed by
  28-101px), and the trend-chart + heatmap legends overflowed; onboarding pumped clean.
  New `test/layout_overflow_test.dart` (28 cases: pomodoro, daily log, badges, profile, habits,
  settings, auth-choice, add-habit picker, stats + history sub-tab, onboarding walk-through,
  each in ar/en/fr at 320dp x 1.3) locks all of this down. **(4) LOGO CORRECTED**:
  the icons were a hand-drawn "emoji-style seedling"; the owner asked for the plant itself
  («هي هي دي، مش تصنعها من جديد»), so ops/icongen now COMPOSITES `app/assets/logo/sprout.png`
  onto the brand tile (new gen.mjs + site-icons.mjs + banners.mjs) and every launcher/splash/
  site/store asset was regenerated from it (see §11). Verified: analyze clean, all tests green,
  site 112 pages, 0 em-dashes.
- **2026-07-14 (SEEDLING LOGO REDESIGN + tab titles + signup-form rework + marketing PDF)** -
  **(1) Marketing kit PDF** (owner request): docs/marketing/Awwad_Marketing_Kit.pdf (also
  copied to the owner's OneDrive Desktop) - cover + trilingual-sourced Arabic explainer
  (idea/14 features/9 steps/7 FAQ) + 100 ad posts in 5 angle families, written by a 6-agent
  workflow, assembled via Node -> RTL HTML (Cairo font) -> Chrome headless print (the
  reliable Arabic-PDF path on this machine; reportlab/python absent). **(2) Tab titles**:
  site home (ar/en/fr) + app web index.html + Flutter onGenerateTitle now show
  «عوّاد | رفيقٌ مَن زانَ عُمرَه، وحُسُنُ عملَه» (en: Always for the better; fr: Toujours
  pour le meilleur); other site pages keep SEO titles. VERIFIED live. **(3) LOGO REDESIGN**
  (owner request): the mark is now an emoji-style SEEDLING (curved stem + two upward leaves
  in a V, matching the in-app build-track icon) in the same brand greens; masters
  assets/icons/icon-full.svg + icon-foreground.svg rewritten; ops/icongen/gen.mjs re-run;
  flutter_launcher_icons + flutter_native_splash regenerated; derived assets regenerated at
  original sizes (site favicon/192/512/apple-touch/logo-mark, app sprout.png, play-icon-512)
  + og-image 1200x630 and play-feature 1024x500 recomposed via Chrome-screenshot HTML
  (seedling + Reem-Kufi عوّاد + slogan) - visually verified. **(4) SIGNUP FORM REWORK**
  (owner request): field order is now conventional (name* -> email* -> password* -> gender*
  -> collapsed optional extras LAST, so required fields never sit under the "optional"
  header); required fields are starred; missing-field toasts added (name/email/password +
  email-format regex) on signup, sign-in and reset flows. Verified: analyze clean, 20/20
  tests. ALSO: owner mega-spec for the religious-habits engine + Quran audio wird recorded
  as TODO item 0d (phased, with honest feasibility calls); data-prep workflow launched
  (cities/reciters/videos JSONs).
- **2026-07-12 round 6 (COMPETITOR FEATURES BATCH: 6 new features + CRITICAL streak fix)** -
  Owner approved implementing the competitor-research table («اعمل كله واختبر»). SHIPPED:
  **(1) Streak protection**: DailyEntry.entryType 'log'|'skip' - excused days (سفر/مرض) via a
  confirm dialog under the save button; transparent to streaks/badges/stats; distinct neutral
  cell + legend + sheet text in the heatmap. **(2) Streak repair**: when yesterday has no entry,
  an amber banner offers a 3-way backfill sheet (clean/slip/excused) via
  backfillYesterday/skipDay. **(3) Relapse journal**: trigger chips (10 trilingual triggers,
  kSlipTriggers in new core/catalog/motivation.dart) appear when the slip answer is chosen;
  stored on the entry; TriggersCard in Stats shows the top-3 recurring triggers. **(4) Ranks**:
  8 streak-based ranks (بذرة العزم -> العوّاد, thresholds aligned with shields) as a chip line
  on Today with days-to-next-rank. **(5) Recovery timeline**: 7 generic neuroplasticity
  milestones (kRecoveryTimeline, non-medical wording) as a Stats card with reached/next +
  progress bar (break habits). **(6) Money/time-saved calculator**: Habit.costPerDay/
  minutesPerDay set at add-time for break habits; gradient SavingsCard shows money+hours
  reclaimed based on clean days. DB migration 0008 applied LIVE (daily_entries entry_type +
  trigger_key) + sync roundtrip (entries columns + habits.config cost/minutes). **CRITICAL FIX
  from the adversarial review workflow**: currentStreak/longestStreak were GAP-BLIND since P1 -
  a user logging twice a month kept an unbroken "streak" and could farm shield badges; streaks
  are now CALENDAR-AWARE (unexcused missing day breaks; skip passes; pending TODAY does not
  break; longestStreak walks the real calendar). Legacy sparse data will show lower (correct)
  streaks. Tests rewritten date-RELATIVE (fixed dates would rot) + gap/pending-today cases;
  20/20 pass, analyze clean. NOT implemented from the table (documented): flexible scheduling,
  prayer-time reminders, habit stacking, lessons program (next wave - deeper model changes);
  accountability partner (needs owner's Firebase account, P4); Quran/dhikr streaks (already
  covered by existing habits + heatmap). NOTE: review workflow's ui-sync reviewer + 2 verifiers
  died on API errors (connection closed); the streak finding was fully verified, ui-sync
  dimension self-checked manually instead.
- **2026-07-12 round 5 (PER-HABIT CONTENT AUDIT: 12 confirmed fixes across all 36 habits)** -
  The long-queued "deep appropriateness review" (old TODO 0a) executed via an adversarial
  audit workflow (2 expert auditors + 11 per-finding verifiers; 13 findings verified, 12
  confirmed, 1 rejected). ALL 12 FIXED: (1) junk_food hadith meaning INVERTED in ar («خير
  وعاء» -> «ما ملأ ابن آدم وعاءً شراً من بطنه») - high; (2) secret_habit ar item
  self-contradictory (hold phone vs busy hands) - aligned to en/fr; (3) secret_habit gained a
  6th competing response: voluntary fasting per the «يا معشر الشباب» prophetic remedy;
  (4) oversleeping question broadened («هل نمت أكثر من حاجتك اليوم؟») - old one only caught
  going-back-to-sleep; (5+6) bad_language + impulse_buying FRENCH strings had all apostrophes
  stripped («d eau», «J ecris») - 18 fr strings restored; (7) HIGH: history_screen showed
  break-track labels (شدة الرغبة) for ALL build habits - now uses resolveMetrics like
  log/stats; (8) voluntary_fasting question reframed to PLAN adherence («هل التزمت بخطة
  صيامك؟») - honest non-fasting days no longer break the streak; (9) voluntary_fasting primary
  metric relabeled to plan-adherence (charts no longer collapse on non-fasting days);
  (10) wake_fajr got defaultReminderHours [4,21] (was falling back to 20:00 evening!);
  (11) adhkar evening reminder 21:00 -> 17:00 (between Asr and Maghrib per the habit's own
  coaching); (12) gratitude habit RENAMED «الحمد والدعاء» -> «الحمد والشكر» (clashed with the
  separate «الدعاء اليومي» habit) - synced in catalog + seed.sql + LIVE DB (verified) +
  STORE_LISTINGS.md + secondary metric label. Verified: analyze clean, 18/18 tests, 0
  em-dashes in content files.
- **2026-07-12 round 4 (CUSTOM habit metrics + advanced analytics)** - Owner-requested:
  **(1) Custom-habit user-defined sliders**: Habit model gained customMetricPrimary/Secondary
  (json + copyWith + cloud roundtrip via habits.config metric_p/metric_s in sync_service);
  new `customMetrics()` + `resolveMetrics()` in habit_catalog.dart (priority: user-typed >
  generated override > catalog > track default) now used by daily_log AND stats; AddHabitScreen
  shows two optional labeled fields (with examples) when creating a CUSTOM habit (onboarding
  custom stays simple deliberately - fields available post-onboarding). **(2) Advanced
  analytics** `features/home/analytics_section.dart` in Stats (needs >=3 entries): 30-day
  dual-metric trend LineChart, weekday success bars with "most challenging day" insight
  (danger-colored, needs >=2 logs/weekday), week-over-week clean-days comparison chip, top-5
  mood distribution. **(3) Competitor research workflow** produced a 14-feature decision table
  (streak freeze/repair, flexible scheduling, relapse journal + trigger analysis, prayer-time
  linked habits, accountability partner via FCM, recovery timeline, money-saved calc, daily
  pledge, habit stacking, Quran/dhikr streaks, rank levels, lessons program, mood correlation,
  notes-on-completion) - AWAITING OWNER DECISIONS, table in the chat + workflow output
  wf_aed940eb-5bc. Verified: analyze clean, 18/18 tests.
- **2026-07-12 round 3 (AUTO-SYNC replaces the manual sync button)** - Owner: the signed-in
  menu should show only the conventional «تسجيل الخروج», not «زامن الآن». Since that button was
  the ONLY ongoing push path, sync is now fully AUTOMATIC: (a) push on app open
  (home_shell._autoSync, silent fail-open, never blocks startup) and (b) fire-and-forget push
  after every saved daily entry (daily_log._save, unawaited + swallowed errors). Settings
  signed-in section = a single sign-out tile; _syncNow removed. Also added the iOS build
  command to §6 for the owner's plan to build the iPhone version from GitHub on a Mac.
  Verified: analyze clean, 17/17 tests.
- **2026-07-12 round 2 (WAVE 3: phone-usage monitoring + settings-menu audit)** - Executed by
  the in-session wakeup after the usage-limit reset (owner pre-authorized). **(1) Usage
  monitoring (phase A)**: new `awwad/usage_stats` MethodChannel in MainActivity.kt
  (hasPermission via AppOpsManager.unsafeCheckOpNoThrow, openSettings ->
  ACTION_USAGE_ACCESS_SETTINGS, todayUsage via queryAndAggregateUsageStats filtered to
  launchable apps with labels); PACKAGE_USAGE_STATS + LAUNCHER <queries> visibility added to
  the manifest; fail-open Dart layer `core/platform/usage_stats.dart` (+ per-app daily limits
  stored as JSON in SharedPreferences key `app_usage_limits_v1`); trilingual
  `features/phone/usage_screen.dart` (permission gate with lifecycle re-check, today's per-app
  list sorted desc, tap-to-set limit dialog with 15/30/60/120 presets + custom, progress bars,
  over-limit red banner, pull-to-refresh); entries: Today-tab card for `phone_addiction` +
  Settings tile (hidden on web). Background periodic warnings = later phase (checks happen
  on screen open now). NATIVE CODE UNTESTED ON DEVICE - owner validates with the new APK.
  **(2) Settings-menu audit (owner-requested)**: signed-out row now titled «إنشاء حساب /
  تسجيل الدخول» (opens signup form; sign-in one tap away); signed-in shows sync+sign-out
  (unchanged); **delete-account entry REMOVED from the app** per owner decision - store
  policy stays satisfied via the website's delete-account page (linked from store listings);
  `_confirmDelete` deleted; ADDED best-in-class items: share-the-app, contact-us (mailto
  moradarafa600@gmail.com), privacy-policy link, version line (1.0.0 - manual const, bump on
  releases). SHARE upgraded same day (owner request): now opens the NATIVE OS share sheet via
  share_plus 13.2.0 with a platform-aware link - Android shares the deterministic Play URL
  (play.google.com/store/apps/details?id=com.awwad.awwad, live the moment the app publishes),
  iOS shares the website until the App Store id exists (TODO(stores) marker in
  settings_screen.dart `_appStoreUrl`), web shares the site; desktop-web fallback = copy to
  clipboard + toast. Verified: analyze clean, 17/17 tests.
- **2026-07-12 (POWER FEATURES wave 1+2: SOS «لحظة ضعف» + DNS content shield)** - Owner
  approved the prioritized power-features roadmap (see §12 "Power features roadmap"). SHIPPED:
  **(1) SOS screen** `features/sos/sos_screen.dart` - urge-surfing support for break habits:
  animated paced breathing (4-2-6 cycle), 5-minute "urge wave" countdown with progress, the
  user's own reason-for-starting card, the habit's tailored competing responses as quick
  actions (reuses kHabitChecklists), adhkar card (respects religious toggle), «انتصرت» /
  restart buttons; entry = prominent gradient button on the Today tab (break habits only);
  new analytics events sos_opened/sos_won (allow-list + tracking-plan.md). Pure Flutter -
  works on Android/iOS/web with zero permissions. **(2) DNS content shield**
  `features/shield/dns_shield_screen.dart` + `core/platform/dns_shield.dart` + MethodChannel
  in MainActivity.kt (first native Kotlin in the project): guided 4-step setup of Android
  Private DNS with Cloudflare family resolver (family.cloudflare-dns.com) = phone-wide porn/
  malware blocking across ALL apps with ZERO app permissions; live VERIFICATION by reading
  Settings.Global private_dns_mode/specifier (no permission needed), auto re-check on
  app resume (lifecycle observer), copy-hostname + open-settings buttons (tries the direct
  PRIVATE_DNS_SETTINGS panel, falls back to wireless/settings), honest-notes card (not
  tamper-proof; iPhone manual path). Fail-open everywhere: web/iOS degrade to manual guidance,
  never crash. Entries: Settings tile («درع المحتوى») + a link inside SOS for secret_habit.
  Verified: analyze clean, 16/16 tests. NOTE: the Kotlin channel is untested on a real device
  yet - owner tests with the new APK; worst case = status shows "unknown" (fail-open).
- **2026-07-11 round 5 (AUTH MODEL REDESIGN: OTP moved to signup+reset, + MONTH CALENDAR)** -
  Owner defined the correct OTP model: the emailed code belongs to SIGNUP (email verification)
  and FORGOT-PASSWORD - not passwordless login (he tested signup with a second email and no code
  was requested/sent, because the old edge-fn path created accounts pre-confirmed). REBUILT AUTH:
  client now uses plain `auth.signUp` (Confirm-email ON) -> Arabic verification code (Confirmation
  template, set via PAT) -> `verifyOTP(type: signup)` -> session; forgot-password on the sign-in
  form -> `resetPasswordForEmail` -> Arabic code (Recovery template) -> `verifyOTP(type:
  recovery)` -> `updateUser(password)`. The passwordless «إرسال رمز» toggle was REMOVED; the
  `signup` edge fn is RETIRED from the client (kept deployed as emergency fallback).
  AuthChoiceScreen (first open) now offers THREE choices: «إنشاء حساب» (primary) / «تسجيل
  الدخول» / «المتابعة كزائر». A design workflow verified the exact GoTrue contract against
  source (obfuscated existing-email reply detected via `identities?.isEmpty ?? false`;
  unconfirmed re-signup resends the code and IGNORES the new password; PKCE does not break raw
  code entry). An ADVERSARIAL REVIEW workflow (2 reviewers + per-finding verifiers, 9 agents)
  confirmed 6 real defects, ALL FIXED: (1) reset flow re-consumed the one-time recovery code
  after a failed updateUser -> `_recoveryVerified` flag skips re-verify on retry; (2) unconfirmed
  re-signup left the OLD password active -> best-effort `changePassword` right after signup-code
  verify (same_password swallowed for fresh signups); (3) `_tr()`/context-after-dispose crashes
  when backing out mid-request -> mounted guards on every post-await toast; (4) RTL month arrows
  were double-mirrored (chevron IconData already carries matchTextDirection=true) -> hand-swap
  removed; (5) heatmap month not re-clamped on habit switch -> didUpdateWidget resets to current
  month; (6) day-details sheet overflowed with long notes -> SingleChildScrollView. NEW FEATURE:
  `features/home/month_heatmap.dart` - competitive monthly calendar heatmap in Stats (locale
  week start via MaterialLocalizations - Saturday for ar; RTL grid mirroring for free via Row
  direction; theme-role colors dark+light incl. WCAG-checked ink rule; break vs build legends;
  today ring; future days inert; month completion % with mid-month-start forgiveness; per-day
  bottom sheet with mood, 10-segment metric bars and note; «سجّل اليوم الآن» jumps to the Today
  tab; nav clamped to createdAt..now). 4 new unit tests for the grid math (offset/leap/rows).
  E2E-VERIFIED LIVE against the real project: real signUp 200 (+1 identity, no session, Brevo
  accepted the email), unconfirmed password login -> email_not_confirmed, full signup-code loop
  -> session, duplicate confirmed signup -> obfuscated identities:[], full recovery loop ->
  session -> new password works + old rejected, resend -> 429 rate-limit as designed. Templates
  set via PAT: mailer_subjects/templates_confirmation + _recovery (Arabic, {{ .Token }}).
  Verified: analyze clean, 16/16 tests. Test users cleaned.
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
