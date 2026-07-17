import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/motivation.dart';
import '../../core/models.dart';

/// Journey cards for BREAK habits on the stats screen: the recovery
/// timeline, the money/time-saved calculator, and the top slip triggers.
/// Pure widgets; trilingual inline strings.

String _jc(String k, String locale) =>
    (_jcStrings[locale] ?? _jcStrings['en']!)[k]!;

/// Recovery timeline: generic neuroplasticity milestones vs current streak.
class RecoveryTimelineCard extends StatelessWidget {
  const RecoveryTimelineCard({super.key, required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final reached =
        kRecoveryTimeline.where((m) => streak >= m.day).toList();
    RecoveryMilestone? next;
    for (final m in kRecoveryTimeline) {
      if (streak < m.day) {
        next = m;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_jc('timelineTitle', locale),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          if (reached.isEmpty)
            Text(_jc('timelineStart', locale),
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12.5, height: 1.6))
          else
            // Show the latest reached milestone as the "you are here" line.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle,
                    size: 18, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(reached.last.t(locale),
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12.5,
                          height: 1.6)),
                ),
              ],
            ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined,
                    size: 18, color: AppColors.accent2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '${_jc('after', locale)} ${next.day - streak} ${_jc('days', locale)} ${next.t(locale)}',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (streak / next.day).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor:
                    AppColors.accent2.withValues(alpha: 0.15),
                color: AppColors.accent2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Money & time saved since starting, from the habit's own configuration.
class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key, required this.habit, required this.cleanDays});
  final Habit habit;
  final int cleanDays;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final cost = habit.costPerDay ?? 0;
    final mins = habit.minutesPerDay ?? 0;
    if (cost <= 0 && mins <= 0) return const SizedBox.shrink();
    final money = cost * cleanDays;
    final totalMins = mins * cleanDays;
    final hours = totalMins ~/ 60;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.success.withValues(alpha: 0.12),
          AppColors.accent2.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_jc('savedTitle', locale),
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.success)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (cost > 0)
                Expanded(
                  child: Column(
                    children: [
                      Text(money.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success)),
                      Text(_jc('money', locale),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
              if (mins > 0)
                Expanded(
                  child: Column(
                    children: [
                      Text('$hours',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent2)),
                      Text(_jc('hours', locale),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${_jc('basis', locale)} $cleanDays',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Top slip triggers (relapse-journal analysis).
class TriggersCard extends StatelessWidget {
  const TriggersCard({super.key, required this.entries});
  final List<DailyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final counts = <String, int>{};
    for (final e in entries) {
      if (!e.isSkip && e.didSlip && e.trigger != null) {
        counts[e.trigger!] = (counts[e.trigger!] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_jc('triggersTitle', locale),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_jc('triggersHint', locale),
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 10),
          for (final t in top.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(triggerByKey(t.key)?.emoji ?? '✨',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        triggerByKey(t.key)?.l(locale) ?? t.key,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.text)),
                  ),
                  Text('×${t.value}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent3)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const Map<String, Map<String, String>> _jcStrings = {
  'ar': {
    'timelineTitle': 'رحلة تعافيك',
    'timelineStart': 'ابدأ أول يوم نظيف لتتحرك في خط التعافي.',
    'after': 'بعد',
    'days': 'من الأيام:',
    'savedTitle': 'وفّرت منذ البداية 💰',
    'money': 'وحدة نقدية موفرة',
    'hours': 'ساعة مستعادة',
    'basis': 'محسوبة على أيامك النظيفة:',
    'triggersTitle': 'محفزاتك الأكثر تكراراً',
    'triggersHint': 'اعرف عدوك: هذه الظروف تسبق تعثرك غالباً.',
  },
  'en': {
    'timelineTitle': 'Your recovery journey',
    'timelineStart': 'Log your first clean day to start moving on the timeline.',
    'after': 'In',
    'days': 'days:',
    'savedTitle': 'Saved since you started 💰',
    'money': 'money units saved',
    'hours': 'hours reclaimed',
    'basis': 'based on your clean days:',
    'triggersTitle': 'Your most frequent triggers',
    'triggersHint': 'Know your enemy: these usually precede a slip.',
  },
  'fr': {
    'timelineTitle': 'Votre parcours de rétablissement',
    'timelineStart': 'Enregistrez votre premier jour réussi pour avancer.',
    'after': 'Dans',
    'days': 'jours :',
    'savedTitle': 'Économisé depuis le début 💰',
    'money': 'unités monétaires',
    'hours': 'heures récupérées',
    'basis': 'sur la base de vos jours réussis :',
    'triggersTitle': 'Vos déclencheurs les plus fréquents',
    'triggersHint': 'Connaissez votre ennemi : ils précèdent souvent un écart.',
  },
};
