import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart' show HabitMetrics;
import '../../core/models.dart';

/// Advanced analytics for the active habit: 30-day metric trend, weekday
/// success analysis with an insight line, week-over-week comparison, and a
/// mood distribution. Pure widget - all data passed in, no providers.
class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({
    super.key,
    required this.entries, // active habit, newest first
    required this.track,
    required this.metrics,
  });

  final List<DailyEntry> entries;
  final String track;
  final HabitMetrics metrics;

  String _tr(BuildContext context, String k) =>
      (_anStrings[Localizations.localeOf(context).languageCode] ??
          _anStrings['en']!)[k]!;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).languageCode;

    // ---- 30-day trend data ----
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final byDay = {for (final e in entries) e.date: e};
    final p = <FlSpot>[];
    final s = <FlSpot>[];
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final e = byDay[key];
      if (e != null) {
        p.add(FlSpot(i.toDouble(), e.urge.toDouble()));
        s.add(FlSpot(i.toDouble(), e.resistance.toDouble()));
      }
    }

    // ---- weekday success analysis (DateTime.weekday 1=Mon..7=Sun) ----
    final loggedPerDow = List.filled(7, 0);
    final cleanPerDow = List.filled(7, 0);
    for (final e in entries) {
      final parts = e.date.split('-').map(int.parse).toList();
      final dow = DateTime(parts[0], parts[1], parts[2]).weekday - 1;
      loggedPerDow[dow]++;
      if (!e.didSlip) cleanPerDow[dow]++;
    }
    int? worstDow;
    double worstRate = 1.01;
    for (var i = 0; i < 7; i++) {
      if (loggedPerDow[i] < 2) continue; // not enough signal
      final rate = cleanPerDow[i] / loggedPerDow[i];
      if (rate < worstRate) {
        worstRate = rate;
        worstDow = i;
      }
    }

    // ---- week-over-week clean days ----
    int cleanIn(DateTime from, DateTime to) {
      var c = 0;
      for (final e in entries) {
        final parts = e.date.split('-').map(int.parse).toList();
        final d = DateTime(parts[0], parts[1], parts[2]);
        if (!d.isBefore(from) && d.isBefore(to) && !e.didSlip) c++;
      }
      return c;
    }

    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = cleanIn(today.subtract(const Duration(days: 6)),
        today.add(const Duration(days: 1)));
    final lastWeek = cleanIn(today.subtract(const Duration(days: 13)),
        today.subtract(const Duration(days: 6)));
    final delta = thisWeek - lastWeek;

    // ---- mood distribution ----
    final moodCounts = <String, int>{};
    for (final e in entries.take(60)) {
      final m = e.moodEmoji;
      if (m != null && m.isNotEmpty) {
        moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      }
    }
    final topMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final weekdayNames = MaterialLocalizations.of(context).narrowWeekdays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 30-day trend.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr(context, 'trendTitle'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(spacing: 14, children: [
                _legend(metrics.primary.l(locale), AppColors.accent3),
                _legend(metrics.secondary.l(locale), AppColors.accent2),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: p.isEmpty
                    ? Center(
                        child: Text(_tr(context, 'noData'),
                            style: TextStyle(color: AppColors.muted)))
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 29,
                          minY: 0,
                          maxY: 10,
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData:
                              const LineTouchData(enabled: false),
                          lineBarsData: [
                            _line(p, AppColors.accent3),
                            _line(s, AppColors.accent2),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Weekday analysis + week comparison.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr(context, 'dowTitle'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 52,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 14,
                                height: loggedPerDow[i] == 0
                                    ? 3
                                    : 6 +
                                        46 *
                                            (cleanPerDow[i] /
                                                loggedPerDow[i]),
                                decoration: BoxDecoration(
                                  color: loggedPerDow[i] == 0
                                      ? AppColors.border
                                      : (i == worstDow
                                          ? AppColors.danger
                                          : AppColors.accent2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // narrowWeekdays is indexed 0=Sun..6=Sat.
                          Text(weekdayNames[(i + 1) % 7],
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.muted)),
                        ],
                      ),
                    ),
                ],
              ),
              if (worstDow != null && worstRate < 0.999) ...[
                const SizedBox(height: 10),
                Text(
                  '${_tr(context, 'worstDay')}: ${_fullWeekday(context, worstDow)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (delta >= 0 ? AppColors.success : AppColors.accent3)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  delta >= 0
                      ? '${_tr(context, 'weekBetter')} (+$delta)'
                      : '${_tr(context, 'weekWorse')} ($delta)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: delta >= 0
                          ? AppColors.success
                          : AppColors.accent3),
                ),
              ),
            ],
          ),
        ),
        if (topMoods.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr(context, 'moodTitle'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final m in topMoods.take(5))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text('${m.key} ×${m.value}',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.text)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.25,
        color: color,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
            show: true, color: color.withValues(alpha: 0.08)),
      );

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 3,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      );

  /// Full localized weekday name for insight text (dow 0=Mon..6=Sun).
  String _fullWeekday(BuildContext context, int dow) {
    const names = {
      'ar': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
      'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'fr': ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'],
    };
    final loc = Localizations.localeOf(context).languageCode;
    return (names[loc] ?? names['en']!)[dow];
  }
}

const Map<String, Map<String, String>> _anStrings = {
  'ar': {
    'trendTitle': 'اتجاه آخر ٣٠ يوماً',
    'noData': 'لا توجد تسجيلات في آخر ٣٠ يوماً.',
    'dowTitle': 'نسبة نجاحك حسب يوم الأسبوع',
    'worstDay': 'أكثر أيامك حاجة للانتباه',
    'weekBetter': 'هذا الأسبوع أفضل من الماضي',
    'weekWorse': 'هذا الأسبوع أقل من الماضي، لا بأس، واصل',
    'moodTitle': 'مزاجك الأكثر تكراراً',
  },
  'en': {
    'trendTitle': 'Last 30 days trend',
    'noData': 'No entries in the last 30 days.',
    'dowTitle': 'Success rate by weekday',
    'worstDay': 'Your most challenging day',
    'weekBetter': 'This week beats last week',
    'weekWorse': 'This week is below last week, keep going',
    'moodTitle': 'Your most frequent moods',
  },
  'fr': {
    'trendTitle': 'Tendance des 30 derniers jours',
    'noData': 'Aucune entrée sur les 30 derniers jours.',
    'dowTitle': 'Taux de réussite par jour de semaine',
    'worstDay': 'Votre jour le plus difficile',
    'weekBetter': 'Cette semaine dépasse la précédente',
    'weekWorse': 'Cette semaine est en retrait, continuez',
    'moodTitle': 'Vos humeurs les plus fréquentes',
  },
};
