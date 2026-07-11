import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/net_errors.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';

// Email-OTP sign-in. Requires the custom SMTP (Brevo) + the Arabic
// {{ .Token }} code template configured on 2026-07-11 (live-tested: /otp 200,
// code email delivered). If SMTP ever breaks, flip to false so the UI never
// offers a code that cannot arrive.
const bool kOtpLoginEnabled = true;

// Optional cloud account screen (P2). Only reachable when SUPABASE_URL/ANON_KEY
// were provided at build time. Implements email+password + an email-OTP path.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startInSignUp = false});

  /// Opens on the create-account form instead of sign-in (used by the
  /// Settings entry and the post-first-log prompt, which both invite the
  /// user to CREATE an account).
  final bool startInSignUp;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _signUp = widget.startInSignUp;
  bool _otpMode = false;
  bool _otpSent = false;
  bool _busy = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  final _country = TextEditingController();
  final _whatsapp = TextEditingController();
  String? _gender; // 'male' | 'female' — mandatory at sign-up
  DateTime? _birthDate;
  bool _showOptional = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    _country.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  // Accept Arabic-Indic (٠-٩) and Persian (۰-۹) digits, normalize to Latin.
  String _normDigits(String s) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final ai = ar.indexOf(ch);
      final fi = fa.indexOf(ch);
      if (ai >= 0) {
        b.write(ai);
      } else if (fi >= 0) {
        b.write(fi);
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  String _tr(String k) =>
      (_regStrings[Localizations.localeOf(context).languageCode] ??
          _regStrings['en']!)[k]!;

  Widget _genderChip(String value, String label) {
    final sel = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              sel ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: sel ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? AppColors.heading : AppColors.muted,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  // Map raw auth/network exceptions to a localized human message; the raw
  // exception text (English, with internal URLs) must never reach the user.
  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (isNetworkError(e)) {
      return _tr('errNetwork');
    }
    if (s.contains('invalid login credentials') ||
        s.contains('invalid_credentials')) {
      return _tr('errBadCredentials');
    }
    if (s.contains('already registered') ||
        s.contains('user_already_exists') ||
        s.contains('email_exists')) {
      return _tr('errEmailExists');
    }
    if (s.contains('weak_password') ||
        s.contains('password should be at least')) {
      return _tr('errWeakPassword');
    }
    if (s.contains('email_address_invalid') ||
        s.contains('validation_failed') ||
        s.contains('invalid format')) {
      return _tr('errBadEmail');
    }
    if (s.contains('otp_disabled') ||
        s.contains('signups not allowed')) {
      // shouldCreateUser=false: requesting a code for an unknown email.
      return _tr('errNoAccount');
    }
    if (s.contains('otp_expired') ||
        s.contains('token has expired') ||
        s.contains('invalid token')) {
      return _tr('errBadOtp');
    }
    if (s.contains('rate limit') || s.contains('too many requests')) {
      return _tr('errRateLimit');
    }
    if (s.contains('email not confirmed')) {
      return _tr('errEmailNotConfirmed');
    }
    return _tr('errGeneric');
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Runs AFTER auth succeeded. A sync hiccup here must never read as a failed
  // sign-in/sign-up (seen live 2026-07-11: signup + login succeeded, then one
  // sync request dropped and the app wrongly showed "cannot reach the server",
  // so the user kept retrying an account that already existed).
  Future<void> _syncAfterAuth() async {
    var syncOk = true;
    try {
      final ctrl = ref.read(appControllerProvider.notifier);
      final snap = await SyncService.pullAll();
      final local = ref.read(appControllerProvider);
      if (local.habits.isEmpty && snap.habits.isNotEmpty) {
        await ctrl.importSnapshot(snap.habits, snap.entries, snap.survey);
      }
      final cur = ref.read(appControllerProvider);
      await SyncService.pushAll(
          habits: cur.habits, entries: cur.entries, survey: cur.survey);
    } catch (_) {
      syncOk = false; // Signed in fine; sync can be re-run from Settings.
    }
    try {
      // The user now has an account, so cancel any pending sign-up nudge.
      await cancelReengageNudge();
    } catch (_) {}
    if (!syncOk) _toast(_tr('syncLater'));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (_signUp) {
      if (_gender == null) {
        _toast(_tr('chooseGender'));
        return;
      }
      await _run(() async {
        final res = await SupabaseService.signUp(
          name: _name.text.trim(),
          email: email,
          password: _password.text,
          gender: _gender!,
          locale: ref.read(appControllerProvider).settings.locale ?? 'ar',
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          birthDate: _birthDate?.toIso8601String().split('T').first,
          whatsapp: _whatsapp.text.trim().isEmpty
              ? null
              : _normDigits(_whatsapp.text.trim()),
        );
        if (res.session == null) {
          // Email confirmation is required: the account exists but there is
          // no session yet, so syncing would silently no-op. Tell the user to
          // open the confirmation email, then switch to the sign-in form.
          AnalyticsService.instance.track('signup_succeeded',
              {'method': 'email', 'pending_confirmation': true});
          _toast(_tr('confirmEmailSent'));
          if (mounted) setState(() => _signUp = false);
          return;
        }
        AnalyticsService.instance.track('signup_succeeded', {'method': 'email'});
        await _syncAfterAuth();
      });
    } else if (_otpMode) {
      if (!_otpSent) {
        await _run(() async {
          await SupabaseService.sendLoginOtp(email);
          AnalyticsService.instance.track('otp_sent');
          setState(() => _otpSent = true);
        });
      } else {
        await _run(() async {
          await SupabaseService.verifyEmailOtp(email, _otp.text.trim());
          AnalyticsService.instance.track('otp_verified', {'success': true});
          await _syncAfterAuth();
        });
      }
    } else {
      await _run(() async {
        await SupabaseService.signInWithPassword(email, _password.text);
        AnalyticsService.instance
            .track('login_succeeded', {'otp_required': false, 'trusted_device': false});
        await _syncAfterAuth();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_signUp ? l10n.signUp : l10n.signIn)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.syncDesc,
              style: TextStyle(color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 20),
          if (_signUp) ...[
            TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.nameLabel)),
            const SizedBox(height: 16),
            Text('${_tr('gender')} *',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _genderChip('male', _tr('male'))),
              const SizedBox(width: 10),
              Expanded(child: _genderChip('female', _tr('female'))),
            ]),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _showOptional = !_showOptional),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(_showOptional ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.muted, size: 20),
                  const SizedBox(width: 6),
                  Text(_tr('optional'),
                      style: TextStyle(color: AppColors.muted)),
                ]),
              ),
            ),
            if (_showOptional) ...[
              const SizedBox(height: 8),
              TextField(
                  controller: _country,
                  decoration: InputDecoration(labelText: _tr('country'))),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime(now.year - 20),
                    firstDate: DateTime(1940),
                    lastDate: now,
                  );
                  if (d != null) setState(() => _birthDate = d);
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: _tr('birthDate')),
                  child: Text(
                    _birthDate == null
                        ? _tr('pick')
                        : _birthDate!.toIso8601String().split('T').first,
                    style: TextStyle(
                        color: _birthDate == null
                            ? AppColors.muted
                            : AppColors.text),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: _tr('whatsapp'),
                      hintText: '+20 / +966 ...')),
            ],
            const SizedBox(height: 14),
          ],
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailLabel)),
          const SizedBox(height: 12),
          if (!_otpMode)
            TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel)),
          if (_otpMode && _otpSent)
            TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.otpHint)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_signUp
                    ? l10n.signUp
                    : (_otpMode
                        ? (_otpSent ? l10n.signIn : l10n.sendCode)
                        : l10n.signIn)),
          ),
          const SizedBox(height: 12),
          if (!_signUp && kOtpLoginEnabled)
            TextButton(
              onPressed: () => setState(() {
                _otpMode = !_otpMode;
                _otpSent = false;
              }),
              child: Text(_otpMode ? l10n.passwordLabel : l10n.sendCode),
            ),
          TextButton(
            onPressed: () => setState(() {
              _signUp = !_signUp;
              _otpMode = false;
            }),
            child: Text(_signUp ? l10n.signIn : l10n.signUp),
          ),
        ],
      ),
    );
  }
}

const Map<String, Map<String, String>> _regStrings = {
  'ar': {
    'gender': 'النوع',
    'male': 'ذكر',
    'female': 'أنثى',
    'chooseGender': 'من فضلك اختر النوع',
    'optional': 'معلومات إضافية (اختيارية)',
    'country': 'الدولة',
    'birthDate': 'تاريخ الميلاد',
    'pick': 'اختر التاريخ',
    'whatsapp': 'رقم واتساب (مع كود الدولة)',
    'errNetwork':
        'تعذّر الاتصال بالخادم. تأكّد من اتصالك بالإنترنت ثم أعد المحاولة.',
    'errBadCredentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'errEmailExists':
        'هذا البريد مسجّل بالفعل. جرّب تسجيل الدخول بدلاً من إنشاء حساب.',
    'errWeakPassword': 'كلمة المرور ضعيفة. استخدم ستة أحرف على الأقل.',
    'errBadEmail': 'البريد الإلكتروني غير صالح. تحقّق من كتابته.',
    'errBadOtp': 'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً.',
    'errNoAccount': 'لا يوجد حساب بهذا البريد الإلكتروني. أنشئ حساباً أولاً.',
    'syncLater':
        'تم تسجيل الدخول بنجاح. تعذّرت مزامنة بياناتك الآن؛ يمكنك تشغيلها لاحقاً من الإعدادات.',
    'errRateLimit':
        'محاولات كثيرة خلال وقت قصير. انتظر قليلاً ثم أعد المحاولة.',
    'errEmailNotConfirmed':
        'البريد الإلكتروني لم يُفعَّل بعد. افتح رسالة التفعيل في بريدك.',
    'errGeneric': 'حدث خطأ غير متوقّع. أعد المحاولة لاحقاً.',
    'confirmEmailSent':
        'تم إنشاء الحساب. أرسلنا رسالة تفعيل إلى بريدك؛ افتحها ثم سجّل الدخول.',
  },
  'en': {
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'chooseGender': 'Please choose your gender',
    'optional': 'Additional info (optional)',
    'country': 'Country',
    'birthDate': 'Date of birth',
    'pick': 'Pick a date',
    'whatsapp': 'WhatsApp number (with country code)',
    'errNetwork':
        'Could not reach the server. Check your internet connection and try again.',
    'errBadCredentials': 'Incorrect email or password.',
    'errEmailExists':
        'This email is already registered. Try signing in instead.',
    'errWeakPassword': 'Password is too weak. Use at least 6 characters.',
    'errBadEmail': 'Invalid email address. Please check the spelling.',
    'errBadOtp': 'The code is invalid or has expired. Request a new one.',
    'errNoAccount': 'No account exists with this email. Create an account first.',
    'syncLater':
        'Signed in successfully. Sync failed for now; you can run it later from Settings.',
    'errRateLimit': 'Too many attempts. Please wait a moment and try again.',
    'errEmailNotConfirmed':
        'Email not confirmed yet. Open the confirmation email in your inbox.',
    'errGeneric': 'Something went wrong. Please try again later.',
    'confirmEmailSent':
        'Account created. We sent a confirmation email; open it, then sign in.',
  },
  'fr': {
    'gender': 'Sexe',
    'male': 'Homme',
    'female': 'Femme',
    'chooseGender': 'Veuillez choisir votre sexe',
    'optional': 'Informations supplémentaires (facultatif)',
    'country': 'Pays',
    'birthDate': 'Date de naissance',
    'pick': 'Choisir une date',
    'whatsapp': 'Numéro WhatsApp (avec indicatif)',
    'errNetwork':
        'Impossible de joindre le serveur. Vérifiez votre connexion internet puis réessayez.',
    'errBadCredentials': 'Email ou mot de passe incorrect.',
    'errEmailExists':
        'Cet email est déjà enregistré. Essayez de vous connecter.',
    'errWeakPassword':
        'Mot de passe trop faible. Utilisez au moins 6 caractères.',
    'errBadEmail': "Adresse email invalide. Vérifiez l'orthographe.",
    'errBadOtp': 'Code invalide ou expiré. Demandez un nouveau code.',
    'errNoAccount':
        "Aucun compte n'existe avec cet email. Créez d'abord un compte.",
    'syncLater':
        'Connexion réussie. La synchronisation a échoué pour le moment ; relancez-la plus tard depuis les réglages.',
    'errRateLimit':
        'Trop de tentatives. Patientez un moment puis réessayez.',
    'errEmailNotConfirmed':
        "Email non confirmé. Ouvrez l'email de confirmation dans votre boîte.",
    'errGeneric': "Une erreur s'est produite. Réessayez plus tard.",
    'confirmEmailSent':
        "Compte créé. Nous avons envoyé un email de confirmation ; ouvrez-le puis connectez-vous.",
  },
};
