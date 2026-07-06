# iOS Build Task — Awwad App

## Goal
Build and run the iOS version of the Awwad Flutter app on this Mac so it matches the already-working Android build exactly (same features, same bundle id, same version). Do this now, step by step, without waiting for further confirmation unless something fails.

## Context
- Repo root contains `app/` (the Flutter project), plus `admin/`, `web/`, `supabase/`, `ops/`, `docs/`.
- Android build already works: applicationId `com.awwad.awwad`, version `1.0.0+1`.
- iOS platform files already exist under `app/ios/` (Runner.xcodeproj/Runner.xcworkspace, bundle id already set to `com.awwad.awwad`) but have never been built — this was developed on Windows, which cannot build iOS. That's why it's happening here on the Mac for the first time.
- Supabase cloud sync is optional (a P2 feature) and is wired via `--dart-define` flags, not hardcoded in source. The public Supabase URL + anon key (safe to reuse, it's the public anon key) are in `ops/build-app-cloud.ps1`.

## Steps
1. `git pull` in the repo root to make sure you have the latest code.
2. Run `flutter doctor` — confirm Xcode and CocoaPods are set up and there's a usable iOS target (simulator or a connected iPhone). Fix anything flagged (e.g. `xcode-select --install`, `sudo gem install cocoapods`).
3. From `app/`: `flutter pub get`
4. `cd app/ios && pod install && cd ../..`
5. Open `app/ios/Runner.xcworkspace` in Xcode (the `.xcworkspace`, not the `.xcodeproj`).
6. In Xcode → Runner target → "Signing & Capabilities": set the Team to the developer's Apple ID (a free "Personal Team" is fine), keep "Automatically manage signing" checked. Do NOT change the Bundle Identifier (`com.awwad.awwad`), display name, or version — they must stay identical to the Android build.
7. If testing on a physical iPhone: connect it via cable, trust the computer, and make sure Developer Mode is on (Settings → Privacy & Security → Developer Mode).
8. Build and run to the device/simulator:
   - Either press Run in Xcode with the target selected, or
   - From terminal in `app/`: `flutter run --release -d <device-id>` (list ids with `flutter devices`)
   - To enable cloud sync in this run, append: `--dart-define=SUPABASE_URL=https://kdczbzzjezyhfxgpegqc.supabase.co --dart-define=SUPABASE_ANON_KEY=<copy the anon key value from ops/build-app-cloud.ps1>`
9. Sanity-check parity with the Android build: app opens in Arabic (RTL) by default, language switch ar/en/fr works, core habit/badge features work, no crashes on launch.
10. Report back: whether it built successfully, on simulator or real device, any errors hit and how they were resolved.

## Known limitation (expected, not a bug)
With a free Apple ID (Personal Team, no paid $99/year Apple Developer Program), an app installed on a physical device expires after 7 days and needs to be rebuilt/reinstalled to keep testing. This is an Apple platform limitation, not something to "fix" in the project.

## Do not
- Do not change `applicationId` / `PRODUCT_BUNDLE_IDENTIFIER`, the app name, or the version — they must match the Android build.
- Do not commit any provisioning profiles, certificates, `.p12`, or `.mobileprovision` files to the repo.
- Do not touch the Android project or web/admin folders — this task is iOS-only.
