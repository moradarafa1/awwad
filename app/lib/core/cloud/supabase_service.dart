// Cloud auth gateway (P2). Entirely optional: if the build wasn't given
// SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define, [configured] is false and
// the app stays in pure offline mode (nothing here runs).
//
// Build with cloud enabled:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
//
// SECURITY: only the public anon key is used here. The service_role key is NEVER
// in the client — privileged work happens in Edge Functions.
//
// AUTH MODEL (since 2026-07-11, Brevo SMTP live):
//   - Sign-up = plain auth.signUp with "Confirm email" ON: the user receives an
//     Arabic verification CODE ({{ .Token }} in the Confirmation template) and
//     the app verifies it with verifyOTP(type: signup) -> session.
//   - Forgot password = resetPasswordForEmail -> Arabic CODE (Recovery
//     template) -> verifyOTP(type: recovery) -> session -> updateUser(password).
//   - The old `signup` edge function (admin-created, pre-confirmed accounts) is
//     retired from the client but stays deployed as an emergency fallback for
//     times when email delivery is down.

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configured => _url.isNotEmpty && _anon.isNotEmpty;

  static bool _inited = false;

  /// Bumps whenever cloud init finishes OR the auth state changes (sign-in /
  /// sign-out / session restored from storage on app open). UI that shows
  /// account state listens to this so it reflects the real session even when
  /// the session is restored asynchronously after the first frame.
  static final ValueNotifier<int> authRevision = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (!configured || _inited) return;
    // _anon holds the legacy public anon JWT (passed via --dart-define).
    // Use anonKey (not publishableKey): our project uses the legacy JWT key,
    // and passing it as publishableKey breaks initialize on web.
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(url: _url, anonKey: _anon);
      _inited = true;
      // Restoring a persisted session (app reopened while logged in) and every
      // later sign-in/out must refresh the account UI.
      client.auth.onAuthStateChange.listen((_) => authRevision.value++);
      authRevision.value++;
    } catch (_) {
      // Leave _inited=false → app stays offline; retried lazily on sign-in.
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => configured && _inited ? client.auth.currentUser : null;
  static bool get signedIn => currentUser != null;

  // ---- auth: sign-up with email verification code ----

  /// Starts registration. GoTrue sends a verification CODE to [email]
  /// (Confirmation template carries {{ .Token }}); the account gets a session
  /// only after [verifySignupCode]. Metadata keys mirror what the
  /// `handle_new_user` DB trigger provisions into `profiles`.
  ///
  /// Anti-enumeration: when the email already belongs to a CONFIRMED account,
  /// GoTrue returns an obfuscated user whose `identities` list is EMPTY and
  /// sends nothing - callers must check [signUpHitExistingEmail] on the result.
  /// For an existing UNCONFIRMED account it re-sends the code instead.
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
    return client.auth.signUp(email: email, password: password, data: {
      'full_name': name,
      'locale': locale,
      'gender': gender,
      if (country != null && country.trim().isNotEmpty)
        'country': country.trim(),
      if (birthDate != null && birthDate.trim().isNotEmpty)
        'birth_date': birthDate.trim(),
      if (whatsapp != null && whatsapp.trim().isNotEmpty)
        'whatsapp': whatsapp.trim(),
    });
  }

  /// True when a signUp response is GoTrue's obfuscated "this email is already
  /// registered and confirmed" reply. Verified against GoTrue source: the fake
  /// user has identities == [] (EMPTY ARRAY, never null); a real fresh or
  /// unconfirmed user always carries exactly one identity. Do not key on
  /// confirmation_sent_at (the fake user carries a fresh one too).
  static bool signUpHitExistingEmail(AuthResponse res) {
    final user = res.user;
    return user != null &&
        res.session == null &&
        (user.identities?.isEmpty ?? false);
  }

  /// Confirms the emailed sign-up code and establishes the session.
  static Future<AuthResponse> verifySignupCode(String email, String token) async {
    await init();
    return client.auth
        .verifyOTP(email: email, token: token, type: OtpType.signup);
  }

  /// Re-sends the sign-up verification code (rate-limited server-side).
  static Future<void> resendSignupCode(String email) async {
    await init();
    await client.auth.resend(type: OtpType.signup, email: email);
  }

  // ---- auth: password sign-in ----

  static Future<AuthResponse> signInWithPassword(
      String email, String password) async {
    await init();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  // ---- auth: forgot password (code-based, no deep links) ----

  /// Sends the password-reset CODE (Recovery template carries {{ .Token }}).
  static Future<void> sendPasswordResetCode(String email) async {
    await init();
    await client.auth.resetPasswordForEmail(email);
  }

  /// Verifies the reset code; on success the user is signed in and the caller
  /// should immediately set the new password via [changePassword].
  static Future<AuthResponse> verifyRecoveryCode(
      String email, String token) async {
    await init();
    return client.auth
        .verifyOTP(email: email, token: token, type: OtpType.recovery);
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
