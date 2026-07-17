// App-usage monitoring (phone-addiction habit, phase A: monitor + warn).
// Android-only, via the special PACKAGE_USAGE_STATS permission the user
// grants manually in system settings (it cannot be requested at runtime).
// Fail-open everywhere: web/iOS/errors degrade to "unsupported", never crash.
//
// Per-app daily limits are stored locally as a JSON map {package: minutes}
// in SharedPreferences. Phase A checks limits when the screen opens; a
// periodic background checker is a documented later phase.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUsage {
  final String package;
  final String label;
  final int minutes;

  /// How many times the app was brought to the foreground today.
  /// 0 when the platform side predates the field or events are unavailable.
  final int opens;
  const AppUsage(this.package, this.label, this.minutes, [this.opens = 0]);
}

/// "1h 25m" style split, kept pure for unit tests.
({int hours, int minutes}) splitMinutes(int total) =>
    (hours: total ~/ 60, minutes: total % 60);

class UsageStatsPlatform {
  UsageStatsPlatform._();
  static const _ch = MethodChannel('awwad/usage_stats');
  static const _limitsKey = 'app_usage_limits_v1';

  static bool get supported => !kIsWeb;

  static Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    try {
      return await _ch.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false; // MissingPluginException on iOS -> unsupported.
    }
  }

  static Future<bool> openSettings() async {
    if (kIsWeb) return false;
    try {
      return await _ch.invokeMethod<bool>('openSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AppUsage>> todayUsage() async {
    if (kIsWeb) return const [];
    try {
      final rows = await _ch.invokeListMethod<dynamic>('todayUsage') ?? [];
      return [
        for (final r in rows.whereType<Map>())
          AppUsage(
            (r['package'] as String?) ?? '',
            (r['label'] as String?) ?? '',
            (r['minutes'] as num?)?.toInt() ?? 0,
            (r['opens'] as num?)?.toInt() ?? 0,
          )
      ];
    } catch (_) {
      return const [];
    }
  }

  // ---- per-app daily limits (local only) ----

  static Future<Map<String, int>> loadLimits() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_limitsKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is num) e.key as String: (e.value as num).toInt()
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveLimits(Map<String, int> limits) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_limitsKey, jsonEncode(limits));
    } catch (_) {}
  }
}
