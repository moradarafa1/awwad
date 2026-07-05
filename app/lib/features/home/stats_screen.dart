import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/habit_daily_content.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import 'habit_switcher.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final recent = s.activeEntries.take(7).toList().reversed.toList();
    final habit = s.activeHabit;
    final metrics = kHabitMetricsOverrides[habit?.catalogKey] ??
        metricsForHabit(habit?.catalogKey, habit?.track ?? 'break');
    final last7 = const {
      'ar': 'آخر ٧ أيام',
      'en': 'last 7 days',
      'fr': '7 derniers jours'
    }[locale] ?? 'last 7 days';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.navStats,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const HabitSwitcher(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '${s.currentStreak}',
                      label: l10n.statsCurrentStreak,
                      color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.longestStreak}',
                      label: l10n.statsLongestStreak,
                      color: AppColors.accent3)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.weekNumber}',
                      label: l10n.statsWeek,
                      color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${metrics.primary.l(locale)} - $last7',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: recent.isEmpty
                      ? Center(
                          child: Text('·',
                              style: TextStyle(color: AppColors.muted)))
                      : BarChart(
                          BarChartData(
                            maxY: 10,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false)),
                            ),
                            barGroups: [
                              for (var i = 0; i < recent.length; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: recent[i].urge.toDouble(),
                                    width: 18,
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(4)),
                                    color: recent[i].didSlip
                                        ? AppColors.accent3
                                        : AppColors.success,
                                  )
                                ]),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: s.avgUrge.toStringAsFixed(1),
                      label: metrics.primary.l(locale),
                      color: AppColors.accent3)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: s.avgResistance.toStringAsFixed(1),
                      label: metrics.secondary.l(locale),
                      color: AppColors.accent2)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.cleanDays}/${s.daysLogged}',
                      label: l10n.statsCleanDays,
                      color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}
