import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_button.dart';
import 'auth_screen.dart';

/// First screen on a fresh install: sign in / create an account, or continue
/// as a guest (data stays offline on the device). Shown once, then the
/// settings.authChoiceMade flag advances the root gate to onboarding.
///
/// It also requests the permissions the app needs (notifications) up front on
/// first open, with no extra in-app dialog. Internet is granted at install and
/// connectivity needs no permission, so notifications is the only OS prompt.
class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({super.key});
  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  Future<void> _requestPermissions() async {
    final s = ref.read(appControllerProvider);
    if (s.settings.notifPromptShown) return;
    await ensureNotificationPermission(); // OS prompt directly, no extra dialog
    await ref.read(appControllerProvider.notifier).markNotifPromptShown();
  }

  String _s(Map<String, String> m, String loc) => m[loc] ?? m['ar'] ?? '';

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final ctrl = ref.read(appControllerProvider.notifier);
    final canSignIn = SupabaseService.configured;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/logo/mark.png', width: 108, height: 108),
              const SizedBox(height: 14),
              Text(l10n.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.heading)),
              const SizedBox(height: 6),
              Text(l10n.slogan,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.accent2, fontSize: 14)),
              const SizedBox(height: 18),
              Text(_s(_kStr['intro']!, loc),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.muted, height: 1.7, fontSize: 14)),
              const Spacer(),
              if (canSignIn) ...[
                GlassButton(
                  label: _s(_kStr['signin']!, loc),
                  icon: Icons.cloud_sync_outlined,
                  onTap: () async {
                    await ctrl.setAuthChoice(guest: false);
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AuthScreen()));
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
              GlassButton(
                label: _s(_kStr['guest']!, loc),
                primary: false,
                onTap: () => ctrl.setAuthChoice(guest: true),
              ),
              const SizedBox(height: 12),
              Text(_s(_kStr['guestNote']!, loc),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 11, height: 1.5)),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

const Map<String, Map<String, String>> _kStr = {
  'intro': {
    'ar': 'سجّل الدخول لحفظ تقدّمك ومزامنته عبر أجهزتك، أو تابع كزائر والبيانات تُحفظ على جهازك.',
    'en': 'Sign in to save and sync your progress across devices, or continue as a guest with data kept on this device.',
    'fr': 'Connectez-vous pour sauvegarder et synchroniser votre progression, ou continuez en invité avec vos données sur cet appareil.'
  },
  'signin': {
    'ar': 'تسجيل الدخول / إنشاء حساب',
    'en': 'Sign in / Create account',
    'fr': 'Se connecter / Créer un compte'
  },
  'guest': {
    'ar': 'المتابعة كزائر',
    'en': 'Continue as guest',
    'fr': 'Continuer en invité'
  },
  'guestNote': {
    'ar': 'كزائر، بياناتك مخزّنة على هذا الجهاز فقط. يمكنك إنشاء حساب لاحقاً من الإعدادات للمزامنة.',
    'en': 'As a guest, your data is stored on this device only. You can create an account later from Settings to sync.',
    'fr': "En invité, vos données restent sur cet appareil. Vous pourrez créer un compte plus tard dans les Réglages pour synchroniser."
  },
};
