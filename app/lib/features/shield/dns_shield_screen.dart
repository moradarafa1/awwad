import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../app/theme.dart';
import '../../core/platform/dns_shield.dart';

/// The same Cloudflare family service as [kFamilyDnsHost], as plain IPv4
/// resolvers: iOS has no Private DNS hostname field, but its per-WiFi
/// «Configure DNS - Manual» accepts these directly.
const String kFamilyDnsIpA = '1.1.1.3';
const String kFamilyDnsIpB = '1.0.0.3';

/// «درع المحتوى» - guided setup + live verification of Android Private DNS
/// with a family-filtering resolver. Blocks pornography phone-wide (every
/// app, every browser) using a free Cloudflare resolver and ZERO app
/// permissions. On web/iOS the screen degrades to manual instructions.
class DnsShieldScreen extends StatefulWidget {
  const DnsShieldScreen({super.key});
  @override
  State<DnsShieldScreen> createState() => _DnsShieldScreenState();
}

class _DnsShieldScreenState extends State<DnsShieldScreen>
    with WidgetsBindingObserver {
  DnsShieldStatus? _status;
  bool _checking = false;

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

  // Re-check when the user comes back from the system settings screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    final s = await DnsShield.status();
    if (mounted) {
      setState(() {
        _status = s;
        _checking = false;
      });
    }
  }

  String _tr(String k) =>
      (_shieldStrings[Localizations.localeOf(context).languageCode] ??
          _shieldStrings['en']!)[k]!;

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final active = s?.shieldActive ?? false;
    final unsupported = s?.unsupported ?? false;

    final Color statusColor = active
        ? AppColors.success
        : (unsupported ? AppColors.muted : AppColors.accent3);
    final String statusText = active
        ? _tr('statusOn')
        : (unsupported ? _tr('statusUnknown') : _tr('statusOff'));
    final IconData statusIcon = active
        ? Icons.verified_user
        : (unsupported ? Icons.help_outline : Icons.gpp_maybe_outlined);

    return Scaffold(
      appBar: AppBar(title: Text(_tr('title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_tr('intro'),
                style: TextStyle(color: AppColors.muted, height: 1.7)),
            const SizedBox(height: 16),
            // Live status card.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.55)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(statusText,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            height: 1.5)),
                  ),
                  IconButton(
                    onPressed: _checking ? null : _refresh,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.refresh, color: statusColor),
                    tooltip: _tr('recheck'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Setup steps.
            Text(_tr('stepsTitle'),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.heading)),
            const SizedBox(height: 10),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
              // iOS has no Private DNS setting: guide through the per-WiFi
              // manual DNS using the same family service's IPv4 resolvers.
              _step('1', _tr('stepIos1'),
                  trailing: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(
                          text: '$kFamilyDnsIpA, $kFamilyDnsIpB'));
                      _toast(_tr('copied'));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('$kFamilyDnsIpA · $kFamilyDnsIpB',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12)),
                  )),
              _step('2', _tr('stepIos2')),
              _step('3', _tr('stepIos3')),
              _step('4', _tr('stepIos4')),
            ] else ...[
              _step('1', _tr('step1'),
                  trailing: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          const ClipboardData(text: kFamilyDnsHost));
                      _toast(_tr('copied'));
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text(kFamilyDnsHost,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12)),
                  )),
              _step('2', _tr('step2'),
                  trailing: FilledButton.icon(
                    onPressed: () async {
                      final ok = await DnsShield.openSettings();
                      if (!ok && mounted) _toast(_tr('openManually'));
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: Text(_tr('openSettings')),
                  )),
              _step('3', _tr('step3')),
              _step('4', _tr('step4')),
            ],
            const SizedBox(height: 14),
            // What it does / honesty notes.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tr('notesTitle'),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.accent2)),
                  const SizedBox(height: 6),
                  Text(_tr('notes'),
                      style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String n, String text, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent2.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(n,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.accent2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(text,
                      style:
                          TextStyle(color: AppColors.text, height: 1.6))),
            ],
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 34, top: 6),
              child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing),
            ),
        ],
      ),
    );
  }
}

/// Localized screen title, for entry points (Settings tile, SOS link).
String dnsShieldTitle(String locale) =>
    (_shieldStrings[locale] ?? _shieldStrings['en']!)['title']!;

const Map<String, Map<String, String>> _shieldStrings = {
  'ar': {
    'title': 'درع المحتوى',
    'intro':
        'يحجب الدرع المواقع الإباحية والضارة على مستوى الهاتف كله: كل التطبيقات وكل المتصفحات، باستخدام خادم DNS عائلي مجاني من كلاودفلير، ومن دون أي صلاحيات إضافية للتطبيق.',
    'statusOn': 'الدرع مفعّل. هاتفك محمي الآن على مستوى الشبكة.',
    'statusOff':
        'الدرع غير مفعّل بعد. اتبع الخطوات بالأسفل، ثم اضغط زر التحديث.',
    'statusUnknown':
        'تعذّر فحص الحالة تلقائياً على هذا الجهاز. اتبع الخطوات يدوياً.',
    'recheck': 'إعادة الفحص',
    'stepsTitle': 'خطوات التفعيل (أقل من دقيقة)',
    'step1': 'انسخ عنوان الخادم العائلي:',
    'step2': 'افتح إعدادات الهاتف، ثم ابحث عن «DNS الخاص» (Private DNS).',
    'step3': 'اختر «اسم مضيف مزوّد DNS الخاص» والصق العنوان ثم احفظ.',
    'step4': 'ارجع إلى هنا واضغط زر التحديث للتأكد من تفعيل الدرع.',
    'stepIos1': 'انسخ عنواني الخادم العائلي:',
    'stepIos2': 'افتح الإعدادات ثم Wi-Fi، واضغط علامة (i) بجوار شبكتك.',
    'stepIos3':
        'اختر «تكوين DNS» ثم «يدوي»، احذف الخوادم الموجودة وأضف العنوانين، ثم احفظ.',
    'stepIos4':
        'كرر الخطوات لكل شبكة تستخدمها. التحقق التلقائي غير متاح على آيفون، فجرّب فتح موقع محجوب للتأكد.',
    'openSettings': 'افتح الإعدادات',
    'openManually':
        'افتح الإعدادات يدوياً وابحث عن «Private DNS» أو «DNS الخاص».',
    'copied': 'تم نسخ العنوان. الصقه في خانة DNS الخاص.',
    'notesTitle': 'ملاحظات مهمة بصراحة',
    'notes':
        'الحجب يعمل على مستوى الشبكة، وهو قوي لكنه ليس معصوماً: من يملك فتح الإعدادات يمكنه إيقافه. لأقصى إلزام أضف قفلاً على تطبيق الإعدادات عبر أدوات الرقابة في هاتفك.\nعلى أجهزة آيفون: أضف العنوان نفسه من الإعدادات > عام > VPN وإدارة الأجهزة، أو استخدم متصفحاً بحماية عائلية.\nالخدمة مجانية بالكامل من كلاودفلير ولا تجمع بيانات تصفحك لأغراض إعلانية.',
  },
  'en': {
    'title': 'Content shield',
    'intro':
        'The shield blocks pornographic and harmful sites PHONE-WIDE: every app and every browser, using a free Cloudflare family DNS resolver, with no extra app permissions.',
    'statusOn': 'Shield is ON. Your phone is now protected at network level.',
    'statusOff':
        'Shield is not enabled yet. Follow the steps below, then tap refresh.',
    'statusUnknown':
        'Could not check the status automatically on this device. Follow the steps manually.',
    'recheck': 'Re-check',
    'stepsTitle': 'Setup steps (under a minute)',
    'step1': 'Copy the family resolver address:',
    'step2': 'Open phone Settings and search for "Private DNS".',
    'step3':
        'Choose "Private DNS provider hostname", paste the address, and save.',
    'step4': 'Come back here and tap refresh to confirm the shield is on.',
    'stepIos1': 'Copy the two family resolver addresses:',
    'stepIos2': 'Open Settings, tap Wi-Fi, then tap the (i) next to your network.',
    'stepIos3':
        'Choose "Configure DNS" then "Manual", remove the existing servers, add both addresses, and save.',
    'stepIos4':
        'Repeat for every Wi-Fi you use. Auto-check is not available on iPhone; test by opening a blocked site.',
    'openSettings': 'Open Settings',
    'openManually': 'Open Settings manually and search for "Private DNS".',
    'copied': 'Address copied. Paste it into the Private DNS field.',
    'notesTitle': 'Honest notes',
    'notes':
        'Blocking works at network level; it is strong but not unbreakable: anyone who can open Settings can turn it off. For stronger commitment, lock the Settings app with your phone parental tools.\nOn iPhone: add the same hostname under Settings > General > VPN and Device Management, or use a family-safe browser.\nThe service is completely free from Cloudflare and does not sell your browsing data.',
  },
  'fr': {
    'title': 'Bouclier de contenu',
    'intro':
        "Le bouclier bloque les sites pornographiques et nuisibles sur TOUT le téléphone : chaque application et chaque navigateur, via un résolveur DNS familial gratuit de Cloudflare, sans aucune permission supplémentaire.",
    'statusOn':
        'Bouclier ACTIVÉ. Votre téléphone est protégé au niveau du réseau.',
    'statusOff':
        "Bouclier pas encore activé. Suivez les étapes ci-dessous puis actualisez.",
    'statusUnknown':
        'Impossible de vérifier automatiquement sur cet appareil. Suivez les étapes manuellement.',
    'recheck': 'Revérifier',
    'stepsTitle': "Étapes d'activation (moins d'une minute)",
    'step1': "Copiez l'adresse du résolveur familial :",
    'step2':
        'Ouvrez les Réglages du téléphone et cherchez « DNS privé » (Private DNS).',
    'step3':
        "Choisissez « Nom d'hôte du fournisseur DNS privé », collez l'adresse et enregistrez.",
    'step4':
        'Revenez ici et appuyez sur actualiser pour confirmer le bouclier.',
    'stepIos1': 'Copiez les deux adresses du résolveur familial :',
    'stepIos2':
        'Ouvrez Réglages, touchez Wi-Fi, puis le (i) à côté de votre réseau.',
    'stepIos3':
        'Choisissez « Configurer le DNS » puis « Manuel », retirez les serveurs existants, ajoutez les deux adresses et enregistrez.',
    'stepIos4':
        'Répétez pour chaque réseau Wi-Fi. La vérification automatique est indisponible sur iPhone ; testez en ouvrant un site bloqué.',
    'openSettings': 'Ouvrir les réglages',
    'openManually':
        'Ouvrez les réglages manuellement et cherchez « DNS privé ».',
    'copied': "Adresse copiée. Collez-la dans le champ DNS privé.",
    'notesTitle': 'Notes honnêtes',
    'notes':
        "Le blocage agit au niveau du réseau ; il est fort mais pas infaillible : quiconque ouvre les Réglages peut le désactiver. Pour plus d'engagement, verrouillez l'app Réglages avec le contrôle parental.\nSur iPhone : ajoutez le même nom d'hôte, ou utilisez un navigateur familial.\nLe service est entièrement gratuit chez Cloudflare et ne vend pas vos données.",
  },
};
