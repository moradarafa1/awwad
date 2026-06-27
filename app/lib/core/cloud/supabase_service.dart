// Cloud auth gateway (P2). Entirely optional: if the build wasn't given
// SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define, [configured] is false and
// the app stays in pure offline mode (nothing here runs).
//
// Build with cloud enabled:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
//
// SECURITY: only the public anon key is used here. The service_role key is NEVER
// in the client — privileged work happens in Edge Functions.

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configured => _url.isNotEmpty && _anon.isNotEmpty;

  static bool _inited = false;

  static Future<void> init() async {
    if (!configured || _inited) return;
    // _anon holds the public anon/publishable key (passed via --dart-define).
    await Supabase.initialize(url: _url, publishableKey: _anon);
    _inited = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => configured && _inited ? client.auth.currentUser : null;
  static bool get signedIn => currentUser != null;

  // ---- auth ----
  static Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    String locale = 'ar',
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'locale': locale},
    );
  }

  static Future<AuthResponse> signInWithPassword(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a 6-digit email OTP to an already-registered user (never creates one).
  static Future<void> sendLoginOtp(String email) {
    return client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  static Future<AuthResponse> verifyEmailOtp(String email, String token) {
    return client.auth.verifyOTP(email: email, token: token, type: OtpType.email);
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Calls the login-guard edge function to decide if OTP is needed for an
  /// untrusted device. Returns true when the device is already trusted.
  static Future<bool> isDeviceTrusted(String? deviceSecret) async {
    if (deviceSecret == null) return false;
    final res = await client.functions.invoke('login-guard',
        body: {'device_secret': deviceSecret});
    final data = res.data as Map?;
    return data?['trusted'] == true;
  }

  static Future<void> registerTrustedDevice(
      String deviceSecret, String label, String platform) async {
    await client.functions.invoke('register-trusted-device', body: {
      'device_secret': deviceSecret,
      'device_label': label,
      'platform': platform,
    });
  }
}
