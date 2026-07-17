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
