import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import '../../core/notifications/notifications.dart';
import '../../core/platform/reliability.dart';

/// One-time permissions sheet, shown on the FIRST arrival at the home screen.
///
/// Owner instruction 2026-07-20: ask for everything the app will genuinely
/// need up front, with a reason per item, so later features never spring a
/// surprise dialog. And ONLY what is needed: no contacts, no camera, no
/// microphone; audio playback, internet and background scheduling need no
/// runtime grant on Android, so they are not listed as requests.
///
/// Two kinds of rows, deliberately mixed:
///  - real runtime dialogs (notifications, location), requested in place;
///  - special-access screens Android only grants via Settings (battery
///    exemption). Usage access is NOT here: it stays lazily asked inside the
///    phone-usage screen, because a Settings deep-dive before the user has
///    seen the feature reads as spyware and gets denied.
///
/// Skippable as a whole; every feature stays fail-open without its grant.
class PermissionsPrimer extends StatefulWidget {
  const PermissionsPrimer({super.key});

  /// Shows the sheet once. The caller owns the "already shown" flag.
  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (_) => const PermissionsPrimer(),
      );

  @override
  State<PermissionsPrimer> createState() => _PermissionsPrimerState();
}

class _PermissionsPrimerState extends State<PermissionsPrimer> {
  bool _notif = false;
  bool _loc = false;
  bool _batteryOpened = false;

  String get _l =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  String _s(String key) => const {
        'title': {
          'ar': 'أذونات يحتاجها عوّاد',
          'en': 'Permissions Awwad needs',
          'fr': 'Autorisations nécessaires'
        },
        'sub': {
          'ar':
              'نطلبها الآن مرة واحدة وبوضوح. كل ميزة تعمل قدر المستطاع حتى لو رفضت إذنها.',
          'en':
              'Asked once, clearly. Every feature degrades gracefully if you decline.',
          'fr':
              'Demandées une fois, clairement. Tout continue de fonctionner si vous refusez.'
        },
        'notif': {
          'ar': 'الإشعارات',
          'en': 'Notifications',
          'fr': 'Notifications'
        },
        'notifWhy': {
          'ar': 'التذكير اليومي، والأذان في وقته، وتنبيه تجاوز حد الاستخدام.',
          'en': 'Daily reminders, the adhan on time, usage-limit alerts.',
          'fr': "Rappels quotidiens, adhan à l'heure, alertes d'usage."
        },
        'loc': {
          'ar': 'الموقع الجغرافي',
          'en': 'Location',
          'fr': 'Localisation'
        },
        'locWhy': {
          'ar':
              'لحساب مواقيت الصلاة فلكياً على جهازك. يُستخدم مرة ولا يغادر هاتفك، ويمكنك اختيار مدينتك يدوياً بدلاً منه.',
          'en':
              'Computes prayer times on your device. Used once, never leaves your phone; you can pick a city manually instead.',
          'fr':
              'Calcule les horaires de prière sur votre appareil. Jamais transmis; ville choisissable manuellement.'
        },
        'battery': {
          'ar': 'استثناء توفير البطارية',
          'en': 'Battery exemption',
          'fr': "Exemption d'économie de batterie"
        },
        'batteryWhy': {
          'ar':
              'بعض الهواتف توقف التنبيهات المجدولة لتوفير الطاقة. الاستثناء يُبقي تذكيراتك تصل في وقتها.',
          'en':
              'Some phones kill scheduled alarms to save power. The exemption keeps reminders on time.',
          'fr':
              'Certains téléphones coupent les alarmes programmées. Cette exemption garde vos rappels.'
        },
        'grant': {'ar': 'السماح', 'en': 'Allow', 'fr': 'Autoriser'},
        'open': {'ar': 'افتح الإعدادات', 'en': 'Open settings', 'fr': 'Réglages'},
        'done': {'ar': 'تم', 'en': 'Done', 'fr': 'Fait'},
        'later': {'ar': 'لاحقاً', 'en': 'Later', 'fr': 'Plus tard'},
      }[key]![_l] ??
      '';

  Future<void> _askNotif() async {
    final ok = await ensureNotificationPermission();
    if (mounted) setState(() => _notif = ok);
  }

  Future<void> _askLocation() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (mounted) {
        setState(() => _loc = p == LocationPermission.always ||
            p == LocationPermission.whileInUse);
      }
    } catch (_) {
      // Fail-open: the prayer screen still offers the manual city picker.
    }
  }

  Future<void> _openBattery() async {
    await openBatterySettings();
    if (mounted) setState(() => _batteryOpened = true);
  }

  Widget _row(String title, String why, bool granted, String action,
      VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(granted ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: granted ? AppColors.success : AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading)),
                Text(why,
                    style: TextStyle(
                        fontSize: 12, height: 1.55, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!granted)
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(action, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 18, 20, 18 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_s('title'), style: headingStyle(20)),
            const SizedBox(height: 6),
            Text(_s('sub'),
                style: TextStyle(
                    fontSize: 12.5, height: 1.6, color: AppColors.muted)),
            const SizedBox(height: 18),
            _row(_s('notif'), _s('notifWhy'), _notif, _s('grant'), _askNotif),
            _row(_s('loc'), _s('locWhy'), _loc, _s('grant'), _askLocation),
            if (!kIsWeb)
              _row(_s('battery'), _s('batteryWhy'), _batteryOpened, _s('open'),
                  _openBattery),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_s('later'),
                      style: TextStyle(color: AppColors.muted)),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_s('done')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
