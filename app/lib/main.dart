import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/l10n/app_localizations.dart';
import 'app/theme.dart';
import 'core/analytics/analytics.dart';
import 'core/cloud/supabase_service.dart';
import 'core/data/local_store.dart';
import 'core/state/app_state.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/language_screen.dart';
import 'features/home/home_shell.dart';
import 'features/auth/auth_choice_screen.dart';

void main() {
  // runZonedGuarded so that any async error from optional cloud init (or any
  // plugin) can NEVER tear down the offline-first UI.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(prefs);
    AnalyticsService.instance.track('app_opened', {
      'is_first_open':
          store.loadHabits().isEmpty && store.loadLegacyHabit() == null
    });

    // Paint the UI FIRST — the app is fully usable offline.
    runApp(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const AwwadApp(),
      ),
    );

    // Initialize cloud AFTER the first frame; failures are swallowed by the zone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(SupabaseService.init());
    });
  }, (error, stack) {
    // Cloud/async errors must not crash the app. (Logged in debug only.)
    debugPrint('Awwad zone error (ignored): $error');
  });
}

class AwwadApp extends ConsumerWidget {
  const AwwadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appControllerProvider).settings;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildAwwadTheme(),
      locale: settings.locale != null ? Locale(settings.locale!) : null,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    // 1) Pick a language. 2) Sign-in vs continue-as-guest. 3) Onboarding / home.
    if (state.settings.locale == null) return const LanguageScreen();
    if (!state.settings.authChoiceMade) return const AuthChoiceScreen();
    final ready = state.settings.onboardingDone && state.habits.isNotEmpty;
    return ready ? const HomeShell() : const OnboardingFlow();
  }
}
