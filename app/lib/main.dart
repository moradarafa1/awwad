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
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs);
  // Cloud auth/sync is optional — no-op unless SUPABASE_URL/ANON_KEY are defined.
  await SupabaseService.init();
  AnalyticsService.instance
      .track('app_opened', {'is_first_open': store.loadHabit() == null});

  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const AwwadApp(),
    ),
  );
}

class AwwadApp extends ConsumerWidget {
  const AwwadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appControllerProvider).settings;
    return MaterialApp(
      title: 'Awwad',
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
    final ready = state.settings.onboardingDone && state.habit != null;
    return ready ? const HomeShell() : const OnboardingFlow();
  }
}
