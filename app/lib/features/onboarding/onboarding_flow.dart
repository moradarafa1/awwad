import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/habit_icons.dart';
import '../../core/catalog/countries.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../../core/analytics/analytics.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/common.dart';
import '../../core/prayer/prayer_engine.dart';
import '../../core/widgets/reminder_times_picker.dart';
import '../prayer/prayer_auto_note.dart';
import '../prayer/prayer_settings_screen.dart';

/// The onboarding steps, in order.
///
/// [survey] is deliberately conditional. It collects ACCOUNT data (gender,
/// age range, country, research consent), so a guest never sees it: there is
/// no account to attach it to, and asking a guest for it is a barrier that
/// buys nothing. Owner instruction, 2026-07-20.
///
/// [location] (owner order 2026-07-31): country then NEAREST CITY, with a GPS
/// auto-detect that fires on entering the step (the permission dialog appears
/// in context, "like other apps" - Android has no install-time grant for
/// runtime permissions). Skippable; feeds PrayerConfig so the adhan works out
/// of the box.
enum _Step { survey, track, habit, setup, location }

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  /// Index into [_steps], NOT a fixed step id: the list length varies.
  int _step = 0;

  /// Resolved once, on entry. A user who signs up mid-flow would otherwise see
  /// the step list change under them.
  late final List<_Step> _steps = [
    if (SupabaseService.signedIn) _Step.survey,
    _Step.track,
    _Step.habit,
    _Step.setup,
    _Step.location,
  ];

  _Step get _current => _steps[_step];
  bool get _isLastStep => _step >= _steps.length - 1;

  // collected data
  String? _ageRange, _gender, _country;
  Country? _selectedCountry;
  String? _track; // 'break' | 'build'
  CatalogHabit? _picked;
  bool _custom = false;
  final _nameCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  List<int> _reminderHours = [20];

  // Location step (prayer times + adhan).
  PrayerCity? _prayerCity;
  String? _prayerCountry; // localized country name picked manually
  bool _locating = false;
  bool _gpsTried = false; // the automatic attempt fires once per flow
  bool _adhanOn = true; // core feature: on by default once a location exists

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

  void _next() {
    setState(() => _step++);
    // Entering the location step auto-tries GPS once: the OS permission
    // dialog appears in context, and on success the country + nearest city
    // fill themselves in (owner order: automatic from GPS).
    if (_current == _Step.location && !_gpsTried && !kIsWeb) {
      _tryGps();
    }
  }

  void _prev() => setState(() => _step--);

  /// One GPS attempt: permission dialog in context, low accuracy (nearest of
  /// 306 bundled cities needs km-level only), graceful fallback to the manual
  /// pickers on deny/failure.
  Future<void> _tryGps() async {
    if (kIsWeb || _locating) return;
    _gpsTried = true;
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return; // manual pickers stay available, no scolding
      }
      // medium (balanced), not low: with only the COARSE permission the fix is
      // km-coarsened anyway, but low restricts to the network provider, which
      // fails on devices without network location (and on the emulator).
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 20));
      final cities = await loadCities();
      final near = nearestCity(cities, pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _prayerCity = near;
          _prayerCountry = _locale == 'ar' ? near.countryAr : near.countryEn;
        });
      }
    } catch (_) {
      // Silent: GPS off / airplane mode / emulator. Manual pickers remain.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Persists the location step into PrayerConfig (merging over any existing
  /// config so per-prayer offsets survive a re-onboarding). Called from
  /// [_finish] BEFORE completeOnboarding, so the first home_shell open already
  /// schedules the prayer window and the native adhan chain.
  Future<void> _savePrayerLocation() async {
    final city = _prayerCity;
    if (city == null) return;
    final store = ref.read(localStoreProvider);
    final raw = store.loadPrayer();
    final base = raw != null ? PrayerConfig.fromJson(raw) : const PrayerConfig();
    await store.savePrayer(base
        .copyWith(
          lat: city.lat,
          lng: city.lng,
          cityAr: city.cityAr,
          cityEn: city.cityEn,
          countryAr: city.countryAr,
          countryEn: city.countryEn,
          adhanSound: !kIsWeb && _adhanOn,
        )
        .toJson());
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final title = _custom
        ? _nameCtrl.text.trim()
        : (_picked?.t(_locale) ?? _nameCtrl.text.trim());
    if (title.isEmpty) return;
    await _savePrayerLocation();
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
      // A prayer-linked first habit needs a location or its adhan-time
      // reminders never fire (the scheduler silently no-ops). The location
      // step normally covers this; the redirect remains for the user who
      // skipped it. Owner instruction 2026-07-20: ask right away.
      const prayerLinked = {'pray_on_time', 'wake_fajr', 'adhkar'};
      if (prayerLinked.contains(habit.catalogKey)) {
        final raw = ref.read(localStoreProvider).loadPrayer();
        final cfg =
            raw != null ? PrayerConfig.fromJson(raw) : const PrayerConfig();
        if (!cfg.configured) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PrayerSettingsScreen()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The steps are an INDEX, not a Navigator stack, so without this the
    // Android back button skips the whole flow instead of stepping back one
    // screen: it tries to pop OnboardingFlow itself, which is the root route.
    // canPop is true only on the first step, where leaving really is correct.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prev();
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(_steps.length, (i) {
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
    switch (_current) {
      case _Step.survey:
        return _surveyStep(l10n);
      case _Step.track:
        return _trackStep(l10n);
      case _Step.habit:
        return _habitStep(l10n);
      case _Step.setup:
        return _setupStep(l10n);
      case _Step.location:
        return _locationStep(l10n);
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
            style: headingStyle(20, weight: FontWeight.w800)),
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
            style: headingStyle(20, weight: FontWeight.w800)),
        const SizedBox(height: 18),
        _trackCard(Icons.smoke_free_rounded, l10n.trackBreak, l10n.trackBreakDesc, 'break',
            AppColors.danger),
        const SizedBox(height: 12),
        _trackCard(Icons.eco_rounded, l10n.trackBuild, l10n.trackBuildDesc, 'build',
            AppColors.success),
      ],
    );
  }

  Widget _trackCard(
      IconData icon, String title, String desc, String track, Color color) {
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
            Icon(icon, size: 34, color: color),
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
            style: headingStyle(20, weight: FontWeight.w800)),
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
        // pray_on_time (owner order 2026-07-31): reminders are the five
        // prayer times per location, never a manual hour.
        if (!_custom && _picked?.key == 'pray_on_time')
          const PrayerAutoReminderNote(inOnboarding: true)
        else ...[
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
      ],
    );
  }

  // ---------- step 5: location (prayer times + adhan) ----------
  static const _kLoc = {
    'title': {
      'ar': 'أين تعيش؟',
      'en': 'Where do you live?',
      'fr': 'Où habitez-vous ?'
    },
    'why': {
      'ar':
          'لحساب مواقيت الصلاة والأذان فلكياً على جهازك: بلا إنترنت، ولا يغادر موقعك هاتفك. يمكنك تخطي هذه الخطوة وضبطها لاحقاً من الإعدادات.',
      'en':
          'Prayer times and the adhan are computed on your device: offline, and your location never leaves your phone. You can skip this and set it later in Settings.',
      'fr':
          "Les horaires de prière et l'adhan sont calculés sur votre appareil : hors ligne, votre position ne quitte jamais votre téléphone. Vous pouvez passer et régler plus tard."
    },
    'gps': {
      'ar': 'تحديد موقعي تلقائياً',
      'en': 'Detect my location',
      'fr': 'Détecter ma position'
    },
    'orManual': {
      'ar': 'أو اختر يدوياً: الدولة ثم أقرب مدينة إليك',
      'en': 'Or pick manually: country, then the nearest city',
      'fr': 'Ou choisissez : le pays, puis la ville la plus proche'
    },
    'country': {'ar': 'الدولة', 'en': 'Country', 'fr': 'Pays'},
    'city': {
      'ar': 'أقرب مدينة إليك',
      'en': 'Nearest city',
      'fr': 'Ville la plus proche'
    },
    'pickCountryFirst': {
      'ar': 'اختر الدولة أولاً',
      'en': 'Pick the country first',
      'fr': "Choisissez d'abord le pays"
    },
    'located': {
      'ar': 'تم تحديد موقعك',
      'en': 'Location set',
      'fr': 'Position définie'
    },
    'adhan': {
      'ar': 'صوت الأذان عند كل صلاة',
      'en': 'Adhan sound at every prayer',
      'fr': 'Son de l\'adhan à chaque prière'
    },
    'adhanSub': {
      'ar': 'يصدح الأذان في وقته حتى والتطبيق مغلق. تتحكم به لاحقاً من الإعدادات.',
      'en': 'Sounds on time even with the app closed. Controllable later in Settings.',
      'fr': "Retentit à l'heure même app fermée. Réglable ensuite dans les paramètres."
    },
    'search': {'ar': 'ابحث...', 'en': 'Search...', 'fr': 'Rechercher...'},
  };

  String _lc(String k) => _kLoc[k]![_locale] ?? _kLoc[k]!['ar']!;

  Future<String?> _pickFromSheet(String title, List<String> items) {
    var query = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          // Case-insensitive: 'egypt' must find 'Egypt' (Arabic is unaffected).
          final q = query.toLowerCase();
          final filtered = [
            for (final i in items)
              if (q.isEmpty || i.toLowerCase().contains(q)) i
          ];
          return SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: SizedBox(
                height: 480,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.heading)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                          hintText: _lc('search'), isDense: true),
                      onChanged: (v) => setSheet(() => query = v.trim()),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(filtered[i]),
                        onTap: () => Navigator.pop(ctx, filtered[i]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _locPickField(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Expanded(
            child: Text(value ?? label,
                style: TextStyle(
                    color: value == null ? AppColors.muted : AppColors.text)),
          ),
          Icon(Icons.expand_more, color: AppColors.muted, size: 20),
        ]),
      ),
    );
  }

  Future<void> _pickPrayerCountry() async {
    final cities = await loadCities();
    if (!mounted) return;
    final ar = _locale == 'ar';
    final seen = <String>{};
    final countries = <String>[
      for (final c in cities)
        if (seen.add(ar ? c.countryAr : c.countryEn)) ar ? c.countryAr : c.countryEn
    ]..sort();
    final country = await _pickFromSheet(_lc('country'), countries);
    if (country == null || !mounted) return;
    setState(() {
      _prayerCountry = country;
      _prayerCity = null; // country changed: the old city no longer applies
    });
  }

  Future<void> _pickPrayerCity() async {
    if (_prayerCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_lc('pickCountryFirst'))));
      return;
    }
    final cities = await loadCities();
    if (!mounted) return;
    final ar = _locale == 'ar';
    final inCountry = cities
        .where((c) => (ar ? c.countryAr : c.countryEn) == _prayerCountry)
        .toList()
      ..sort((a, b) =>
          (ar ? a.cityAr : a.cityEn).compareTo(ar ? b.cityAr : b.cityEn));
    final cityName = await _pickFromSheet(
        _lc('city'), [for (final c in inCountry) ar ? c.cityAr : c.cityEn]);
    if (cityName == null || !mounted) return;
    setState(() => _prayerCity = inCountry
        .firstWhere((c) => (ar ? c.cityAr : c.cityEn) == cityName));
  }

  Widget _locationStep(AppLocalizations l10n) {
    final ar = _locale == 'ar';
    final city = _prayerCity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(_lc('title'), style: headingStyle(20, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_lc('why'),
            style:
                TextStyle(color: AppColors.muted, fontSize: 12, height: 1.6)),
        const SizedBox(height: 16),
        if (!kIsWeb)
          FilledButton.icon(
            onPressed: _locating ? null : _tryGps,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, size: 18),
            label: Text(_lc('gps')),
          ),
        if (!kIsWeb) const SizedBox(height: 14),
        Text(_lc('orManual'),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.muted)),
        const SizedBox(height: 8),
        _locPickField(_lc('country'), _prayerCountry, _pickPrayerCountry),
        const SizedBox(height: 10),
        _locPickField(_lc('city'),
            city == null ? null : (ar ? city.cityAr : city.cityEn),
            _pickPrayerCity),
        if (city != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.check_circle_rounded,
                size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_lc('located')}: ${ar ? city.cityAr : city.cityEn} · ${ar ? city.countryAr : city.countryEn}',
                style: TextStyle(color: AppColors.text, fontSize: 12.5),
              ),
            ),
          ]),
          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _adhanOn,
              activeThumbColor: AppColors.accent,
              title: Text(_lc('adhan'), style: const TextStyle(fontSize: 13)),
              subtitle: Text(_lc('adhanSub'),
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              onChanged: (v) => setState(() => _adhanOn = v),
            ),
          ],
        ],
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
              child: Text(_isLastStep ? l10n.startJourney : l10n.next),
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
    if (_current == _Step.survey) {
      AnalyticsService.instance.track('survey_completed', {
        'has_gender': _gender != null,
        'has_age': _ageRange != null,
        'has_country': _country != null,
      });
    }
    if (_isLastStep) {
      _finish();
    } else {
      _next();
    }
  }

  // Localized reason the current step can't advance, or null when it can.
  String? _stepError() {
    switch (_current) {
      case _Step.survey:
        return _gender == null ? _msg('gender') : null;
      case _Step.track:
        return _track == null ? _msg('track') : null;
      case _Step.habit:
        return (_custom ? _nameCtrl.text.trim().isEmpty : _picked == null)
            ? _msg('habit')
            : null;
      case _Step.setup:
        return _nameCtrl.text.trim().isEmpty ? _msg('habit') : null;
      case _Step.location:
        return null; // optional by design: configurable later in Settings
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
    // optional islamic marker).
    // Since 2026-07-20 these are Icons, not emoji Texts. An Icon has a FIXED
    // logical size and does not grow with the OS font setting, so the reserve
    // is a constant. Kept a touch generous: over-reserving only makes the
    // label wrap sooner, while under-reserving hard-overflows the Wrap line.
    final iconW = 19 + 8.0; // icon + gap
    final islamicW = 13 + 6.0; // mosque marker + gap
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
            style: headingStyle(20, weight: FontWeight.w800)),
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
                      HabitIcon(habitKey: h.key, emoji: h.icon, size: 19),
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
                        Icon(Icons.mosque_rounded,
                            size: 13, color: AppColors.accent2),
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
                Icon(Icons.edit_note_rounded, size: 24, color: AppColors.accent),
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
