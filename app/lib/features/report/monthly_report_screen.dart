// End-of-month report screen (TODO 0d Phase C): a calm, encouraging summary of
// each habit's month plus a per-habit relapse-recovery tip. Reachable from the
// end-of-month notification and from a Stats card.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/report/monthly_report.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final report = buildMonthlyReport(s.habits, s.entries);
    final monthName = _kMonths[loc]?[report.month - 1] ??
        _kMonths['ar']![report.month - 1];

    return Scaffold(
      appBar: AppBar(title: Text(_s('title', loc))),
      body: report.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(_s('empty', loc),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.7)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Text('$monthName ${report.year}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.heading)),
                const SizedBox(height: 4),
                Text(_s('subtitle', loc),
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 16),
                for (final r in report.habits)
                  if (r.loggedDays > 0) _habitCard(context, r, loc),
              ],
            ),
    );
  }

  Widget _habitCard(BuildContext context, HabitMonthReport r, String loc) {
    final pct = (r.successRate * 100).round();
    final cat = r.habit.catalogKey == null
        ? null
        : catalogByKey(r.habit.catalogKey!);
    final icon = cat?.icon ?? (r.habit.track == 'break' ? '🚭' : '🌱');
    final isBreak = r.habit.track == 'break';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.habit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading)),
              ),
              Text('$pct%',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: pct >= 60
                          ? AppColors.success
                          : (pct >= 30
                              ? AppColors.accent3
                              : AppColors.danger))),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: r.successRate.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: AppColors.border,
                color: AppColors.accent2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _stat(_s(isBreak ? 'cleanDays' : 'doneDays', loc),
                    '${r.cleanDays}'),
                _stat(_s('logged', loc), '${r.loggedDays}'),
                _stat(_s('bestStreak', loc), '${r.bestStreak}'),
                if (r.skipDays > 0) _stat(_s('excused', loc), '${r.skipDays}'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(relapseTip(r.habit, loc),
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            height: 1.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.heading)),
          Text(label,
              style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
        ],
      );

  String _s(String k, String loc) => _kStr[k]![loc] ?? _kStr[k]!['ar']!;
}

const Map<String, Map<String, String>> _kStr = {
  'title': {
    'ar': 'تقرير الشهر',
    'en': 'Monthly report',
    'fr': 'Rapport du mois'
  },
  'subtitle': {
    'ar': 'نظرة على تقدّمك هذا الشهر، وكلمة تشجيع لكل عادة.',
    'en': "A look at this month's progress, with a word of encouragement per habit.",
    'fr': "Un aperçu de vos progrès du mois, avec un mot d'encouragement."
  },
  'empty': {
    'ar': 'لا توجد تسجيلات لهذا الشهر بعد. سجّل يومك لتبني تقريرك.',
    'en': 'No entries for this month yet. Log your day to build your report.',
    'fr': "Aucune entrée ce mois-ci. Enregistrez votre journée pour bâtir votre rapport."
  },
  'cleanDays': {'ar': 'أيام نظيفة', 'en': 'Clean days', 'fr': 'Jours réussis'},
  'doneDays': {'ar': 'أيام أُنجزت', 'en': 'Days done', 'fr': 'Jours accomplis'},
  'logged': {'ar': 'أيام مسجّلة', 'en': 'Days logged', 'fr': 'Jours enregistrés'},
  'bestStreak': {
    'ar': 'أطول سلسلة',
    'en': 'Best streak',
    'fr': 'Meilleure série'
  },
  'excused': {'ar': 'أيام معفاة', 'en': 'Excused', 'fr': 'Exemptés'},
};

const Map<String, List<String>> _kMonths = {
  'ar': [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس',
    'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ],
  'en': [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ],
  'fr': [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août',
    'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ],
};
