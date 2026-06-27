import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/state/app_state.dart';

// Optional cloud account screen (P2). Only reachable when SUPABASE_URL/ANON_KEY
// were provided at build time. Implements email+password + an email-OTP path.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _signUp = false;
  bool _otpMode = false;
  bool _otpSent = false;
  bool _busy = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncAfterAuth() async {
    final ctrl = ref.read(appControllerProvider.notifier);
    final snap = await SyncService.pullAll();
    final local = ref.read(appControllerProvider);
    if (local.habit == null && snap.habit != null) {
      await ctrl.importSnapshot(snap.habit!, snap.entries, snap.survey);
    }
    final cur = ref.read(appControllerProvider);
    await SyncService.pushAll(
        habit: cur.habit, entries: cur.entries, survey: cur.survey);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (_signUp) {
      await _run(() async {
        await SupabaseService.signUp(
          name: _name.text.trim(),
          email: email,
          password: _password.text,
          locale: ref.read(appControllerProvider).settings.locale ?? 'ar',
        );
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
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.syncDesc,
              style: const TextStyle(color: AppColors.muted, height: 1.6)),
          const SizedBox(height: 20),
          if (_signUp) ...[
            TextField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.nameLabel)),
            const SizedBox(height: 12),
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
          if (!_signUp)
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
