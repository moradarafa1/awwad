import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/badge_catalog.dart';
import '../../core/state/app_state.dart';
import 'habit_switcher.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppColors.accent3;
      case 'diamond':
        return AppColors.accent2;
      case 'special':
        return const Color(0xFFA78BFA);
      default:
        return const Color(0xFFCD7F32); // bronze
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final earnedKeys = {for (final b in s.activeBadges) b.badgeKey};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.badgesTitle,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('${earnedKeys.length} / ${kBadges.length}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          const HabitSwitcher(),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: kBadges.map((b) {
              final earned = earnedKeys.contains(b.key);
              final color = _tierColor(b.tier);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: earned
                      ? color.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: earned ? color : AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: earned ? 1 : 0.3,
                      child: Text(b.icon,
                          style: const TextStyle(fontSize: 34)),
                    ),
                    const SizedBox(height: 6),
                    Text(b.t(locale),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: earned
                                ? AppColors.heading
                                : AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(earned ? l10n.badgeEarnedOn : l10n.badgeLocked,
                        style: TextStyle(
                            fontSize: 9,
                            color: earned ? color : AppColors.muted)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
