import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/glass_button.dart';

/// First screen on a fresh install: pick the language. Choosing one sets the
/// locale, after which the root gate advances to the sign-in / guest choice.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ctrl = ref.read(appControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              const Text('🌱', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 14),
              Text(l10n.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.heading)),
              const SizedBox(height: 6),
              Text(l10n.slogan,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.accent2, fontSize: 14)),
              const SizedBox(height: 28),
              Text(l10n.chooseLanguage,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 14),
              GlassButton(
                  label: 'العربية',
                  onTap: () => ctrl.setLocale('ar')),
              const SizedBox(height: 12),
              GlassButton(
                  label: 'English',
                  primary: false,
                  onTap: () => ctrl.setLocale('en')),
              const SizedBox(height: 12),
              GlassButton(
                  label: 'Français',
                  primary: false,
                  onTap: () => ctrl.setLocale('fr')),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.accent3, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.medicalDisclaimer,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted, height: 1.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
