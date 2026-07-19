import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_button.dart';
import 'auth_screen.dart';

/// First screen on a fresh install: sign in / create an account, or continue
/// as a guest (data stays offline on the device). Shown once, then the
/// settings.authChoiceMade flag advances the root gate to onboarding.
///
/// It requests NO OS permission: the notification prompt moved to the first
/// moment the user actually has a habit with reminder times (see home_shell).
class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({super.key});
  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen> {
  // The notification permission is NO LONGER requested here (SP9). Asking on
  // the very first screen, before the user has any habit or reminder, is the
  // weakest possible moment: the value is unexplained, a denial is permanent
  // on Android 13+, and a cold prompt is a known Apple soft-rejection flag.
  // home_shell now asks the first time the user actually has a habit with
  // reminder times, and Settings re-requests on demand.

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
        // Scrollable + min-height: the fixed Column (logo, slogan, intro, three
        // buttons, guest note) is taller than a 320x640 screen once the OS font
        // is scaled up. The Spacers still center it whenever there IS room.
        child: LayoutBuilder(builder: (context, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - 52),
            // IntrinsicHeight gives the Column a bounded height inside the
            // scroll view, which is what the Spacers need to work.
            child: IntrinsicHeight(
            child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/logo/sprout.png', width: 96, height: 96),
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
                  label: _s(_kStr['create']!, loc),
                  icon: Icons.person_add_alt_1_outlined,
                  onTap: () async {
                    await ctrl.setAuthChoice(guest: false);
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              const AuthScreen(startInSignUp: true)));
                    }
                  },
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: _s(_kStr['signin']!, loc),
                  icon: Icons.cloud_sync_outlined,
                  primary: false,
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
        );
        }),
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
  'create': {
    'ar': 'إنشاء حساب',
    'en': 'Create account',
    'fr': 'Créer un compte'
  },
  'signin': {
    'ar': 'تسجيل الدخول',
    'en': 'Sign in',
    'fr': 'Se connecter'
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
