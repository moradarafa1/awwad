import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:awwad/app/theme.dart';
import 'package:awwad/core/data/local_store.dart';
import 'package:awwad/core/models.dart';
import 'package:awwad/core/state/app_state.dart';
import 'package:awwad/l10n/app_localizations.dart';
import 'package:awwad/features/onboarding/onboarding_flow.dart';

// Owner instruction 2026-07-20: a user who chose «متابعة كزائر» must NOT be
// asked the profile survey. Gender, age range, country and the research
// consent are ACCOUNT data; with no account there is nothing to attach them
// to, so the question is a pure barrier.
//
// With Supabase unconfigured (the default in tests) SupabaseService.signedIn
// is false, which is exactly the guest case.
void main() {
  Future<void> pumpOnboarding(WidgetTester tester, Locale locale) async {
    SharedPreferences.setMockInitialValues({
      'awwad_settings': jsonEncode(
          AppSettings(locale: locale.languageCode, authChoiceMade: true)
              .toJson()),
    });
    final store = LocalStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        locale: locale,
        theme: buildAwwadTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingFlow(),
      ),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  for (final locale in const [Locale('ar'), Locale('en'), Locale('fr')]) {
    testWidgets('guest never sees the survey step (${locale.languageCode})',
        (tester) async {
      await pumpOnboarding(tester, locale);
      final l10n = await AppLocalizations.delegate.load(locale);

      // The survey title must be absent on the very first screen...
      expect(find.text(l10n.surveyTitle), findsNothing,
          reason: 'a guest was shown the account survey');
      // ...and so must the research-consent notice that lives with it.
      expect(find.text(l10n.surveyConsent), findsNothing,
          reason: 'a guest was shown the research consent notice');

      // The first thing a guest sees is the track choice instead.
      expect(find.text(l10n.chooseTrackTitle), findsOneWidget,
          reason: 'a guest should land straight on the track step');
    });
  }

  testWidgets('the guest flow is four steps, and the progress bar agrees',
      (tester) async {
    await pumpOnboarding(tester, const Locale('ar'));
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    // One segment per step: track, habit, setup, location (the location step
    // was added 2026-07-31 - country, nearest city, GPS). Five segments would
    // mean the skipped survey is still counted even though it never renders.
    final segments = tester
        .widgetList<Expanded>(find.descendant(
          of: find.byType(Row).first,
          matching: find.byType(Expanded),
        ))
        .length;
    expect(segments, 4, reason: 'progress bar disagrees with the step list');

    // Step 1 of 4 is the track step, so the button still says «التالي».
    expect(find.text(l10n.next), findsOneWidget);
    expect(find.text(l10n.startJourney), findsNothing);
  });
}
