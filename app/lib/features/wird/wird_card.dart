import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../quran/quran_player_screen.dart';
import '../radio/radio_player_screen.dart';
import 'wird_settings_sheet.dart';

/// The listening wird, pinned to the TOP of a listening habit's page.
///
/// Owner instruction 2026-07-20: for Qur'an, hadith and the other listening
/// habits, the listen action is the whole point of opening the screen, so it
/// leads the page instead of sitting under the checklists. One tap starts,
/// one tap opens the settings.
///
/// The card states the auto-log rule in plain words, because a rule the user
/// cannot see is a rule they will not trust: listen for the minutes YOU chose,
/// without stopping, and the day logs itself.
class WirdCard extends ConsumerWidget {
  final Habit habit;
  const WirdCard({super.key, required this.habit});

  static const _kStr = {
    'title': {
      'ar': 'وِرد الاستماع',
      'en': 'Listening wird',
      'fr': "Wird d'écoute",
    },
    'listen': {'ar': 'استمع الآن', 'en': 'Listen now', 'fr': 'Écouter'},
    'settings': {'ar': 'خياراتي', 'en': 'My options', 'fr': 'Mes options'},
    'ruleOn': {
      'ar': 'استمع {m} دقيقة دون إيقاف، ويُسجَّل وردك تلقائياً.',
      'en': 'Listen for {m} minutes without stopping and your wird logs itself.',
      'fr': "Écoutez {m} minutes sans arrêter et votre wird s'enregistre seul.",
    },
    'ruleOff': {
      'ar': 'فعّل الوِرد لتحدّد مدّتك ومواعيدك، ويُسجَّل يومك تلقائياً.',
      'en': 'Turn the wird on to set your length and times, and log the day automatically.',
      'fr': "Activez le wird pour définir durée et horaires, et enregistrer la journée automatiquement.",
    },
    'atTimes': {'ar': 'مواعيدك اليوم: ', 'en': 'Your times today: ', 'fr': 'Vos horaires : '},
    'autoPlay': {
      'ar': 'يبدأ تلقائياً في موعده.',
      'en': 'Starts by itself at its time.',
      'fr': "Démarre seul à l'heure prévue.",
    },
    'done': {
      'ar': 'وِرد اليوم مُسجَّل. وزيادة الخير خير.',
      'en': "Today's wird is logged. More is still good.",
      'fr': "Le wird du jour est enregistré.",
    },
  };

  String _s(String k, String loc) => _kStr[k]![loc] ?? _kStr[k]!['ar']!;

  /// Hadith habits open the live radio; everything else opens the reciter
  /// player. Both auto-log against the SAME wird length.
  void _openPlayer(BuildContext context) {
    final isHadith =
        habit.catalogKey == 'hadith_wird' || habit.catalogKey == 'listening_wird';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => isHadith
          ? RadioPlayerScreen(category: 'hadith', habitId: habit.id)
          : QuranPlayerScreen(habitId: habit.id),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = Localizations.localeOf(context).languageCode;
    final wird = habit.wird ?? const WirdConfig();
    final s = ref.watch(appControllerProvider);
    final today = dayKey(DateTime.now());
    final loggedToday =
        s.entriesFor(habit.id).any((e) => e.date == today);

    final rule = wird.enabled
        ? _s('ruleOn', loc).replaceFirst('{m}', '${wird.minutesPerSession}')
        : _s('ruleOff', loc);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent2.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.accent2.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones_rounded, color: AppColors.accent2, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_s('title', loc),
                    style: headingStyle(17, weight: FontWeight.w800)),
              ),
              if (loggedToday)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(loggedToday ? _s('done', loc) : rule,
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.muted)),
          if (wird.enabled && wird.times.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${_s('atTimes', loc)}'
              '${(wird.times.toList()..sort()).map((h) => '${h.toString().padLeft(2, '0')}:00').join('  ')}'
              '${wird.autoPlay ? '  ·  ${_s('autoPlay', loc)}' : ''}',
              style: TextStyle(fontSize: 11.5, color: AppColors.accent2),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openPlayer(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent2,
                    foregroundColor: AppColors.bg,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                  label: Text(_s('listen', loc),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => showWirdSettings(context, ref, habit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent2,
                  side: BorderSide(color: AppColors.accent2.withValues(alpha: 0.6)),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(_s('settings', loc),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
