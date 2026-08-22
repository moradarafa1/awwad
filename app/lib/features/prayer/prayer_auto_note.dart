// The pray_on_time habit has NO manual reminder hours (owner order
// 2026-07-31): its reminders are the five exact prayer-time notifications,
// computed per the user's location by the prayer window (and the adhan when
// enabled). Everywhere the UI would show an hour picker for this habit it
// shows this note instead, listing today's five times once a location exists.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/prayer/prayer_engine.dart';
import '../../core/state/app_state.dart';

const _kAuto = {
  'title': {
    'ar': 'تذكيرات تلقائية بمواقيت الصلاة',
    'en': 'Automatic prayer-time reminders',
    'fr': 'Rappels automatiques aux heures de prière'
  },
  'body': {
    'ar':
        'تُضبط تذكيرات هذه العادة تلقائياً على المواقيت الخمسة حسب موقعك، ومعها الأذان إن فعّلته. لا حاجة لاختيار وقت يدوي.',
    'en':
        'Reminders for this habit follow the five daily prayer times for your location, with the adhan when enabled. No manual time is needed.',
    'fr':
        "Les rappels de cette habitude suivent les cinq horaires de prière selon votre position, avec l'adhan si activé. Aucune heure manuelle n'est requise."
  },
  'today': {'ar': 'مواقيت اليوم', 'en': "Today's times", 'fr': "Aujourd'hui"},
  // Two no-location variants: inside onboarding the location step really IS
  // next; everywhere else pointing at a "next step" would be a lie.
  'noLocOnboarding': {
    'ar': 'بعد تحديد موقعك في الخطوة التالية تُحسب المواقيت على جهازك بلا إنترنت.',
    'en': 'Once you set your location in the next step, the times are computed on-device, offline.',
    'fr': "Une fois votre position définie à l'étape suivante, les horaires sont calculés hors ligne."
  },
  'noLoc': {
    'ar': 'بعد تحديد موقعك من إعدادات مواقيت الصلاة تُحسب المواقيت على جهازك بلا إنترنت.',
    'en': 'Once your location is set in the prayer-times settings, the times are computed on-device, offline.',
    'fr': 'Une fois votre position définie dans les réglages de prière, les horaires sont calculés hors ligne.'
  },
};

class PrayerAutoReminderNote extends ConsumerWidget {
  /// True only inside the onboarding flow, where the location step follows.
  final bool inOnboarding;
  const PrayerAutoReminderNote({super.key, this.inOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = Localizations.localeOf(context).languageCode;
    String t(String k) => _kAuto[k]![loc] ?? _kAuto[k]!['ar']!;
    final raw = ref.read(localStoreProvider).loadPrayer();
    final cfg = raw != null ? PrayerConfig.fromJson(raw) : const PrayerConfig();
    String two(int n) => n.toString().padLeft(2, '0');
    String? times;
    if (cfg.configured) {
      final today = timesFor(cfg, DateTime.now());
      times = kPrayerKeys
          .map((k) => '${prayerName(k, loc)} ${two(today[k]!.hour)}:${two(today[k]!.minute)}')
          .join(' · ');
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.schedule_rounded, size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t('title'),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.heading)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(t('body'),
              style: TextStyle(
                  fontSize: 12, height: 1.6, color: AppColors.text)),
          const SizedBox(height: 8),
          if (times != null)
            Text('${t('today')}: $times',
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent2))
          else
            Text(t(inOnboarding ? 'noLocOnboarding' : 'noLoc'),
                style: TextStyle(
                    fontSize: 11.5, height: 1.6, color: AppColors.muted)),
        ],
      ),
    );
  }
}
