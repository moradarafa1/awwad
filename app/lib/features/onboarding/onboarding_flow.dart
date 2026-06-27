import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/widgets/common.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;

  // collected data
  bool _consent = false;
  String? _ageRange, _gender, _country, _referral;
  String? _track; // 'break' | 'build'
  CatalogHabit? _picked;
  bool _custom = false;
  final _nameCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  int _reminderHour = 20;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track('onboarding_started');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whyCtrl.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  void _next() => setState(() => _step++);
  void _prev() => setState(() => _step--);

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final title = _custom
        ? _nameCtrl.text.trim()
        : (_picked?.t(_locale) ?? _nameCtrl.text.trim());
    if (title.isEmpty) return;
    final habit = Habit(
      id: const Uuid().v4(),
      track: _track ?? 'break',
      catalogKey: _custom ? null : _picked?.key,
      isCustom: _custom,
      title: title,
      reason: _whyCtrl.text.trim().isEmpty ? null : _whyCtrl.text.trim(),
      templateKey: _custom ? 'generic' : (_picked?.templateKey ?? 'generic'),
      reminderHour: _reminderHour,
      createdAt: DateTime.now(),
    );
    final survey = _consent ||
            _ageRange != null ||
            _gender != null ||
            (_country?.isNotEmpty ?? false)
        ? SurveyData(
            consent: _consent,
            ageRange: _ageRange,
            gender: _gender,
            country: _country,
            referralSource: _referral,
          )
        : null;
    await ref
        .read(appControllerProvider.notifier)
        .completeOnboarding(habit, survey: survey);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.entrySaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _progressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _buildStep(l10n),
              ),
            ),
            _bottomBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(5, (i) {
          final active = i <= _step;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _welcomeStep(l10n);
      case 1:
        return _surveyStep(l10n);
      case 2:
        return _trackStep(l10n);
      case 3:
        return _habitStep(l10n);
      default:
        return _setupStep(l10n);
    }
  }

  // ---------- step 0: welcome + language ----------
  Widget _welcomeStep(AppLocalizations l10n) {
    final current = ref.watch(appControllerProvider).settings.locale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Text('🌱', style: const TextStyle(fontSize: 56)),
        ),
        const SizedBox(height: 16),
        Text(l10n.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.heading)),
        const SizedBox(height: 6),
        Text(l10n.slogan,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.accent2, fontSize: 14)),
        const SizedBox(height: 24),
        Text(l10n.onboardWelcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(l10n.onboardWelcomeBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.6)),
        const SizedBox(height: 24),
        Text(l10n.chooseLanguage,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 10),
        Row(
          children: [
            _langBtn('العربية', 'ar', current),
            const SizedBox(width: 8),
            _langBtn('English', 'en', current),
            const SizedBox(width: 8),
            _langBtn('Français', 'fr', current),
          ],
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.accent3, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.medicalDisclaimer,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.6)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _langBtn(String label, String code, String? current) {
    final selected = current == code;
    return Expanded(
      child: InkWell(
        onTap: () =>
            ref.read(appControllerProvider.notifier).setLocale(code),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.text,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // ---------- step 1: optional survey ----------
  Widget _surveyStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.surveyTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(l10n.surveyBody,
            style: const TextStyle(color: AppColors.muted, height: 1.6)),
        const SizedBox(height: 18),
        _surveyField(l10n.ageRange, ['<18', '18-24', '25-34', '35-44', '45-54', '55+'],
            _ageRange, (v) => setState(() => _ageRange = v)),
        const SizedBox(height: 14),
        _surveyField(
            l10n.gender,
            [l10n.genderMale, l10n.genderFemale, l10n.genderPreferNot],
            _gender,
            (v) => setState(() => _gender = v)),
        const SizedBox(height: 14),
        Text(l10n.country,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(isDense: true),
          onChanged: (v) => _country = v,
        ),
        const SizedBox(height: 14),
        Text(l10n.referralSource,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(isDense: true),
          onChanged: (v) => _referral = v,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => setState(() => _consent = !_consent),
          child: Row(
            children: [
              Icon(_consent ? Icons.check_box : Icons.check_box_outline_blank,
                  color: _consent ? AppColors.accent : AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.surveyConsent,
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _surveyField(String label, List<String> options, String? selected,
      ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((o) => ChoiceChipTile(
                    label: o,
                    selected: selected == o,
                    onTap: () => onSelect(o),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ---------- step 2: track ----------
  Widget _trackStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.chooseTrackTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        _trackCard('🚭', l10n.trackBreak, l10n.trackBreakDesc, 'break',
            AppColors.danger),
        const SizedBox(height: 12),
        _trackCard('🌱', l10n.trackBuild, l10n.trackBuildDesc, 'build',
            AppColors.success),
      ],
    );
  }

  Widget _trackCard(
      String emoji, String title, String desc, String track, Color color) {
    final selected = _track == track;
    return InkWell(
      onTap: () {
        setState(() {
          _track = track;
          _picked = null;
          _custom = false;
        });
        AnalyticsService.instance.track('track_selected', {'track': track});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  // ---------- step 3: habit pick ----------
  Widget _habitStep(AppLocalizations l10n) {
    final track = _track ?? 'break';
    final all = catalogForTrack(track);
    return _HabitPicker(
      locale: _locale,
      habits: all,
      selectedKey: _custom ? null : _picked?.key,
      customSelected: _custom,
      customCtrl: _nameCtrl,
      onPick: (h) => setState(() {
        _picked = h;
        _custom = false;
        _nameCtrl.text = h.t(_locale);
        AnalyticsService.instance.track('habit_selected', {
          'catalog_key': h.key,
          'category': h.category,
          'is_islamic': h.isIslamic,
        });
      }),
      onCustom: () => setState(() {
        _custom = true;
        _picked = null;
        AnalyticsService.instance
            .track('habit_custom_created', {'track': track, 'category': 'custom'});
      }),
    );
  }

  // ---------- step 4: setup ----------
  Widget _setupStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.habitSetupTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Text(l10n.habitNameLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl),
        const SizedBox(height: 16),
        Text(l10n.habitWhyLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: _whyCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.habitWhyHint),
        ),
        const SizedBox(height: 16),
        Text(l10n.reminderTime,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _reminderHour,
          dropdownColor: AppColors.surface,
          items: List.generate(
              24,
              (h) => DropdownMenuItem(
                  value: h,
                  child: Text('${h.toString().padLeft(2, '0')}:00'))),
          onChanged: (v) => setState(() => _reminderHour = v ?? 20),
        ),
      ],
    );
  }

  // ---------- bottom bar ----------
  Widget _bottomBar(AppLocalizations l10n) {
    final canNext = _canProceed();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(onPressed: _prev, child: Text(l10n.back)),
          if (_step == 1)
            TextButton(
                onPressed: () {
                  AnalyticsService.instance.track('survey_skipped');
                  _next();
                },
                child: Text(l10n.skipSurvey)),
          const Spacer(),
          FilledButton(
            onPressed: canNext
                ? () {
                    if (_step == 1) {
                      AnalyticsService.instance.track('survey_completed', {
                        'consent': _consent,
                        'fields_count': [
                          _ageRange,
                          _gender,
                          _country,
                          _referral
                        ].where((e) => e != null && e.toString().isNotEmpty).length,
                      });
                    }
                    if (_step >= 4) {
                      _finish();
                    } else {
                      _next();
                    }
                  }
                : null,
            child: Text(_step >= 4 ? l10n.startJourney : l10n.next),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_step) {
      case 2:
        return _track != null;
      case 3:
        return _custom ? _nameCtrl.text.trim().isNotEmpty : _picked != null;
      case 4:
        return _nameCtrl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }
}

class _HabitPicker extends StatefulWidget {
  final String locale;
  final List<CatalogHabit> habits;
  final String? selectedKey;
  final bool customSelected;
  final TextEditingController customCtrl;
  final ValueChanged<CatalogHabit> onPick;
  final VoidCallback onCustom;
  const _HabitPicker({
    required this.locale,
    required this.habits,
    required this.selectedKey,
    required this.customSelected,
    required this.customCtrl,
    required this.onPick,
    required this.onCustom,
  });
  @override
  State<_HabitPicker> createState() => _HabitPickerState();
}

class _HabitPickerState extends State<_HabitPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = widget.habits
        .where((h) =>
            _query.isEmpty ||
            h.t(widget.locale).toLowerCase().contains(_query.toLowerCase()))
        .toList();
    // group by category
    final byCat = <String, List<CatalogHabit>>{};
    for (final h in filtered) {
      byCat.putIfAbsent(h.category, () => []).add(h);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.chooseHabitTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchHabits,
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 14),
        // custom option
        _customTile(l10n),
        const SizedBox(height: 14),
        for (final entry in byCat.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(categoryName(entry.key, widget.locale),
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.value.map((h) {
              final sel = widget.selectedKey == h.key;
              return InkWell(
                onTap: () => widget.onPick(h),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel ? AppColors.accent : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(h.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(h.t(widget.locale),
                          style: TextStyle(
                              color: sel ? AppColors.accent : AppColors.text,
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500)),
                      if (h.isIslamic) ...[
                        const SizedBox(width: 6),
                        const Text('🕌', style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _customTile(AppLocalizations l10n) {
    return Column(
      children: [
        InkWell(
          onTap: widget.onCustom,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.customSelected
                  ? AppColors.accent2.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: widget.customSelected
                      ? AppColors.accent2
                      : AppColors.border),
            ),
            child: Row(
              children: [
                const Text('✏️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.customHabitTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading)),
                      Text(l10n.customHabitDesc,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.customSelected) ...[
          const SizedBox(height: 10),
          TextField(
            controller: widget.customCtrl,
            decoration: InputDecoration(hintText: l10n.customHabitNameHint),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}
