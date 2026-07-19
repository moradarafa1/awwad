import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/platform/usage_stats.dart';

/// «استخدام الهاتف» - phase A of the phone-addiction toolkit: see today's
/// per-app screen time, set a daily minutes limit per app, and get a clear
/// over-limit warning. Monitoring only (no forced blocking yet); the
/// periodic background warning is a documented later phase.
class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});
  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _granted = false;
  List<AppUsage> _usage = const [];
  Map<String, int> _limits = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check after the user returns from the system settings screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final granted = await UsageStatsPlatform.hasPermission();
    final limits = await UsageStatsPlatform.loadLimits();
    final usage = granted ? await UsageStatsPlatform.todayUsage() : const <AppUsage>[];
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _limits = limits;
      _usage = usage;
      _loading = false;
    });
  }

  String _tr(String k) =>
      (_usageStrings[Localizations.localeOf(context).languageCode] ??
          _usageStrings['en']!)[k]!;

  String _fmt(int minutes) {
    final s = splitMinutes(minutes);
    if (s.hours == 0) return '${s.minutes} ${_tr('min')}';
    return '${s.hours} ${_tr('hr')} ${s.minutes} ${_tr('min')}';
  }

  List<AppUsage> get _exceeded => [
        for (final u in _usage)
          if ((_limits[u.package] ?? 0) > 0 && u.minutes > _limits[u.package]!)
            u
      ];

  Future<void> _editLimit(AppUsage u) async {
    final current = _limits[u.package];
    final controller =
        TextEditingController(text: current?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(u.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16)),
        // Scrollable: this content holds a TextField, so the keyboard (plus a
        // large font scale, which pushes the chips onto extra rows) would
        // otherwise clip the dialog.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_tr('limitPrompt'),
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const [15, 30, 60, 120])
                    ActionChip(
                      label: Text('$m ${_tr('min')}'),
                      onPressed: () => Navigator.pop(ctx, m),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: _tr('customMinutes')),
              ),
            ],
          ),
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: Text(_tr('removeLimit'),
                  style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (v != null && v > 0) ? v : null);
            },
            child: Text(_tr('save')),
          ),
        ],
      ),
    );
    if (result == null) return;
    final next = Map<String, int>.from(_limits);
    if (result == 0) {
      next.remove(u.package);
    } else {
      next[u.package] = result;
    }
    await UsageStatsPlatform.saveLimits(next);
    if (mounted) setState(() => _limits = next);
  }

  @override
  Widget build(BuildContext context) {
    final total = _usage.fold<int>(0, (a, u) => a + u.minutes);
    final exceeded = _exceeded;

    return Scaffold(
      appBar: AppBar(title: Text(_tr('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (!UsageStatsPlatform.supported) ...[
                    Text(_tr('unsupported'),
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.muted, height: 1.7)),
                  ] else if (!_granted) ...[
                    Text(_tr('permIntro'),
                        style:
                            TextStyle(color: AppColors.muted, height: 1.7)),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await UsageStatsPlatform.openSettings();
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_tr('openManually'))));
                        }
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: Text(_tr('grantBtn')),
                    ),
                    const SizedBox(height: 8),
                    Text(_tr('permNote'),
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            height: 1.6)),
                  ] else ...[
                    // Over-limit warning banner.
                    if (exceeded.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.danger.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppColors.danger),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_tr('exceededBanner')} ${exceeded.map((e) => e.label).join('، ')}',
                                style: TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Total for today.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent2.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timelapse, color: AppColors.accent2),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('${_tr('totalToday')}: ${_fmt(total)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_tr('tapHint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 11.5)),
                    const SizedBox(height: 10),
                    if (_usage.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_tr('empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    for (final u in _usage) _appRow(u),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _appRow(AppUsage u) {
    final limit = _limits[u.package];
    final over = limit != null && limit > 0 && u.minutes > limit;
    final progress = (limit == null || limit == 0)
        ? null
        : (u.minutes / limit).clamp(0.0, 1.0);
    final color = over
        ? AppColors.danger
        : (limit != null ? AppColors.accent2 : AppColors.muted);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: over ? AppColors.danger : AppColors.border),
      ),
      child: InkWell(
        onTap: () => _editLimit(u),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.heading)),
                      if (u.opens > 0)
                        Text(
                          usageOpensLabel(
                              Localizations.localeOf(context).languageCode,
                              u.opens),
                          style: TextStyle(
                              fontSize: 10.5, color: AppColors.muted),
                        ),
                    ],
                  ),
                ),
                Text(_fmt(u.minutes),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: color)),
              ],
            ),
            if (limit != null && limit > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                over
                    ? '${_tr('overBy')} ${_fmt(u.minutes - limit)}'
                    : '${_tr('limitLabel')}: ${_fmt(limit)}',
                style: TextStyle(fontSize: 11, color: color),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_tr('noLimit'),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.muted)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Localized entry-point title for Settings / daily log cards.
String usageScreenTitle(String locale) =>
    (_usageStrings[locale] ?? _usageStrings['en']!)['title']!;

/// "Opened N times" line for a per-app usage row. Pure so the Arabic
/// number agreement (مرة واحدة / مرتين / N مرات / N مرة) is unit-testable.
String usageOpensLabel(String locale, int n) {
  switch (locale) {
    case 'ar':
      if (n == 1) return 'فُتح مرة واحدة اليوم';
      if (n == 2) return 'فُتح مرتين اليوم';
      // Same n % 100 MSA agreement rule as widgetStreakLabel: 103-110 opens
      // take the plural تمييز (heavy phone days do reach three digits).
      final r = n % 100;
      if (r >= 3 && r <= 10) return 'فُتح $n مرات اليوم';
      return 'فُتح $n مرة اليوم';
    case 'fr':
      return n == 1 ? "Ouvert 1 fois aujourd'hui" : "Ouvert $n fois aujourd'hui";
    default:
      return n == 1 ? 'Opened once today' : 'Opened $n times today';
  }
}

/// Prominent entry card on the Today tab for the phone-addiction habit.
class UsageEntryButton extends StatelessWidget {
  const UsageEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final label = (_usageStrings[loc] ?? _usageStrings['en']!)['entryBtn']!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const UsageScreen())),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent2.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.accent2.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.timelapse, color: AppColors.accent2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.heading)),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

const Map<String, Map<String, String>> _usageStrings = {
  'ar': {
    'title': 'استخدام الهاتف',
    'permIntro':
        'لعرض وقت استخدامك لكل تطبيق وتنبيهك عند تجاوز حدّك اليومي، يحتاج عوّاد إذن «الوصول إلى بيانات الاستخدام». يُمنح هذا الإذن يدوياً من إعدادات النظام ولا يقرأ محتوى أي تطبيق، بل مدة الاستخدام فقط. وتبقى هذه البيانات على جهازك وحده، فلا تُرسل إلى خوادمنا ولا تُشارك مع أي جهة.',
    'grantBtn': 'امنح الإذن من الإعدادات',
    'openManually':
        'افتح إعدادات النظام يدوياً وابحث عن «الوصول إلى بيانات الاستخدام».',
    'permNote':
        'بعد منح الإذن ارجع إلى هذه الشاشة وستظهر بياناتك تلقائياً.',
    'unsupported': 'هذه الميزة متاحة على أجهزة أندرويد فقط.',
    'totalToday': 'إجمالي استخدام اليوم',
    'tapHint': 'اضغط على أي تطبيق لتحديد حدّ يومي له بالدقائق.',
    'empty': 'لا توجد بيانات استخدام لليوم بعد.',
    'limitPrompt': 'اختر الحدّ اليومي المسموح به لهذا التطبيق:',
    'customMinutes': 'عدد دقائق مخصص',
    'removeLimit': 'إزالة الحدّ',
    'save': 'حفظ',
    'limitLabel': 'الحدّ اليومي',
    'noLimit': 'بدون حدّ. اضغط لتحديد حدّ يومي.',
    'overBy': 'تجاوزت حدّك بمقدار',
    'exceededBanner': 'تجاوزت حدّك اليومي في:',
    'entryBtn': 'راقب استخدامك اليوم وحدّد حدودك',
    'min': 'د',
    'hr': 'س',
  },
  'en': {
    'title': 'Phone usage',
    'permIntro':
        'To show your per-app screen time and warn you when you pass your daily limit, Awwad needs the "Usage access" permission. It is granted manually in system settings and reads usage DURATION only, never app content. This data stays on your device alone: it is never sent to our servers and never shared with anyone.',
    'grantBtn': 'Grant access in Settings',
    'openManually':
        'Open system settings manually and search for "Usage access".',
    'permNote':
        'After granting access, come back here and your data will appear automatically.',
    'unsupported': 'This feature is available on Android devices only.',
    'totalToday': 'Total today',
    'tapHint': 'Tap any app to set a daily limit in minutes.',
    'empty': 'No usage data for today yet.',
    'limitPrompt': 'Choose the allowed daily limit for this app:',
    'customMinutes': 'Custom minutes',
    'removeLimit': 'Remove limit',
    'save': 'Save',
    'limitLabel': 'Daily limit',
    'noLimit': 'No limit. Tap to set one.',
    'overBy': 'Over your limit by',
    'exceededBanner': 'You passed your daily limit in:',
    'entryBtn': 'Track today\'s usage and set your limits',
    'min': 'm',
    'hr': 'h',
  },
  'fr': {
    'title': 'Utilisation du téléphone',
    'permIntro':
        "Pour afficher votre temps d'écran par application et vous avertir au-delà de votre limite quotidienne, Awwad a besoin de la permission « Accès aux données d'utilisation ». Elle s'accorde manuellement dans les réglages et ne lit que la DURÉE d'utilisation, jamais le contenu. Ces données restent uniquement sur votre appareil : elles ne sont jamais envoyées à nos serveurs ni partagées.",
    'grantBtn': "Accorder l'accès dans les réglages",
    'openManually':
        "Ouvrez les réglages manuellement et cherchez « Accès aux données d'utilisation ».",
    'permNote':
        "Après avoir accordé l'accès, revenez ici : vos données apparaîtront automatiquement.",
    'unsupported':
        'Cette fonctionnalité est disponible uniquement sur Android.',
    'totalToday': "Total aujourd'hui",
    'tapHint':
        'Touchez une application pour définir sa limite quotidienne en minutes.',
    'empty': "Pas encore de données d'utilisation aujourd'hui.",
    'limitPrompt':
        'Choisissez la limite quotidienne autorisée pour cette application :',
    'customMinutes': 'Minutes personnalisées',
    'removeLimit': 'Retirer la limite',
    'save': 'Enregistrer',
    'limitLabel': 'Limite quotidienne',
    'noLimit': 'Sans limite. Touchez pour en définir une.',
    'overBy': 'Dépassement de',
    'exceededBanner': 'Limite quotidienne dépassée pour :',
    'entryBtn': "Suivez votre utilisation et fixez vos limites",
    'min': 'min',
    'hr': 'h',
  },
};
