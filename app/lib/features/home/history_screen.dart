import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/state/app_state.dart';
import 'habit_switcher.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(appControllerProvider);
    final entries = s.activeEntries;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.historyTitle,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const HabitSwitcher(),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(l10n.noHistory,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
            )
          else
            ...entries.map((e) {
              final clean = !e.didSlip;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('📅 ${e.date}',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (clean
                                    ? AppColors.success
                                    : AppColors.danger)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: clean
                                    ? AppColors.success
                                    : AppColors.danger),
                          ),
                          child: Text(
                              clean
                                  ? '✅ ${l10n.badgeClean}'
                                  : '⚠️ ${l10n.badgeSlip}',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: clean
                                      ? AppColors.success
                                      : AppColors.danger)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _row(l10n.urgeLevel, '${e.urge}/10'),
                    _row(l10n.resistanceLevel, '${e.resistance}/10'),
                    if (e.moodEmoji != null)
                      _row(l10n.moodLabel, '${e.moodEmoji} ${e.moodLabel ?? ''}'),
                    if (e.note != null && e.note!.isNotEmpty)
                      _row(l10n.noteLabel, e.note!),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(k,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const Spacer(),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
