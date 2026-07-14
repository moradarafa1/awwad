import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/catalog/habit_content.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import '../shield/dns_shield_screen.dart';

/// «لحظة ضعف» - the urge-surfing SOS screen (evidence-based HRT support).
///
/// Opens in the moment a craving hits. Guides the user through:
///   1. paced breathing (4s in / 2s hold / 6s out, animated circle),
///   2. a 5-minute "urge wave" countdown (urges crest and pass),
///   3. their own written reason for starting,
///   4. the habit's tailored competing responses (quick actions),
///   5. short adhkar (respects the religious-content toggle).
/// Pure Flutter: works on Android, iOS and web with zero permissions.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key, this.habitId});

  /// When set (from the «هُدنة» nav flow), the screen targets THIS habit
  /// instead of the active one, so the user can get help for any break habit
  /// without switching their active tab context.
  final String? habitId;

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with TickerProviderStateMixin {
  static const _waveSeconds = 5 * 60;
  late final AnimationController _breath; // one full 12s breathing cycle
  late final AnimationController _ripple; // urge "wave" rings, 3.4s
  Timer? _tick;
  int _left = _waveSeconds;
  // Sub-second precision for the wave ring (a 1s timer alone makes it step).
  DateTime _waveEnd = DateTime.now().add(const Duration(seconds: _waveSeconds));

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track('sos_opened');
    _breath = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _ripple = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400))
      ..repeat();
    _startWave();
  }

  void _startWave() {
    _tick?.cancel();
    _left = _waveSeconds;
    _waveEnd = DateTime.now().add(const Duration(seconds: _waveSeconds));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left > 0) {
        setState(() => _left--);
      } else {
        _tick?.cancel();
      }
    });
  }

  /// Seconds left, fractional, so the ring sweeps instead of stepping.
  double get _leftExact {
    if (_left <= 0) return 0;
    final ms = _waveEnd.difference(DateTime.now()).inMilliseconds;
    return (ms / 1000).clamp(0, _waveSeconds.toDouble()).toDouble();
  }

  @override
  void dispose() {
    _breath.dispose();
    _ripple.dispose();
    _tick?.cancel();
    super.dispose();
  }

  String _tr(String k) =>
      (_sosStrings[Localizations.localeOf(context).languageCode] ??
          _sosStrings['en']!)[k]!;

  /// 0..1 breath cycle position -> (scale, phase label key).
  (double, String) _breathState(double t) {
    // 4s inhale, 2s hold, 6s exhale (of a 12s cycle).
    if (t < 4 / 12) {
      final p = t / (4 / 12);
      return (0.55 + 0.45 * Curves.easeInOut.transform(p), 'breatheIn');
    }
    if (t < 6 / 12) return (1.0, 'breatheHold');
    final p = (t - 6 / 12) / (6 / 12);
    return (1.0 - 0.45 * Curves.easeInOut.transform(p), 'breatheOut');
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    Habit? habit = s.activeHabit;
    if (widget.habitId != null) {
      for (final h in s.habits) {
        if (h.id == widget.habitId) {
          habit = h;
          break;
        }
      }
    }
    final actions =
        habitChecklistLabels(habit?.catalogKey, 'competing_response', locale)
            .take(4)
            .toList();
    final mm = (_left ~/ 60).toString();
    final ss = (_left % 60).toString().padLeft(2, '0');
    final waveDone = _left == 0;

    return Scaffold(
      appBar: AppBar(title: Text(_tr('title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_tr('subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.7)),
            const SizedBox(height: 18),
            // Breathing circle: the urge rides out as rings that expand and
            // fade (the "wave"), the circle breathes 4s in / 2s hold / 6s out,
            // and the ring around it fills as the 5 minutes pass.
            SizedBox(
              height: 210,
              child: AnimatedBuilder(
                animation: Listenable.merge([_breath, _ripple]),
                builder: (context, child) {
                  final (scale, phaseKey) = _breathState(_breath.value);
                  final waveP =
                      (1 - _leftExact / _waveSeconds).clamp(0.0, 1.0);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Two staggered rings expanding outward and fading.
                      for (final offset in const [0.0, 0.5])
                        Builder(builder: (context) {
                          final t = (_ripple.value + offset) % 1.0;
                          final eased = Curves.easeOut.transform(t);
                          return Opacity(
                            opacity: (1 - t) * 0.35,
                            child: Container(
                              width: 120 + 90 * eased,
                              height: 120 + 90 * eased,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.accent2, width: 1.5),
                              ),
                            ),
                          );
                        }),
                      // Wave progress ring (how much of the 5 minutes passed).
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: waveDone ? 1.0 : waveP,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          backgroundColor:
                              AppColors.accent2.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.accent2.withValues(alpha: 0.75)),
                        ),
                      ),
                      // The breathing circle itself.
                      Container(
                        width: 160 * scale,
                        height: 160 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent2.withValues(alpha: 0.18),
                          border:
                              Border.all(color: AppColors.accent2, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent2
                                  .withValues(alpha: 0.10 + 0.16 * (scale - 0.55)),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Cross-fade the breathing instruction as it changes.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: Text(_tr(phaseKey),
                            key: ValueKey(phaseKey),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.heading)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Urge-wave countdown.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(waveDone ? _tr('waveDone') : _tr('waveTitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.heading)),
                  const SizedBox(height: 8),
                  if (!waveDone) ...[
                    Text('$mm:$ss',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent2)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      // Rebuilt every frame with the breath clock, so the bar
                      // creeps forward smoothly instead of ticking.
                      child: AnimatedBuilder(
                        animation: _breath,
                        builder: (context, _) => LinearProgressIndicator(
                          value: (1 - _leftExact / _waveSeconds)
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              AppColors.accent2.withValues(alpha: 0.15),
                          color: AppColors.accent2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_tr('waveHint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.6)),
                  ] else
                    Text(_tr('waveDoneHint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.6)),
                ],
              ),
            ),
            // Why you started.
            if ((habit?.reason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tr('whyTitle'),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.accent)),
                    const SizedBox(height: 6),
                    Text(habit!.reason!.trim(),
                        style: TextStyle(
                            color: AppColors.text, height: 1.7)),
                  ],
                ),
              ),
            ],
            // Tailored quick actions (competing responses).
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_tr('actionsTitle'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.heading)),
              const SizedBox(height: 8),
              for (final a in actions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.accent2),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(a,
                              style: TextStyle(
                                  color: AppColors.text, height: 1.6))),
                    ],
                  ),
                ),
            ],
            // Adhkar (respects the religious-content toggle).
            if (s.settings.showReligiousContent) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tr('dhikrTitle'),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.accent2)),
                    const SizedBox(height: 8),
                    Text(
                        'أستغفر الله العظيم وأتوب إليه.\nلا حول ولا قوة إلا بالله.\nاللهم إني أعوذ بك من شر نفسي.',
                        style: TextStyle(
                            color: AppColors.text,
                            height: 2.0,
                            fontSize: 15)),
                  ],
                ),
              ),
            ],
            // Phone-wide content shield: most relevant to the secret habit.
            if (habit?.catalogKey == 'secret_habit') ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DnsShieldScreen())),
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: Text(dnsShieldTitle(locale)),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                AnalyticsService.instance.track('sos_won');
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.emoji_events_outlined),
              label: Text(_tr('winBtn')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(_startWave),
              child: Text(_tr('stillBtn')),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prominent entry button shown on the Today tab for break habits.
class SosEntryButton extends StatelessWidget {
  const SosEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final label =
        (_sosStrings[loc] ?? _sosStrings['en']!)['entryBtn']!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SosScreen())),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.danger.withValues(alpha: 0.16),
              AppColors.accent3.withValues(alpha: 0.10),
            ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  color: AppColors.danger),
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

const Map<String, Map<String, String>> _sosStrings = {
  'ar': {
    'title': 'لحظة ضعف',
    'subtitle':
        'الرغبة موجة: تصعد ثم تنكسر خلال دقائق. تنفّس معنا وابقَ هنا حتى تمرّ.',
    'breatheIn': 'خذ نفساً عميقاً',
    'breatheHold': 'أمسِك',
    'breatheOut': 'أخرِج الهواء ببطء',
    'waveTitle': 'موجة الرغبة تنكسر خلال',
    'waveHint': 'لا تقاوم الفكرة، راقبها فقط وهي تمرّ. أنت لست رغبتك.',
    'waveDone': 'مرّت الموجة!',
    'waveDoneHint': 'أحسنت. لقد صمدت حتى انكسرت الرغبة. هذا نصر حقيقي.',
    'whyTitle': 'تذكّر لماذا بدأت',
    'actionsTitle': 'افعل الآن بدلاً من ذلك',
    'dhikrTitle': 'اذكر الله',
    'winBtn': 'انتصرت، الحمد لله',
    'stillBtn': 'ما زلت أقاوم، أعد المؤقت',
    'entryBtn': 'لحظة ضعف؟ اضغط هنا وسنعبرها معاً',
  },
  'en': {
    'title': 'Weak moment',
    'subtitle':
        'An urge is a wave: it rises, then breaks within minutes. Breathe with us and stay here until it passes.',
    'breatheIn': 'Breathe in deeply',
    'breatheHold': 'Hold',
    'breatheOut': 'Breathe out slowly',
    'waveTitle': 'The urge wave breaks in',
    'waveHint':
        "Don't fight the thought; just watch it pass. You are not your urge.",
    'waveDone': 'The wave has passed!',
    'waveDoneHint':
        'Well done. You held on until the urge broke. That is a real win.',
    'whyTitle': 'Remember why you started',
    'actionsTitle': 'Do this instead, right now',
    'dhikrTitle': 'Remember Allah',
    'winBtn': 'I made it through',
    'stillBtn': 'Still fighting, restart the timer',
    'entryBtn': 'Weak moment? Tap here, we will get through it together',
  },
  'fr': {
    'title': 'Moment de faiblesse',
    'subtitle':
        "Une envie est une vague : elle monte puis se brise en quelques minutes. Respirez avec nous et restez ici jusqu'à ce qu'elle passe.",
    'breatheIn': 'Inspirez profondément',
    'breatheHold': 'Retenez',
    'breatheOut': 'Expirez lentement',
    'waveTitle': "La vague d'envie se brise dans",
    'waveHint':
        "Ne combattez pas la pensée ; regardez-la passer. Vous n'êtes pas votre envie.",
    'waveDone': 'La vague est passée !',
    'waveDoneHint':
        "Bravo. Vous avez tenu jusqu'à ce que l'envie se brise. Une vraie victoire.",
    'whyTitle': 'Rappelez-vous pourquoi vous avez commencé',
    'actionsTitle': 'Faites ceci à la place, maintenant',
    'dhikrTitle': 'Invoquez Allah',
    'winBtn': "J'ai tenu bon",
    'stillBtn': 'Je résiste encore, relancer le minuteur',
    'entryBtn': 'Moment de faiblesse ? Appuyez ici, traversons-le ensemble',
  },
};
