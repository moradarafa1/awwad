# Adhan notification sound

`app/android/app/src/main/res/raw/adhan.mp3` is the sound played when a prayer
time enters (Android), gated by the "adhan sound" toggle in Prayer settings.
It is referenced by name (`RawResourceAndroidNotificationSound('adhan')`), so
the file MUST stay named `adhan` (lowercase, no spaces/hyphens); `.mp3` and
`.ogg` are both valid raw formats.

CURRENT FILE: owner-provided adhan recording (317311.mp3), placed 2026-07-18 at
the owner's explicit instruction ("ده ملف صوت الاذان لا تستخدم غيره مطلقا").
The owner is responsible for holding any distribution rights, since the app is
published to app stores.

To change it: replace this file, keep the name `adhan`, rebuild.
iOS: bundle a licensed short `.caf`/`.aiff` and reference it in
notifications_mobile.dart `scheduleAdhan` (needs a Mac to build).
