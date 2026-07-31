// Bridge to the NATIVE Android adhan chain (AdhanScheduler/AdhanService in
// android/.../kotlin). Dart stays the single owner of the astronomical
// engine: it writes a ~30-day table of prayer moments + localized copy to
// SharedPreferences ("flutter.adhan_native_v1" on the native side) and asks
// the native side to (re)arm ONE exact AlarmManager alarm for the next entry.
// The native receiver re-arms after each fire and after boot, so the adhan
// keeps working with the app closed, offline, for a month without an open.
//
// Why native playback at all: a notification-channel sound is played BY THE
// SYSTEM and cannot be stopped programmatically without cancelling the
// notification. The owner's requirement (2026-07-31) is that ANY hardware
// button press stops the adhan sound instantly, which is only possible when
// the app plays the sound itself (AdhanService + MediaPlayer, USAGE_ALARM).
//
// Everything here fails open and is a no-op off Android.

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ch = MethodChannel('awwad/adhan');

/// The Dart-side key; native reads it as "flutter.adhan_native_v1".
const String kAdhanTablePrefsKey = 'adhan_native_v1';

/// The native chain exists only on Android.
bool get isNativeAdhanPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Persists [tableJson] and re-arms the native alarm chain. Returns whether
/// BOTH steps succeeded. The caller must treat false as "the native chain is
/// NOT armed" and fall back to FLN adhan mains: when the native path is
/// active the FLN mains are deliberately not scheduled, so swallowing a
/// failure here would mean no prayer notification at all.
Future<bool> syncNativeAdhan(String tableJson) async {
  if (!isNativeAdhanPlatform) return false;
  try {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(kAdhanTablePrefsKey, tableJson)) return false;
    return await _ch.invokeMethod<bool>('rearm') ?? false;
  } catch (_) {
    return false;
  }
}

/// Removes the table and cancels the armed alarm (adhan turned off, prayer
/// habit removed, notifications disabled...).
Future<void> clearNativeAdhan() async {
  if (!isNativeAdhanPlatform) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAdhanTablePrefsKey);
    await _ch.invokeMethod('rearm');
  } catch (_) {}
}

/// A tap on the NATIVE adhan notification opens the app with a payload extra
/// instead of going through the plugin's callback. Returns it once (native
/// clears it), in the same `prayer:<key>` format the plugin taps use.
Future<String?> consumeNativeAdhanTap() async {
  if (!isNativeAdhanPlatform) return null;
  try {
    return await _ch.invokeMethod<String>('pendingTap');
  } catch (_) {
    return null;
  }
}
