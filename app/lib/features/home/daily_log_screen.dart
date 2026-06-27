import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/badge_catalog.dart';
import '../../core/catalog/default_fields.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import 'badge_celebration.dart';

// HRT 4 phases (weeks 1-2, 3-4, 5-6, 7-8) for the "break" track.
const _phases = [
  {'ar': 'المرحلة ١: الوعي — ارصد وسجّل', 'en': 'Phase 1: Awareness', 'fr': 'Phase 1 : Prise de conscience'},
  {'ar': 'المرحلة ٢: الاستجابة التنافسية', 'en': 'Phase 2: Competing response', 'fr': 'Phase 2 : Réponse alternative'},
  {'ar': 'المرحلة ٣: التحكم في البيئة', 'en': 'Phase 3: Environment control', 'fr': "Phase 3 : Contrôle de l'environnement"},
  {'ar': 'المرحلة ٤: التثبيت والصيانة', 'en': 'Phase 4: Maintenance', 'fr': 'Phase 4 : Maintien'},
];

const _moods = [
  ('😊', 'مرتاح'),
  ('😰', 'قلق'),
  ('😤', 'متوتر'),
  ('😑', 'بايخ'),
  ('😴', 'تعبان'),
  ('🔥', 'نشيط'),
  ('😢', 'حزين'),
  ('😶', 'محايد'),
];

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});
  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  double _urge = 5, _resistance = 5;
  bool? _didSlip;
  String? _moodEmoji, _moodLabel;
  final _noteCtrl = TextEditingController();
  final Set<String> _selectedCR = {};
  final Set<String> _selectedEnv = {};
  bool _loaded = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromToday(AppState s) {
    if (_loaded) return;
    final e = s.entryForToday();
    if (e != null) {
      _urge = e.urge.toDouble();
      _resistance = e.resistance.toDouble();
      _didSlip = e.didSlip;
      _moodEmoji = e.moodEmoji;
      _moodLabel = e.moodLabel;
      _noteCtrl.text = e.note ?? '';
      _selectedCR.addAll(e.competingResponses);
      _selectedEnv.addAll(e.environment);
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final newBadges = await ref.read(appControllerProvider.notifier).saveEntry(
          urge: _urge.round(),
          resistance: _resistance.round(),
          didSlip: _didSlip ?? false,
          moodEmoji: _moodEmoji,
          moodLabel: _moodLabel,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          competingResponses: _selectedCR.toList(),
          environment: _selectedEnv.toList(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.entrySaved), backgroundColor: AppColors.success),
    );
    for (final b in newBadges) {
      final def = badgeByKey(b.badgeKey);
      if (def != null && mounted) {
        await showBadgeCelebration(context, def);
        await ref
            .read(appControllerProvider.notifier)
            .markBadgeCelebrated(b.badgeKey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    _hydrateFromToday(s);
    final habit = s.habit;
    final isBreak = habit?.track == 'break';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          Text(habit?.title ?? l10n.appName,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.heading)),
          const SizedBox(height: 2),
          Text(l10n.slogan,
              style: const TextStyle(color: AppColors.accent2, fontSize: 12)),
          const SizedBox(height: 16),
          // stats row
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '${s.daysLogged}',
                      label: l10n.statsDaysLogged)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.cleanDays}',
                      label: l10n.statsCleanDays,
                      color: AppColors.accent2)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.currentStreak}',
                      label: l10n.statsCurrentStreak,
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 14),
          if (s.settings.showReligiousContent)
            MotivationBanner(
              emoji: '🤍',
              title: l10n.motivationIntention,
              subtitle: s.currentStreak > 0 ? l10n.motivationPatience : null,
            ),
          if (isBreak) ...[
            const SizedBox(height: 12),
            _phaseBanner(s, locale),
          ],
          const SizedBox(height: 16),
          Text(l10n.todayTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          // urge slider
          SectionCard(
            child: _slider(
              label: l10n.urgeLevel,
              value: _urge,
              color: AppColors.accent3,
              low: l10n.urgeLow,
              high: l10n.urgeHigh,
              onChanged: (v) => setState(() => _urge = v),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: _slider(
              label: l10n.resistanceLevel,
              value: _resistance,
              color: AppColors.accent2,
              low: l10n.resistWeak,
              high: l10n.resistStrong,
              onChanged: (v) => setState(() => _resistance = v),
            ),
          ),
          const SizedBox(height: 10),
          // did slip
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.didSlipQuestion,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChipTile(
                        label: l10n.no,
                        selected: _didSlip == false,
                        color: AppColors.success,
                        onTap: () => setState(() => _didSlip = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChipTile(
                        label: l10n.yes,
                        selected: _didSlip == true,
                        color: AppColors.danger,
                        onTap: () => setState(() => _didSlip = true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // mood
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.moodLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((m) {
                    final sel = _moodEmoji == m.$1;
                    return InkWell(
                      onTap: () => setState(() {
                        _moodEmoji = m.$1;
                        _moodLabel = m.$2;
                      }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel ? AppColors.accent : AppColors.border),
                        ),
                        child: Text('${m.$1} ${m.$2}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isBreak) ...[
            _checklistSection('competing_response', _selectedCR, s, locale),
            const SizedBox(height: 10),
            _checklistSection('environment_action', _selectedEnv, s, locale),
            const SizedBox(height: 10),
          ],
          // note
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.noteLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: l10n.noteHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _didSlip == null ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.saveEntry),
          ),
          if (s.entryForToday() != null) ...[
            const SizedBox(height: 8),
            Text(l10n.alreadyLoggedToday,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _phaseBanner(AppState s, String locale) {
    final habit = s.habit;
    if (habit == null) return const SizedBox.shrink();
    final week = s.weekNumber;
    final idx = ((week - 1) ~/ 2).clamp(0, 3);
    final label = _phases[idx][locale] ?? _phases[idx]['ar']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0x1F4F8EF7), Color(0x122DD4BF)]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x394F8EF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text('$week', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _checklistSection(
      String group, Set<String> selected, AppState s, String locale) {
    final fields = s.visibleFields(group);
    if (fields.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(groupTitle(group, locale),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          ...fields.map((f) {
            final on = selected.contains(f.label);
            return InkWell(
              onTap: () => setState(() {
                if (on) {
                  selected.remove(f.label);
                } else {
                  selected.add(f.label);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
                        color: on ? AppColors.success : AppColors.muted,
                        size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f.label,
                          style: TextStyle(
                              fontSize: 13,
                              color: on ? AppColors.text : AppColors.muted)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required Color color,
    required String low,
    required String high,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text('${value.round()}',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(low, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            Text(high, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
