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
    // _anon holds the legacy public anon JWT (passed via --dart-define).
    // Use anonKey (not publishableKey): our project uses the legacy JWT key,
    // and passing it as publishableKey breaks initialize on web.
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(url: _url, anonKey: _anon);
      _inited = true;
    } catch (_) {
      // Leave _inited=false → app stays offline; retried lazily on sign-in.
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => configured && _inited ? client.auth.currentUser : null;
  static bool get signedIn => currentUser != null;

  // ---- auth ----
  // Registration goes through the `signup` edge function, which creates the
  // account already CONFIRMED server-side. This removes the dependency on
  // confirmation emails: the project has no custom SMTP yet and Supabase's
  // built-in mailer is capped at ~2 emails/hour (over_email_send_rate_limit,
  // hit live 2026-07-06). The function returns GoTrue-style error codes
  // (user_already_exists / weak_password / email_address_invalid) so the UI's
  // localized error mapping works unchanged. When Brevo SMTP is configured,
  // this can revert to plain client.auth.signUp.
  static Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    required String gender, // 'male' | 'female' (mandatory at registration)
    String locale = 'ar',
    String? country,
    String? birthDate, // ISO yyyy-MM-dd
    String? whatsapp,
  }) async {
    await init();
    try {
      await client.functions.invoke('signup', body: {
        'email': email,
        'password': password,
        'data': {
          'full_name': name,
          'locale': locale,
          'gender': gender,
          if (country != null && country.trim().isNotEmpty)
            'country': country.trim(),
          if (birthDate != null && birthDate.trim().isNotEmpty)
            'birth_date': birthDate.trim(),
          if (whatsapp != null && whatsapp.trim().isNotEmpty)
            'whatsapp': whatsapp.trim(),
        },
      });
    } on FunctionException catch (e) {
      final details = 'signup failed: ${e.details}';
      if (details.contains('user_already_exists')) {
        // The account already exists - typically because a PREVIOUS attempt
        // actually succeeded server-side while the phone missed the response
        // (seen live 2026-07-11: user created + signed in, then the post-auth
        // sync request dropped, so the app showed an error and the user
        // retried). If the entered password matches, just sign the user in:
        // the retry becomes seamless instead of a dead end.
        try {
          return await client.auth
              .signInWithPassword(email: email, password: password);
        } on AuthException {
          // Password does not match the existing account: surface
          // already-exists so the UI tells the user to sign in instead.
          throw Exception(details);
        }
      }
      // Re-throw with the function's error code in the message so the UI's
      // substring-based localized mapping picks the right text.
      throw Exception(details);
    }
    // Account is confirmed; establish the session right away.
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signInWithPassword(
      String email, String password) async {
    await init();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sends a 6-digit email OTP to an already-registered user (never creates one).
  static Future<void> sendLoginOtp(String email) async {
    await init();
    return client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  static Future<AuthResponse> verifyEmailOtp(String email, String token) {
    return client.auth.verifyOTP(email: email, token: token, type: OtpType.email);
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Change the signed-in user's password.
  static Future<void> changePassword(String newPassword) async {
    await init();
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

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
