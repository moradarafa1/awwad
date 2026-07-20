import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';

/// Where the user shapes their own listening wird: how long counts, when it
/// should happen, whether it starts by itself, and how many sessions they are
/// aiming for.
///
/// Owner brief 2026-07-20. Two rules are deliberately visible in the copy
/// rather than hidden in code:
///   - the floor is five minutes, so a wird cannot be a token tap,
///   - ONE completed session logs the day, no matter how many they do.
Future<void> showWirdSettings(
    BuildContext context, WidgetRef ref, Habit habit) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _WirdSettingsSheet(habit: habit),
  );
}

class _WirdSettingsSheet extends ConsumerStatefulWidget {
  final Habit habit;
  const _WirdSettingsSheet({required this.habit});
  @override
  ConsumerState<_WirdSettingsSheet> createState() => _WirdSettingsSheetState();
}

class _WirdSettingsSheetState extends ConsumerState<_WirdSettingsSheet> {
  late WirdConfig _cfg = widget.habit.wird ?? const WirdConfig();

  static const _kStr = {
    'title': {'ar': 'خيارات وِردي', 'en': 'My wird options', 'fr': 'Mes options de wird'},
    'enable': {'ar': 'فعّل وِرد الاستماع', 'en': 'Enable the listening wird', 'fr': "Activer le wird d'écoute"},
    'enableSub': {
      'ar': 'يُسجَّل يومك تلقائياً بعد استماعٍ متّصل بالمدّة التي تختارها.',
      'en': 'Your day logs itself after uninterrupted listening for the length you choose.',
      'fr': "Votre journée s'enregistre après une écoute continue de la durée choisie.",
    },
    'minutes': {'ar': 'مدّة الوِرد', 'en': 'Wird length', 'fr': 'Durée du wird'},
    'minutesSub': {
      'ar': 'أقلّها خمس دقائق. ما دونها ليس وِرداً.',
      'en': 'Five minutes minimum. Less than that is not a wird.',
      'fr': 'Cinq minutes minimum.',
    },
    'min': {'ar': 'دقيقة', 'en': 'min', 'fr': 'min'},
    'times': {'ar': 'مواعيدك', 'en': 'Your times', 'fr': 'Vos horaires'},
    'timesSub': {
      'ar': 'اختر ساعةً أو أكثر. اتركها فارغة إن كنت تفتحه بنفسك.',
      'en': 'Pick one or more hours. Leave empty if you open it yourself.',
      'fr': "Choisissez une ou plusieurs heures.",
    },
    'addTime': {'ar': 'أضف موعداً', 'en': 'Add a time', 'fr': 'Ajouter une heure'},
    'autoPlay': {'ar': 'ابدأ التشغيل تلقائياً', 'en': 'Start playing automatically', 'fr': 'Démarrer automatiquement'},
    'autoPlaySub': {
      'ar': 'إن أطفأته، يصلك تذكير في الموعد وتضغط أنت.',
      'en': 'If off, you get a reminder at that time and press play yourself.',
      'fr': "Sinon, un rappel vous invite à lancer la lecture.",
    },
    'sessions': {'ar': 'كم مرّة في اليوم؟', 'en': 'How many times a day?', 'fr': 'Combien de fois par jour ?'},
    'sessionsSub': {
      'ar': 'هدفك الشخصي. ويكفي إتمام مرّةٍ واحدة لتسجيل العادة لليوم.',
      'en': 'Your personal target. One completed session already logs the day.',
      'fr': "Votre objectif. Une seule session suffit à valider la journée.",
    },
    'save': {'ar': 'حفظ', 'en': 'Save', 'fr': 'Enregistrer'},
    'times_': {'ar': 'مرّة', 'en': 'x', 'fr': 'x'},
  };

  String _s(String k) {
    final loc = Localizations.localeOf(context).languageCode;
    return _kStr[k]![loc] ?? _kStr[k]!['ar']!;
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      helpText: _s('addTime'),
    );
    if (picked == null) return;
    if (_cfg.times.contains(picked.hour)) return;
    setState(() => _cfg = _cfg.copyWith(times: [..._cfg.times, picked.hour]));
  }

  Future<void> _save() async {
    await ref
        .read(appControllerProvider.notifier)
        .updateHabitWird(widget.habit.id, _cfg);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _cfg.times.toList()..sort();
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(_s('title'), style: headingStyle(19, weight: FontWeight.w800)),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _cfg.enabled,
              onChanged: (v) => setState(() => _cfg = _cfg.copyWith(enabled: v)),
              title: Text(_s('enable'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(_s('enableSub'),
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.5)),
              activeThumbColor: AppColors.accent2,
            ),

            if (_cfg.enabled) ...[
              const Divider(height: 26),
              Text(_s('minutes'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(_s('minutesSub'),
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.5)),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _cfg.minutesPerSession.toDouble(),
                      min: WirdConfig.kMinWirdMinutes.toDouble(),
                      max: 60,
                      divisions: 60 - WirdConfig.kMinWirdMinutes,
                      activeColor: AppColors.accent2,
                      label: '${_cfg.minutesPerSession}',
                      onChanged: (v) => setState(
                          () => _cfg = _cfg.copyWith(minutesPerSession: v.round())),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: Text('${_cfg.minutesPerSession} ${_s('min')}',
                        textAlign: TextAlign.center,
                        style: numberStyle(15, color: AppColors.accent2)),
                  ),
                ],
              ),

              const Divider(height: 26),
              Text(_s('times'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(_s('timesSub'),
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in sorted)
                    InputChip(
                      label: Text('${h.toString().padLeft(2, '0')}:00'),
                      onDeleted: () => setState(() => _cfg = _cfg.copyWith(
                          times: _cfg.times.where((x) => x != h).toList())),
                      backgroundColor: AppColors.surface2,
                      side: BorderSide(color: AppColors.border),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(_s('addTime')),
                    onPressed: _addTime,
                    backgroundColor: AppColors.surface2,
                    side: BorderSide(color: AppColors.accent2.withValues(alpha: 0.5)),
                  ),
                ],
              ),

              if (sorted.isNotEmpty) ...[
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _cfg.autoPlay,
                  onChanged: (v) => setState(() => _cfg = _cfg.copyWith(autoPlay: v)),
                  title: Text(_s('autoPlay'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(_s('autoPlaySub'),
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.5)),
                  activeThumbColor: AppColors.accent2,
                ),
              ],

              const Divider(height: 26),
              Text(_s('sessions'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(_s('sessionsSub'),
                  style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var n = 1; n <= 5; n++)
                    ChoiceChip(
                      label: Text('$n'),
                      selected: _cfg.sessionsPerDay == n,
                      onSelected: (_) =>
                          setState(() => _cfg = _cfg.copyWith(sessionsPerDay: n)),
                      selectedColor: AppColors.accent2.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surface2,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent2,
                foregroundColor: AppColors.bg,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(_s('save')),
            ),
          ],
        ),
      ),
    );
  }
}
