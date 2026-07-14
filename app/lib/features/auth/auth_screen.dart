import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/net_errors.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';

/// Which top-level flow the screen is showing.
enum _AuthMode { signIn, signUp, reset }

// Cloud account screen (P2). Only reachable when SUPABASE_URL/ANON_KEY were
// provided at build time. Flows:
//   - sign-in: email + password (+ "forgot password?" -> reset flow)
//   - sign-up: form -> emailed verification CODE -> verify -> session
//   - reset:   email -> emailed reset CODE -> code + new password -> session
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
  late _AuthMode _mode =
      widget.startInSignUp ? _AuthMode.signUp : _AuthMode.signIn;
  bool _codeStep = false; // signUp: verify code; reset: code + new password
  bool _busy = false;
  // Eye toggle: show/hide the password (visible text is also copyable).
  bool _obscurePassword = true;
  // The recovery code is ONE-TIME: verifyOTP consumes it and signs the user
  // in even if the subsequent updateUser fails (e.g. same_password). Track
  // that so a retry goes straight to changePassword instead of re-consuming
  // the burned code and dead-ending on otp_expired.
  bool _recoveryVerified = false;
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

  Widget _eyeToggle() => IconButton(
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: AppColors.muted),
      );

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
    if (s.contains('same_password') ||
        s.contains('different from the old')) {
      return _tr('errSamePassword');
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
    if (s.contains('user not found') ||
        s.contains('user_not_found') ||
        s.contains('otp_disabled') ||
        s.contains('signups not allowed')) {
      return _tr('errNoAccount');
    }
    if (s.contains('otp_expired') ||
        s.contains('token has expired') ||
        s.contains('invalid token') ||
        s.contains('invalid otp')) {
      return _tr('errBadOtp');
    }
    if (s.contains('rate limit') ||
        s.contains('rate_limit') ||
        s.contains('you can only request this after') ||
        s.contains('too many requests')) {
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
      // mounted guard: _friendlyError -> _tr reads State.context, which is
      // gone if the user backed out while the request was in flight.
      if (mounted) _toast(_friendlyError(e));
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
    if (!syncOk && mounted) _toast(_tr('syncLater'));
    if (mounted) Navigator.of(context).pop();
  }

  // ---- flow steps ----

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  Future<void> _submitSignUpForm() async {
    // Required-field checks, in visual order, each with the conventional
    // toast (fields are starred; the toast fires only when one is missed).
    if (_name.text.trim().isEmpty) {
      _toast(_tr('nameRequired'));
      return;
    }
    final emailText = _email.text.trim();
    if (emailText.isEmpty) {
      _toast(_tr('emailRequired'));
      return;
    }
    if (!_emailRe.hasMatch(emailText)) {
      _toast(_tr('errBadEmail'));
      return;
    }
    if (_password.text.length < 6) {
      _toast(_tr('errWeakPassword'));
      return;
    }
    if (_gender == null) {
      _toast(_tr('chooseGender'));
      return;
    }
    await _run(() async {
      final res = await SupabaseService.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        gender: _gender!,
        locale: ref.read(appControllerProvider).settings.locale ?? 'ar',
        country: _country.text.trim().isEmpty ? null : _country.text.trim(),
        birthDate: _birthDate?.toIso8601String().split('T').first,
        whatsapp: _whatsapp.text.trim().isEmpty
            ? null
            : _normDigits(_whatsapp.text.trim()),
      );
      if (SupabaseService.signUpHitExistingEmail(res)) {
        // Confirmed account already exists for this email: no code was sent.
        throw Exception('signup failed: user_already_exists');
      }
      if (res.session != null) {
        // Server had auto-confirm on: signed in directly.
        AnalyticsService.instance
            .track('signup_succeeded', {'method': 'email'});
        await _syncAfterAuth();
        return;
      }
      // Verification code sent (or re-sent for an unconfirmed account).
      AnalyticsService.instance.track('otp_sent');
      _otp.clear();
      if (!mounted) return;
      setState(() => _codeStep = true);
      _toast(_tr('codeSentInfo'));
    });
  }

  Future<void> _submitSignUpCode() async {
    final code = _normDigits(_otp.text.trim());
    if (code.isEmpty) {
      _toast(_tr('errBadOtp'));
      return;
    }
    await _run(() async {
      await SupabaseService.verifySignupCode(_email.text.trim(), code);
      AnalyticsService.instance.track('otp_verified', {'success': true});
      // Reconcile the password with what the user just typed: when the email
      // belonged to an EXISTING UNCONFIRMED account, GoTrue ignored the new
      // password at signUp ("can't be sure of their claimed identity"), so
      // without this the stored password would silently stay the OLD one and
      // the next sign-in with the just-typed password would fail. For a
      // fresh signup this is a same_password no-op rejection - swallowed.
      if (_password.text.length >= 6) {
        try {
          await SupabaseService.changePassword(_password.text);
        } catch (_) {}
      }
      AnalyticsService.instance.track('signup_succeeded', {'method': 'email'});
      await _syncAfterAuth();
    });
  }

  Future<void> _resendSignUpCode() async {
    await _run(() async {
      await SupabaseService.resendSignupCode(_email.text.trim());
      AnalyticsService.instance.track('otp_sent');
      if (mounted) _toast(_tr('codeSentInfo'));
    });
  }

  Future<void> _submitSignIn() async {
    if (_email.text.trim().isEmpty) {
      _toast(_tr('emailRequired'));
      return;
    }
    if (_password.text.isEmpty) {
      _toast(_tr('passwordRequired'));
      return;
    }
    await _run(() async {
      try {
        await SupabaseService.signInWithPassword(
            _email.text.trim(), _password.text);
      } on AuthException catch (e) {
        final s = '${e.message} ${e.code ?? ''}'.toLowerCase();
        if (s.contains('not confirmed') || s.contains('email_not_confirmed')) {
          // Account exists but the email was never verified: re-send the
          // code and jump straight to the verification step.
          try {
            await SupabaseService.resendSignupCode(_email.text.trim());
          } catch (_) {}
          _otp.clear();
          if (!mounted) return;
          setState(() {
            _mode = _AuthMode.signUp;
            _codeStep = true;
          });
          _toast(_tr('confirmFirst'));
          return;
        }
        rethrow;
      }
      AnalyticsService.instance.track(
          'login_succeeded', {'otp_required': false, 'trusted_device': false});
      await _syncAfterAuth();
    });
  }

  Future<void> _submitResetEmail() async {
    final emailText = _email.text.trim();
    if (emailText.isEmpty) {
      _toast(_tr('emailRequired'));
      return;
    }
    if (!_emailRe.hasMatch(emailText)) {
      _toast(_tr('errBadEmail'));
      return;
    }
    await _run(() async {
      await SupabaseService.sendPasswordResetCode(_email.text.trim());
      AnalyticsService.instance.track('otp_sent');
      _otp.clear();
      _password.clear();
      _recoveryVerified = false; // a fresh code invalidates prior progress
      if (!mounted) return;
      setState(() => _codeStep = true);
      _toast(_tr('resetSentNote'));
    });
  }

  // Reset is TWO screens: (1) enter the code only -> verify; (2) once the
  // code is verified, enter the new password only. Splitting keeps each step
  // focused and matches conventional reset UX.
  Future<void> _submitResetCode() async {
    // Step 1: verify the emailed code (OTP field only on screen).
    if (!_recoveryVerified) {
      final code = _normDigits(_otp.text.trim());
      if (code.isEmpty) {
        _toast(_tr('errBadOtp'));
        return;
      }
      await _run(() async {
        await SupabaseService.verifyRecoveryCode(_email.text.trim(), code);
        AnalyticsService.instance.track('otp_verified', {'success': true});
        if (!mounted) return;
        setState(() {
          _recoveryVerified = true; // reveal the new-password field
          _obscurePassword = true;
          _password.clear();
        });
        _toast(_tr('resetEnterNewPw'));
      });
      return;
    }
    // Step 2: set the new password. The code was already consumed, so a
    // failed updateUser retry must NOT re-verify (we stay signed in).
    if (_password.text.length < 6) {
      _toast(_tr('errWeakPassword'));
      return;
    }
    await _run(() async {
      await SupabaseService.changePassword(_password.text);
      AnalyticsService.instance.track(
          'login_succeeded', {'otp_required': true, 'trusted_device': false});
      if (mounted) _toast(_tr('resetDone'));
      await _syncAfterAuth();
    });
  }

  Future<void> _submit() async {
    switch (_mode) {
      case _AuthMode.signUp:
        _codeStep ? await _submitSignUpCode() : await _submitSignUpForm();
      case _AuthMode.signIn:
        await _submitSignIn();
      case _AuthMode.reset:
        _codeStep ? await _submitResetCode() : await _submitResetEmail();
    }
  }

  String _title(AppLocalizations l10n) {
    switch (_mode) {
      case _AuthMode.signUp:
        return l10n.signUp;
      case _AuthMode.signIn:
        return l10n.signIn;
      case _AuthMode.reset:
        return _tr('resetTitle');
    }
  }

  String _submitLabel(AppLocalizations l10n) {
    switch (_mode) {
      case _AuthMode.signUp:
        return _codeStep ? _tr('verifyCreate') : l10n.signUp;
      case _AuthMode.signIn:
        return l10n.signIn;
      case _AuthMode.reset:
        if (!_codeStep) return l10n.sendCode;
        return _recoveryVerified ? _tr('resetApply') : _tr('verifyCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inCode = _codeStep && _mode != _AuthMode.signIn;
    return Scaffold(
      appBar: AppBar(title: Text(_title(l10n))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_mode == _AuthMode.signIn || _mode == _AuthMode.signUp && !inCode)
            Text(l10n.syncDesc,
                style: TextStyle(color: AppColors.muted, height: 1.6)),
          if (_mode == _AuthMode.reset && !inCode)
            Text(_tr('resetInfo'),
                style: TextStyle(color: AppColors.muted, height: 1.6)),
          if (inCode) ...[
            Text(
                _mode == _AuthMode.signUp
                    ? _tr('codeSentInfo')
                    : (_recoveryVerified
                        ? _tr('resetNewPwInfo')
                        : _tr('resetCodeInfo')),
                style: TextStyle(color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 8),
            Text(_email.text.trim(),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.heading, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 20),
          // Sign-up form, CONVENTIONAL order: required identity+credentials
          // first (all starred), the optional extras collapsed at the END so
          // nothing required ever renders under an "optional" header.
          if (_mode == _AuthMode.signUp && !inCode) ...[
            TextField(
                controller: _name,
                decoration:
                    InputDecoration(labelText: '${l10n.nameLabel} *')),
            const SizedBox(height: 12),
          ],
          if (!inCode) ...[
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: _mode == _AuthMode.signUp
                        ? '${l10n.emailLabel} *'
                        : l10n.emailLabel)),
            const SizedBox(height: 12),
          ],
          if (_mode != _AuthMode.reset && !inCode)
            TextField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                    labelText: _mode == _AuthMode.signUp
                        ? '${l10n.passwordLabel} *'
                        : l10n.passwordLabel,
                    suffixIcon: _eyeToggle())),
          if (_mode == _AuthMode.signUp && !inCode) ...[
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
                  Expanded(
                    child: Text(_tr('optional'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted)),
                  ),
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
          ],
          if (inCode) ...[
            // Reset step 2 = new-password ONLY; otherwise (signup code, reset
            // step 1) = OTP field ONLY.
            if (_mode == _AuthMode.reset && _recoveryVerified)
              TextField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                      labelText: _tr('newPassword'),
                      suffixIcon: _eyeToggle()))
            else
              TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.otpHint)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_submitLabel(l10n)),
          ),
          const SizedBox(height: 12),
          if (inCode) ...[
            // "Resend" only makes sense while still awaiting/entering a code
            // (not on reset step 2 where the code was already consumed).
            if (!(_mode == _AuthMode.reset && _recoveryVerified))
              TextButton(
                onPressed: _busy
                    ? null
                    : (_mode == _AuthMode.signUp
                        ? _resendSignUpCode
                        : _submitResetEmail),
                child: Text(_tr('resendCode')),
              ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _codeStep = false;
                        _recoveryVerified = false;
                      }),
              child: Text(_tr('back')),
            ),
          ] else ...[
            if (_mode == _AuthMode.signIn)
              TextButton(
                onPressed: () => setState(() {
                  _mode = _AuthMode.reset;
                  _codeStep = false;
                }),
                child: Text(_tr('forgotPassword')),
              ),
            if (_mode == _AuthMode.reset)
              TextButton(
                onPressed: () => setState(() {
                  _mode = _AuthMode.signIn;
                  _codeStep = false;
                }),
                child: Text(l10n.signIn),
              )
            else
              TextButton(
                onPressed: () => setState(() {
                  _mode = _mode == _AuthMode.signUp
                      ? _AuthMode.signIn
                      : _AuthMode.signUp;
                  _codeStep = false;
                }),
                child:
                    Text(_mode == _AuthMode.signUp ? l10n.signIn : l10n.signUp),
              ),
          ],
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
    'nameRequired': 'من فضلك اكتب اسمك.',
    'emailRequired': 'البريد الإلكتروني مطلوب.',
    'passwordRequired': 'أدخل كلمة المرور.',
    'optional': 'معلومات إضافية (اختيارية)',
    'country': 'الدولة',
    'birthDate': 'تاريخ الميلاد',
    'pick': 'اختر التاريخ',
    'whatsapp': 'رقم واتساب (مع كود الدولة)',
    'codeSentInfo':
        'أرسلنا رمز تحقق إلى بريدك الإلكتروني. افتح بريدك (وتحقق من مجلد الرسائل غير المرغوبة) ثم أدخل الرمز هنا.',
    'verifyCreate': 'تأكيد الرمز وإنشاء الحساب',
    'resendCode': 'لم يصلك الرمز؟ أعد الإرسال',
    'back': 'رجوع',
    'forgotPassword': 'نسيت كلمة المرور؟',
    'resetTitle': 'إعادة تعيين كلمة المرور',
    'resetInfo':
        'أدخل بريدك الإلكتروني وسنرسل إليك رمزاً لتعيين كلمة مرور جديدة.',
    'resetSentNote':
        'إن كان البريد مسجّلاً لدينا فستصلك رسالة بالرمز خلال لحظات. تحقق أيضاً من مجلد الرسائل غير المرغوبة.',
    'resetCodeInfo': 'أدخل الرمز المرسل إلى بريدك الإلكتروني.',
    'resetNewPwInfo': 'تم التحقق من الرمز. اكتب الآن كلمة المرور الجديدة.',
    'resetEnterNewPw': 'تم التحقق من الرمز. اكتب كلمة المرور الجديدة.',
    'verifyCode': 'تأكيد الرمز',
    'newPassword': 'كلمة المرور الجديدة',
    'resetApply': 'تعيين كلمة المرور والدخول',
    'resetDone': 'تم تغيير كلمة المرور وتسجيل دخولك بنجاح.',
    'confirmFirst':
        'حسابك بحاجة إلى تأكيد البريد أولاً. أرسلنا رمزاً جديداً إلى بريدك؛ أدخله هنا.',
    'errNetwork':
        'تعذّر الاتصال بالخادم. تأكّد من اتصالك بالإنترنت ثم أعد المحاولة.',
    'errBadCredentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    'errEmailExists':
        'هذا البريد مسجّل بالفعل. جرّب تسجيل الدخول بدلاً من إنشاء حساب.',
    'errWeakPassword': 'كلمة المرور ضعيفة. استخدم ستة أحرف على الأقل.',
    'errSamePassword': 'كلمة المرور الجديدة يجب أن تختلف عن القديمة.',
    'errBadEmail': 'البريد الإلكتروني غير صالح. تحقّق من كتابته.',
    'errBadOtp': 'الرمز غير صحيح أو انتهت صلاحيته. اطلب رمزاً جديداً.',
    'errNoAccount': 'لا يوجد حساب بهذا البريد الإلكتروني. أنشئ حساباً أولاً.',
    'errRateLimit':
        'محاولات كثيرة خلال وقت قصير. انتظر قليلاً ثم أعد المحاولة.',
    'errEmailNotConfirmed':
        'البريد الإلكتروني لم يُؤكَّد بعد. أدخل الرمز المرسل إلى بريدك.',
    'errGeneric': 'حدث خطأ غير متوقّع. أعد المحاولة لاحقاً.',
    'syncLater':
        'تم تسجيل الدخول بنجاح. تعذّرت مزامنة بياناتك الآن؛ يمكنك تشغيلها لاحقاً من الإعدادات.',
  },
  'en': {
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'chooseGender': 'Please choose your gender',
    'nameRequired': 'Please enter your name.',
    'emailRequired': 'Email is required.',
    'passwordRequired': 'Enter your password.',
    'optional': 'Additional info (optional)',
    'country': 'Country',
    'birthDate': 'Date of birth',
    'pick': 'Pick a date',
    'whatsapp': 'WhatsApp number (with country code)',
    'codeSentInfo':
        'We sent a verification code to your email. Open your inbox (check spam too) and enter the code here.',
    'verifyCreate': 'Verify code & create account',
    'resendCode': "Didn't get the code? Resend",
    'back': 'Back',
    'forgotPassword': 'Forgot your password?',
    'resetTitle': 'Reset password',
    'resetInfo':
        "Enter your email and we'll send you a code to set a new password.",
    'resetSentNote':
        'If this email is registered, a code is on its way. Check your spam folder too.',
    'resetCodeInfo': 'Enter the code we sent to your email.',
    'resetNewPwInfo': 'Code verified. Now type your new password.',
    'resetEnterNewPw': 'Code verified. Type your new password.',
    'verifyCode': 'Verify code',
    'newPassword': 'New password',
    'resetApply': 'Set password & sign in',
    'resetDone': 'Password changed and you are signed in.',
    'confirmFirst':
        'Your account needs email confirmation first. We sent a new code to your email; enter it here.',
    'errNetwork':
        'Could not reach the server. Check your internet connection and try again.',
    'errBadCredentials': 'Incorrect email or password.',
    'errEmailExists':
        'This email is already registered. Try signing in instead.',
    'errWeakPassword': 'Password is too weak. Use at least 6 characters.',
    'errSamePassword': 'The new password must differ from the old one.',
    'errBadEmail': 'Invalid email address. Please check the spelling.',
    'errBadOtp': 'The code is invalid or has expired. Request a new one.',
    'errNoAccount': 'No account exists with this email. Create an account first.',
    'errRateLimit': 'Too many attempts. Please wait a moment and try again.',
    'errEmailNotConfirmed':
        'Email not confirmed yet. Enter the code we sent to your inbox.',
    'errGeneric': 'Something went wrong. Please try again later.',
    'syncLater':
        'Signed in successfully. Sync failed for now; you can run it later from Settings.',
  },
  'fr': {
    'gender': 'Sexe',
    'male': 'Homme',
    'female': 'Femme',
    'chooseGender': 'Veuillez choisir votre sexe',
    'nameRequired': 'Veuillez saisir votre nom.',
    'emailRequired': "L'email est requis.",
    'passwordRequired': 'Saisissez votre mot de passe.',
    'optional': 'Informations supplémentaires (facultatif)',
    'country': 'Pays',
    'birthDate': 'Date de naissance',
    'pick': 'Choisir une date',
    'whatsapp': 'Numéro WhatsApp (avec indicatif)',
    'codeSentInfo':
        'Nous avons envoyé un code de vérification à votre email. Ouvrez votre boîte (vérifiez aussi les spams) puis saisissez le code ici.',
    'verifyCreate': 'Vérifier le code et créer le compte',
    'resendCode': 'Code non reçu ? Renvoyer',
    'back': 'Retour',
    'forgotPassword': 'Mot de passe oublié ?',
    'resetTitle': 'Réinitialiser le mot de passe',
    'resetInfo':
        'Saisissez votre email et nous vous enverrons un code pour définir un nouveau mot de passe.',
    'resetSentNote':
        'Si cet email est enregistré, un code est en route. Vérifiez aussi vos spams.',
    'resetCodeInfo': 'Saisissez le code envoyé à votre email.',
    'resetNewPwInfo': 'Code vérifié. Saisissez votre nouveau mot de passe.',
    'resetEnterNewPw': 'Code vérifié. Saisissez votre nouveau mot de passe.',
    'verifyCode': 'Vérifier le code',
    'newPassword': 'Nouveau mot de passe',
    'resetApply': 'Définir le mot de passe et se connecter',
    'resetDone': 'Mot de passe changé, vous êtes connecté.',
    'confirmFirst':
        "Votre compte doit d'abord être confirmé. Nous avons envoyé un nouveau code à votre email ; saisissez-le ici.",
    'errNetwork':
        'Impossible de joindre le serveur. Vérifiez votre connexion internet puis réessayez.',
    'errBadCredentials': 'Email ou mot de passe incorrect.',
    'errEmailExists':
        'Cet email est déjà enregistré. Essayez de vous connecter.',
    'errWeakPassword':
        'Mot de passe trop faible. Utilisez au moins 6 caractères.',
    'errSamePassword':
        "Le nouveau mot de passe doit différer de l'ancien.",
    'errBadEmail': "Adresse email invalide. Vérifiez l'orthographe.",
    'errBadOtp': 'Code invalide ou expiré. Demandez un nouveau code.',
    'errNoAccount':
        "Aucun compte n'existe avec cet email. Créez d'abord un compte.",
    'errRateLimit':
        'Trop de tentatives. Patientez un moment puis réessayez.',
    'errEmailNotConfirmed':
        'Email non confirmé. Saisissez le code envoyé à votre boîte.',
    'errGeneric': "Une erreur s'est produite. Réessayez plus tard.",
    'syncLater':
        'Connexion réussie. La synchronisation a échoué pour le moment ; relancez-la plus tard depuis les réglages.',
  },
};
