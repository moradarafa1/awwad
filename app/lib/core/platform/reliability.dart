// Reminder-reliability helpers (Android only; every call fails open).
//
// Aggressive OEM battery managers (Xiaomi, Oppo, Vivo, Huawei, Realme,
// Samsung's "sleeping apps"...) silently kill AlarmManager schedules, which is
// the #1 reason correctly-scheduled reminders never arrive on real devices in
// our market. The app cannot exempt itself; all it can do is detect a risky
// manufacturer and walk the user to the right settings screen.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

const _ch = MethodChannel('awwad/reliability');

/// Manufacturers whose stock battery managers are known to kill alarms.
const _aggressive = {
  'xiaomi', 'redmi', 'poco', 'oppo', 'realme', 'vivo', 'iqoo', 'oneplus',
  'huawei', 'honor', 'meizu', 'infinix', 'tecno', 'itel', 'samsung',
};

/// True when this device's maker is known to throttle background alarms, so
/// the UI should surface the "reminders not arriving?" guidance proactively.
Future<bool> isAggressiveBatteryOem() async {
  if (kIsWeb) return false;
  try {
    final m = await _ch.invokeMethod<String>('manufacturer');
    return _aggressive.contains((m ?? '').toLowerCase().trim());
  } catch (_) {
    return false;
  }
}

/// Opens the battery-optimization exemption list (falls back to the app's
/// details page, then to Settings). Returns whether a screen opened.
Future<bool> openBatterySettings() async {
  if (kIsWeb) return false;
  try {
    return await _ch.invokeMethod<bool>('openBatterySettings') ?? false;
  } catch (_) {
    return false;
  }
}

/// Opens THIS app's notification settings (the only recovery path after a
/// permanently-denied POST_NOTIFICATIONS: the OS prompt can no longer show).
Future<bool> openNotificationSettings() async {
  if (kIsWeb) return false;
  try {
    return await _ch.invokeMethod<bool>('openNotificationSettings') ?? false;
  } catch (_) {
    return false;
  }
}

// --- Adhan vs Do Not Disturb (MANDATE_PLAN N7, safe half) ---
// Android channels can bypass DND, but only if the user grants the app "Do
// Not Disturb access" AND the channel was created with the flag.
// flutter_local_notifications cannot express that flag, so the channel is
// created natively. All three calls fail open.

/// Creates (or refreshes) the DND-bypassing adhan channel on Android 8+.
/// Safe to call on every app open, and it MUST be called again after the user
/// grants DND access: setBypassDnd only sticks while the app holds that
/// access, so a channel created before the grant needs re-applying.
/// [name] and [description] are what the user reads in system settings, so
/// they are passed in localized rather than hardcoded natively.
Future<bool> createAdhanBypassChannel(
    {required String name, required String description}) async {
  if (kIsWeb) return false;
  try {
    return await _ch.invokeMethod<bool>(
          'createAdhanChannel',
          {'name': name, 'description': description},
        ) ??
        false;
  } catch (_) {
    return false;
  }
}

/// Whether the user has actually granted DND access. Without it the bypass
/// silently does nothing, so the UI must not promise it.
Future<bool> hasDndAccess() async {
  if (kIsWeb) return false;
  try {
    return await _ch.invokeMethod<bool>('hasDndAccess') ?? false;
  } catch (_) {
    return false;
  }
}

/// Opens the system screen where DND access is granted.
Future<bool> openDndAccessSettings() async {
  if (kIsWeb) return false;
  try {
    return await _ch.invokeMethod<bool>('openDndAccessSettings') ?? false;
  } catch (_) {
    return false;
  }
}
