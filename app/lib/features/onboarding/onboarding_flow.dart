import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/countries.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/reminder_times_picker.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _step = 0;

  // collected data
  String? _ageRange, _gender, _country;
  Country? _selectedCountry;
  String? _track; // 'break' | 'build'
  CatalogHabit? _picked;
  bool _custom = false;
  final _nameCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  List<int> _reminderHours = [20];

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

  String _reminderHint() =>
      const {
        'ar': 'يمكنك إضافة أكثر من وقت، أو تركها بدون تذكير.',
        'en': 'You can add more than one time, or leave it with no reminder.',
        'fr': "Vous pouvez ajouter plusieurs heures ou n'en mettre aucune.",
      }[_locale] ??
      '';

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
      reminderHour: _reminderHours.isNotEmpty ? _reminderHours.first : 20,
      reminderHours: _reminderHours,
      createdAt: DateTime.now(),
    );
    // Consent is TRUE only because the survey step now displays the research
    // notice (surveyConsent) above these optional fields; an untouched survey
    // stays consent-free.
    final answered =
        _ageRange != null || _gender != null || _country != null;
    final survey = SurveyData(
      consent: answered,
      ageRange: _ageRange,
      gender: _gender,
      country: _country,
    );
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
      body: AmbientBackground(
        child: SafeArea(
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
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(4, (i) {
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
        return _surveyStep(l10n);
      case 1:
        return _trackStep(l10n);
      case 2:
        return _habitStep(l10n);
      default:
        return _setupStep(l10n);
    }
  }

  // ---------- step 0: profile (gender mandatory, the rest optional) ----------
  Widget _surveyStep(AppLocalizations l10n) {
    final selectHint = const {
      'ar': 'اختر دولتك',
      'en': 'Select your country',
      'fr': 'Sélectionnez votre pays',
    }[_locale] ?? 'Select your country';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(l10n.surveyTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        // Gender — mandatory.
        _surveyField('${l10n.gender} *', [l10n.genderMale, l10n.genderFemale],
            _gender, (v) => setState(() => _gender = v)),
        const SizedBox(height: 16),
        // Age — optional.
        _surveyField(l10n.ageRange, ['18-24', '25-34', '35-44', '45+'],
            _ageRange, (v) => setState(() => _ageRange = v)),
        const SizedBox(height: 16),
        // Country — optional, searchable list of all countries (localized).
        Text(l10n.country,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCountry,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCountry?.name(_locale) ?? selectHint,
                    style: TextStyle(
                        color: _selectedCountry == null
                            ? AppColors.muted
                            : AppColors.text),
                  ),
                ),
                Icon(Icons.expand_more, color: AppColors.muted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        // The research notice MUST be visible here: answering these optional
        // fields is what constitutes consent (see _finish), so recording
        // consent without rendering this text would be dishonest.
        Text(l10n.surveyConsent,
            style: TextStyle(
                color: AppColors.muted, fontSize: 11.5, height: 1.6)),
      ],
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _CountrySheet(locale: _locale),
    );
    if (picked != null) {
      setState(() {
        _selectedCountry = picked;
        _country = picked.en; // store a stable canonical value
      });
    }
  }

  Widget _surveyField(String label, List<String> options, String? selected,
      ValueChanged<String> onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
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
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 12)),
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
        // Suggest the habit's natural reminder times (e.g. water = several/day).
        _reminderHours =
            h.defaultReminderHours.isNotEmpty ? [...h.defaultReminderHours] : [20];
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
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl),
        const SizedBox(height: 16),
        Text(l10n.habitWhyLabel,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: _whyCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.habitWhyHint),
        ),
        const SizedBox(height: 16),
        Text(l10n.reminderTime,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(_reminderHint(),
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 8),
        ReminderTimesPicker(
          hours: _reminderHours,
          onChanged: (v) => setState(() => _reminderHours = v),
        ),
      ],
    );
  }

  // ---------- bottom bar ----------
  Widget _bottomBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            OutlinedButton(
              onPressed: _prev,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                minimumSize: const Size(64, 52),
                side: BorderSide(color: AppColors.border),
              ),
              child: Text(l10n.back),
            ),
            const SizedBox(width: 12),
          ],
          // "Next" is ALWAYS visible and enabled, and spans the width so it can
          // never be missed. Validation runs on tap, so a blocked step shows a
          // clear reason instead of an invisible disabled button.
          Expanded(
            child: FilledButton(
              onPressed: () => _onNext(l10n),
              child: Text(_step >= 3 ? l10n.startJourney : l10n.next),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext(AppLocalizations l10n) {
    final err = _stepError();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.surface,
      ));
      return;
    }
    if (_step == 0) {
      AnalyticsService.instance.track('survey_completed', {
        'has_gender': _gender != null,
        'has_age': _ageRange != null,
        'has_country': _country != null,
      });
    }
    if (_step >= 3) {
      _finish();
    } else {
      _next();
    }
  }

  // Localized reason the current step can't advance, or null when it can.
  String? _stepError() {
    switch (_step) {
      case 0:
        return _gender == null ? _msg('gender') : null;
      case 1:
        return _track == null ? _msg('track') : null;
      case 2:
        return (_custom ? _nameCtrl.text.trim().isEmpty : _picked == null)
            ? _msg('habit')
            : null;
      case 3:
        return _nameCtrl.text.trim().isEmpty ? _msg('habit') : null;
      default:
        return null;
    }
  }

  String _msg(String key) {
    const m = {
      'gender': {
        'ar': 'من فضلك اختر النوع للمتابعة',
        'en': 'Please choose your gender to continue',
        'fr': 'Veuillez choisir votre sexe pour continuer',
      },
      'track': {
        'ar': 'اختر مسارًا للمتابعة',
        'en': 'Choose a track to continue',
        'fr': 'Choisissez un parcours pour continuer',
      },
      'habit': {
        'ar': 'اختر عادة أو اكتب اسم عادتك',
        'en': 'Pick a habit or type its name',
        'fr': 'Choisissez une habitude ou saisissez son nom',
      },
    };
    return m[key]?[_locale] ?? m[key]?['en'] ?? '';
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
    // Widest a chip label may be: the Wrap line (screen - 40 page padding)
    // minus the chip's own chrome (24 padding + 2 border + the icon and the
    // optional islamic marker). The emoji Texts scale with the OS font
    // setting, so they are measured scaled, not at their nominal size.
    final scaler = MediaQuery.textScalerOf(context);
    final iconW = scaler.scale(18) * 1.3 + 8; // emoji advance + gap
    final islamicW = scaler.scale(12) * 1.3 + 6;
    double labelMaxWidth(bool isIslamic) =>
        (MediaQuery.sizeOf(context).width -
                40 - // page padding
                24 - // chip padding
                2 - // border
                iconW -
                (isIslamic ? islamicW : 0))
            .clamp(72.0, 420.0);

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
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
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
                style: TextStyle(
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
                      // The Wrap hands this Row UNBOUNDED width, so a bare Text
                      // (and a Flexible) can never wrap: long titles (e.g. fr
                      // "Trichotillomanie...") would hard-overflow. Bound the
                      // label explicitly, then let it take a second line.
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: labelMaxWidth(h.isIslamic)),
                        child: Text(h.t(widget.locale),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: sel ? AppColors.accent : AppColors.text,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500)),
                      ),
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
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading)),
                      Text(l10n.customHabitDesc,
                          style: TextStyle(
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

// Searchable country picker (bottom sheet). Searches by the localized name
// (and English/Arabic fallback) so it works whatever the app language is.
class _CountrySheet extends StatefulWidget {
  final String locale;
  const _CountrySheet({required this.locale});
  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final hint = const {
      'ar': 'ابحث عن دولة...',
      'en': 'Search for a country...',
      'fr': 'Rechercher un pays...',
    }[widget.locale] ?? 'Search...';
    final raw = _q.trim();
    final q = raw.toLowerCase();
    final list = raw.isEmpty
        ? kCountries
        : kCountries
            .where((c) =>
                c.name(widget.locale).toLowerCase().contains(q) ||
                c.en.toLowerCase().contains(q) ||
                c.ar.contains(raw))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.muted),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('·',
                          style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          title: Text(c.name(widget.locale),
                              style: TextStyle(color: AppColors.text)),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
