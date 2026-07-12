// DNS content shield: guides the user to enable Android Private DNS with a
// family-filtering resolver (blocks pornography and malware PHONE-WIDE, in
// every app and browser, with zero app permissions), then VERIFIES the
// setting so the habit log can show a live shield status.
//
// Reading uses Settings.Global private_dns_mode / private_dns_specifier via a
// tiny MethodChannel (Android only). Web/iOS report 'unsupported' and the UI
// falls back to manual guidance. Everything here is fail-open: any platform
// error degrades to 'unknown', never a crash.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Cloudflare's free family resolver (malware + adult content).
const String kFamilyDnsHost = 'family.cloudflare-dns.com';

class DnsShieldStatus {
  /// 'hostname' | 'opportunistic' | 'off' | 'unknown' | 'unsupported'
  final String mode;
  final String? hostname;
  const DnsShieldStatus(this.mode, this.hostname);

  /// True when Private DNS is set to a family-filtering hostname.
  bool get shieldActive =>
      mode == 'hostname' &&
      (hostname ?? '').trim().toLowerCase() == kFamilyDnsHost;

  /// True when the platform cannot report the setting (web/iOS/old Android).
  bool get unsupported => mode == 'unsupported' || mode == 'unknown';
}

class DnsShield {
  DnsShield._();
  static const _ch = MethodChannel('awwad/dns_shield');

  static Future<DnsShieldStatus> status() async {
    if (kIsWeb) return const DnsShieldStatus('unsupported', null);
    try {
      final res = await _ch.invokeMapMethod<String, dynamic>('status');
      return DnsShieldStatus(
          (res?['mode'] as String?) ?? 'unknown', res?['hostname'] as String?);
    } catch (_) {
      // MissingPluginException on iOS (no handler) or any platform error.
      return const DnsShieldStatus('unsupported', null);
    }
  }

  /// Opens the Private DNS settings screen (Android). Returns false when the
  /// platform could not open any settings screen (caller shows manual steps).
  static Future<bool> openSettings() async {
    if (kIsWeb) return false;
    try {
      return await _ch.invokeMethod<bool>('openSettings') ?? false;
    } catch (_) {
      return false;
    }
  }
}
