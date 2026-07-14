import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/reminder_times_picker.dart';

/// Flow for adding an extra habit after onboarding. Reachable from the habit
/// switcher's "+". Enforces the per-track cap (kMaxHabitsPerTrack), hides
/// already-chosen catalog habits, and surfaces the 90-day focus advisory.
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});
  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  String? _track; // 'break' | 'build'
  CatalogHabit? _picked;
  bool _custom = false;
  final _nameCtrl = TextEditingController();
  final _whyCtrl = TextEditingController();
  // Custom-habit slider labels: the user defines what to measure daily.
  final _metricPrimaryCtrl = TextEditingController();
  final _metricSecondaryCtrl = TextEditingController();
  // Money/time-saved calculator inputs (break habits, optional).
  final _costCtrl = TextEditingController();
  List<int> _reminderHours = [20];
  String _query = '';
  bool _advisoryShown = false;

  String get _loc => Localizations.localeOf(context).languageCode;

  String _s(Map<String, String> m) => m[_loc] ?? m['ar'] ?? '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track('add_habit_opened');
    // Show the gentle "focus on one goal for 90 days" advisory once, the first
    // time the user lands here. It is advice only; the real rule is the cap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowAdvisory());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whyCtrl.dispose();
    _metricPrimaryCtrl.dispose();
    _metricSecondaryCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _maybeShowAdvisory() {
    if (_advisoryShown || !mounted) return;
    _advisoryShown = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_s(_kStr['advisoryTitle']!),
            style: TextStyle(color: AppColors.heading)),
        content: Text(_s(_kStr['advisoryBody']!),
            style: TextStyle(color: AppColors.text, height: 1.6)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_s(_kStr['advisoryOk']!))),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final title = _custom
        ? _nameCtrl.text.trim()
        : (_picked?.t(_loc) ?? _nameCtrl.text.trim());
    if (title.isEmpty || _track == null) return;
    final habit = Habit(
      id: const Uuid().v4(),
      track: _track!,
      catalogKey: _custom ? null : _picked?.key,
      isCustom: _custom,
      title: title,
      reason: _whyCtrl.text.trim().isEmpty ? null : _whyCtrl.text.trim(),
      templateKey: _custom ? 'generic' : (_picked?.templateKey ?? 'generic'),
      reminderHour: _reminderHours.isNotEmpty ? _reminderHours.first : 20,
      reminderHours: _reminderHours,
      customMetricPrimary: _custom && _metricPrimaryCtrl.text.trim().isNotEmpty
          ? _metricPrimaryCtrl.text.trim()
          : null,
      customMetricSecondary:
          _custom && _metricSecondaryCtrl.text.trim().isNotEmpty
              ? _metricSecondaryCtrl.text.trim()
              : null,
      costPerDay: _track == 'break'
          ? double.tryParse(_costCtrl.text.trim())
          : null,
      createdAt: DateTime.now(),
    );
    final ok = await ref.read(appControllerProvider.notifier).addHabit(habit);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_s(_kStr['capReached']!)),
          backgroundColor: AppColors.surface));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appControllerProvider);
    final breakFull = !s.canAddTrack('break');
    final buildFull = !s.canAddTrack('build');
    final canConfirm = _track != null &&
        (_custom ? _nameCtrl.text.trim().isNotEmpty : _picked != null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(_s(_kStr['addTitle']!)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // advisory banner (also shown as a dialog on entry)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_s(_kStr['advisoryBody']!),
                          style: TextStyle(
                              fontSize: 12, color: AppColors.muted, height: 1.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(_s(_kStr['chooseTrack']!),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              _trackCard('🚭', _s(_kStr['breakTrack']!),
                  '${s.trackCount('break')}/$kMaxHabitsPerTrack', 'break',
                  AppColors.danger, breakFull),
              const SizedBox(height: 10),
              _trackCard('🌱', _s(_kStr['buildTrack']!),
                  '${s.trackCount('build')}/$kMaxHabitsPerTrack', 'build',
                  AppColors.success, buildFull),
              if (_track != null) ...[
                const SizedBox(height: 22),
                Text(_s(_kStr['chooseHabit']!),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _picker(s),
              ],
              if (canConfirm) ...[
                const SizedBox(height: 22),
                Text(_s(_kStr['nameLabel']!),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 8),
                TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 14),
                Text(_s(_kStr['whyLabel']!),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 8),
                TextField(
                  controller: _whyCtrl,
                  maxLines: 2,
                  decoration:
                      InputDecoration(hintText: _s(_kStr['whyHint']!)),
                ),
                if (_custom) ...[
                  const SizedBox(height: 14),
                  Text(_s(_kStr['metricsTitle']!),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(_s(_kStr['metricsHint']!),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          height: 1.6)),
                  const SizedBox(height: 8),
                  // maxLength keeps a user-typed slider label displayable
                  // everywhere it is echoed (daily log, stats, heatmap sheet).
                  TextField(
                    controller: _metricPrimaryCtrl,
                    maxLength: 30,
                    decoration: InputDecoration(
                        labelText: _s(_kStr['metricP']!),
                        hintText: _s(_kStr['metricPHint']!),
                        counterText: ''),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _metricSecondaryCtrl,
                    maxLength: 30,
                    decoration: InputDecoration(
                        labelText: _s(_kStr['metricS']!),
                        hintText: _s(_kStr['metricSHint']!),
                        counterText: ''),
                  ),
                ],
                if (_track == 'break') ...[
                  const SizedBox(height: 14),
                  Text(_s(_kStr['savingsTitle']!),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(_s(_kStr['savingsHint']!),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          height: 1.6)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: _s(_kStr['costLabel']!)),
                  ),
                ],
                const SizedBox(height: 14),
                Text(_s(_kStr['reminder']!),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 8),
                ReminderTimesPicker(
                  hours: _reminderHours,
                  onChanged: (v) => setState(() => _reminderHours = v),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: canConfirm ? _finish : null,
                icon: const Icon(Icons.add),
                label: Text(_s(_kStr['addBtn']!)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trackCard(String emoji, String title, String count, String track,
      Color color, bool full) {
    final selected = _track == track;
    return Opacity(
      opacity: full ? 0.5 : 1,
      child: InkWell(
        onTap: full
            ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_s(_kStr['trackFull']!)),
                backgroundColor: AppColors.surface))
            : () => setState(() {
                  _track = track;
                  _picked = null;
                  _custom = false;
                  _nameCtrl.clear();
                }),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading)),
              ),
              Text(count,
                  style: TextStyle(
                      color: full ? AppColors.danger : AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: color, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _picker(AppState s) {
    final owned = s.ownedCatalogKeys;
    final all = catalogForTrack(_track!)
        .where((h) => !owned.contains(h.key))
        .where((h) =>
            _query.isEmpty ||
            h.t(_loc).toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final byCat = <String, List<CatalogHabit>>{};
    for (final h in all) {
      byCat.putIfAbsent(h.category, () => []).add(h);
    }
    // The Wrap gives each pill's inner Row UNBOUNDED width, so a bare label
    // Text can never wrap and would hard-overflow. Bound it explicitly to the
    // Wrap line (screen - 32 page padding) minus the pill's own chrome. The
    // emoji Texts scale with the OS font setting, so measure them scaled.
    final scaler = MediaQuery.textScalerOf(context);
    final iconW = scaler.scale(16) * 1.3 + 8; // emoji advance + gap
    final islamicW = scaler.scale(12) * 1.3 + 6;
    double labelMaxWidth(bool isIslamic) =>
        (MediaQuery.sizeOf(context).width -
                32 - // page padding
                24 - // pill padding
                2 - // border
                iconW -
                (isIslamic ? islamicW : 0))
            .clamp(72.0, 420.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: _s(_kStr['search']!),
            prefixIcon: Icon(Icons.search, color: AppColors.muted),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        // custom option
        InkWell(
          onTap: () => setState(() {
            _custom = true;
            _picked = null;
            _nameCtrl.clear();
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _custom
                  ? AppColors.accent2.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _custom ? AppColors.accent2 : AppColors.border),
            ),
            child: Row(
              children: [
                const Text('✏️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_s(_kStr['custom']!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in byCat.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(categoryName(entry.key, _loc),
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.value.map((h) {
              final sel = !_custom && _picked?.key == h.key;
              return InkWell(
                onTap: () => setState(() {
                  _picked = h;
                  _custom = false;
                  _nameCtrl.text = h.t(_loc);
                  _reminderHours = h.defaultReminderHours.isNotEmpty
                      ? [...h.defaultReminderHours]
                      : [20];
                }),
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
                      Text(h.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: labelMaxWidth(h.isIslamic)),
                        child: Text(h.t(_loc),
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
        if (byCat.isEmpty && !_custom)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_s(_kStr['allChosen']!),
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
      ],
    );
  }
}

// Trilingual UI strings, inline (consistent with the rest of the app's
// per-screen string maps).
const Map<String, Map<String, String>> _kStr = {
  'addTitle': {'ar': 'إضافة هدف', 'en': 'Add a goal', 'fr': 'Ajouter un objectif'},
  'addBtn': {'ar': 'إضافة الهدف', 'en': 'Add goal', 'fr': "Ajouter l'objectif"},
  'advisoryTitle': {
    'ar': 'نصيحة قبل أن تبدأ',
    'en': 'A tip before you start',
    'fr': 'Un conseil avant de commencer'
  },
  'advisoryBody': {
    'ar':
        'ننصحك بالتركيز على هدف واحد فقط خلال ٩٠ يوماً، ثم تضيف أهدافاً أخرى. هذا تنبيه فقط، ويمكنك متابعة حتى ٣ عادات للكسر و٣ للبناء في الوقت نفسه.',
    'en':
        'We recommend focusing on a single goal for 90 days, then adding others. This is only a tip - you may track up to 3 break and 3 build habits at the same time.',
    'fr':
        "Nous recommandons de vous concentrer sur un seul objectif pendant 90 jours, puis d'en ajouter d'autres. Ce n'est qu'un conseil : vous pouvez suivre jusqu'à 3 habitudes à briser et 3 à bâtir en même temps."
  },
  'advisoryOk': {'ar': 'فهمت', 'en': 'Got it', 'fr': 'Compris'},
  'chooseTrack': {
    'ar': 'اختر نوع الهدف',
    'en': 'Choose the goal type',
    'fr': "Choisissez le type d'objectif"
  },
  'breakTrack': {'ar': 'كسر عادة', 'en': 'Break a habit', 'fr': 'Briser une habitude'},
  'buildTrack': {'ar': 'بناء عادة', 'en': 'Build a habit', 'fr': 'Bâtir une habitude'},
  'chooseHabit': {'ar': 'اختر العادة', 'en': 'Choose the habit', 'fr': "Choisissez l'habitude"},
  'search': {'ar': 'ابحث...', 'en': 'Search...', 'fr': 'Rechercher...'},
  'custom': {'ar': 'عادة مخصّصة', 'en': 'Custom habit', 'fr': 'Habitude personnalisée'},
  'nameLabel': {'ar': 'اسم الهدف', 'en': 'Goal name', 'fr': "Nom de l'objectif"},
  'whyLabel': {'ar': 'لماذا؟ (اختياري)', 'en': 'Why? (optional)', 'fr': 'Pourquoi ? (facultatif)'},
  'whyHint': {
    'ar': 'دافعك يذكّرك في أوقات الفتور',
    'en': 'Your motivation, for the hard moments',
    'fr': 'Votre motivation, pour les moments difficiles'
  },
  'metricsTitle': {
    'ar': 'مؤشرا قياسك اليومي (اختياري)',
    'en': 'Your two daily measures (optional)',
    'fr': 'Vos deux mesures quotidiennes (facultatif)'
  },
  'metricsHint': {
    'ar':
        'حدد بنفسك ما يقيسه المؤشران في التسجيل اليومي كي يناسب عادتك تماماً. اتركهما فارغين للمقاييس الافتراضية.',
    'en':
        'Define what the two daily sliders measure so they fit your habit exactly. Leave empty for the defaults.',
    'fr':
        "Définissez ce que mesurent les deux curseurs quotidiens pour votre habitude. Laissez vide pour les valeurs par défaut."
  },
  'metricP': {
    'ar': 'المؤشر الأول',
    'en': 'First measure',
    'fr': 'Première mesure'
  },
  'metricPHint': {
    'ar': 'مثال: صفحات القراءة اليوم',
    'en': 'e.g. Pages read today',
    'fr': 'ex. Pages lues aujourd\'hui'
  },
  'metricS': {
    'ar': 'المؤشر الثاني',
    'en': 'Second measure',
    'fr': 'Seconde mesure'
  },
  'metricSHint': {
    'ar': 'مثال: مستوى التركيز',
    'en': 'e.g. Focus level',
    'fr': 'ex. Niveau de concentration'
  },
  'savingsTitle': {
    'ar': 'حاسبة التوفير (اختياري)',
    'en': 'Savings calculator (optional)',
    'fr': "Calculateur d'économies (facultatif)"
  },
  'savingsHint': {
    'ar':
        'كم كانت تكلفك هذه العادة يومياً؟ سنريك كم وفّرت من مال مع كل يوم نظيف.',
    'en':
        'What did this habit cost you daily? We will show the money saved with every clean day.',
    'fr':
        "Combien cette habitude vous coûtait-elle par jour ? Nous afficherons l'argent économisé."
  },
  'costLabel': {
    'ar': 'التكلفة اليومية',
    'en': 'Daily cost',
    'fr': 'Coût quotidien'
  },
  'reminder': {'ar': 'وقت التذكير بتسجيل تقدمك اليومي', 'en': 'Daily progress reminder time', 'fr': 'Heure du rappel de progrès'},
  'capReached': {
    'ar': 'وصلت للحد الأقصى (٣) لهذا النوع',
    'en': 'You reached the limit (3) for this type',
    'fr': 'Vous avez atteint la limite (3) pour ce type'
  },
  'trackFull': {
    'ar': 'هذا النوع مكتمل (٣ عادات). أكمل أحدها أو احذفه أولاً.',
    'en': 'This type is full (3 habits). Finish or remove one first.',
    'fr': 'Ce type est complet (3 habitudes). Terminez ou supprimez-en une.'
  },
  'allChosen': {
    'ar': 'اخترت كل العادات الجاهزة هنا - جرّب عادة مخصّصة.',
    'en': 'You have chosen all preset habits here - try a custom one.',
    'fr': 'Vous avez choisi toutes les habitudes prédéfinies - essayez-en une personnalisée.'
  },
};
