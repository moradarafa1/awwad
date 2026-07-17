import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/habit_daily_content.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import 'habit_switcher.dart';

/// Embeddable history list for the ACTIVE habit (no header/switcher), so it
/// can be shown inside the Stats screen's «السجل» tab. The standalone
/// HistoryScreen below wraps it with a title + habit switcher.
class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final entries = s.activeEntries;
    final habit = s.activeHabit;
    final metrics = resolveMetrics(
      catalogKey: habit?.catalogKey,
      track: habit?.track ?? 'break',
      customPrimary: habit?.customMetricPrimary,
      customSecondary: habit?.customMetricSecondary,
      generatedOverride: kHabitMetricsOverrides[habit?.catalogKey],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(l10n.noHistory,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          )
        else
          ...entries.map((e) =>
              _historyCard(context, e, l10n, locale, metrics, habit?.track)),
      ],
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final entries = s.activeEntries;
    // Per-habit slider labels (same resolution as the log/stats screens):
    // a build habit must not show break-track labels like "urge level".
    final habit = s.activeHabit;
    final metrics = resolveMetrics(
      catalogKey: habit?.catalogKey,
      track: habit?.track ?? 'break',
      customPrimary: habit?.customMetricPrimary,
      customSecondary: habit?.customMetricSecondary,
      generatedOverride: kHabitMetricsOverrides[habit?.catalogKey],
    );

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
                  style: TextStyle(color: AppColors.muted)),
            )
          else
            ...entries.map((e) =>
                _historyCard(context, e, l10n, locale, metrics, habit?.track)),
        ],
      ),
    );
  }
}

// Build habits are "done / missed", not "clean / slipped": matches the heatmap.
const _kBuildDone = {'ar': 'أُنجزت', 'en': 'Done', 'fr': 'Accomplie'};
const _kBuildMissed = {'ar': 'لم تُنجَز', 'en': 'Missed', 'fr': 'Manquée'};

Widget _historyCard(BuildContext context, DailyEntry e, AppLocalizations l10n,
    String locale, HabitMetrics metrics, String? track) {
  final clean = !e.didSlip;
  final skip = e.isSkip;
  final isBuild = track == 'build';
  final goodLabel =
      isBuild ? (_kBuildDone[locale] ?? _kBuildDone['ar']!) : l10n.badgeClean;
  final badLabel = isBuild
      ? (_kBuildMissed[locale] ?? _kBuildMissed['ar']!)
      : l10n.badgeSlip;
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
            Expanded(
              child: Text('📅 ${e.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (skip
                        ? AppColors.muted
                        : (clean ? AppColors.success : AppColors.danger))
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: skip
                        ? AppColors.muted
                        : (clean ? AppColors.success : AppColors.danger)),
              ),
              child: Text(
                  skip
                      ? '➖'
                      : (clean ? '✅ $goodLabel' : '⚠️ $badLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: skip
                          ? AppColors.muted
                          : (clean
                              ? AppColors.success
                              : AppColors.danger))),
              ),
            ),
          ],
        ),
        if (!skip) ...[
          const SizedBox(height: 8),
          _row(metrics.primary.l(locale), '${e.urge}/10'),
          _row(metrics.secondary.l(locale), '${e.resistance}/10'),
          if (e.moodEmoji != null)
            _row(l10n.moodLabel, '${e.moodEmoji} ${e.moodLabel ?? ''}'),
          if (e.note != null && e.note!.isNotEmpty)
            _row(l10n.noteLabel, e.note!),
        ],
      ],
    ),
  );
}

// Key on the start, value on the end. BOTH sides must flex: the key can be a
// long (or user-typed) metric label and the value can be a whole note.
Widget _row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(k,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(v,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
