import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';

/// Pomodoro focus timer. A productivity tool that complements habit building:
/// focus in short, repeatable sprints (25m focus / 5m short break / 15m long
/// break after 4 focus sprints). Fully self-contained and trilingual.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

enum _Phase { focus, shortBreak, longBreak }

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  // Durations in minutes (the focus length is user-selectable).
  int _focusMin = 25;
  static const int _shortMin = 5;
  static const int _longMin = 15;
  static const int _roundsBeforeLong = 4;

  _Phase _phase = _Phase.focus;
  late int _remaining = _focusMin * 60; // seconds
  Timer? _timer;
  bool _running = false;
  int _completedFocus = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _phaseMinutes => switch (_phase) {
        _Phase.focus => _focusMin,
        _Phase.shortBreak => _shortMin,
        _Phase.longBreak => _longMin,
      };
  int get _total => _phaseMinutes * 60;

  Color get _phaseColor => switch (_phase) {
        _Phase.focus => AppColors.accent,
        _Phase.shortBreak => AppColors.accent2,
        _Phase.longBreak => AppColors.accent3,
      };

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    AnalyticsService.instance.track('pomodoro_start', {'phase': _phase.name});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        _completePhase();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _total;
    });
  }

  void _switchPhase(_Phase p) {
    _timer?.cancel();
    setState(() {
      _phase = p;
      _running = false;
      _remaining = _total;
    });
  }

  void _setFocusLength(int min) {
    _timer?.cancel();
    setState(() {
      _focusMin = min;
      _running = false;
      if (_phase == _Phase.focus) _remaining = min * 60;
    });
  }

  void _completePhase() {
    _timer?.cancel();
    final lang = Localizations.localeOf(context).languageCode;
    final s = _strings[lang] ?? _strings['en']!;
    final wasFocus = _phase == _Phase.focus;
    AnalyticsService.instance.track('pomodoro_complete', {'phase': _phase.name});
    setState(() {
      _running = false;
      if (wasFocus) {
        _completedFocus++;
        _phase = (_completedFocus % _roundsBeforeLong == 0)
            ? _Phase.longBreak
            : _Phase.shortBreak;
      } else {
        _phase = _Phase.focus;
      }
      _remaining = _total;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(wasFocus ? s['doneFocus']! : s['doneBreak']!,
            style: const TextStyle(color: AppColors.text)),
      ));
    }
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final t = _strings[lang] ?? _strings['en']!;
    final progress = _total == 0 ? 0.0 : 1 - (_remaining / _total);
    final phaseLabel = switch (_phase) {
      _Phase.focus => t['focus']!,
      _Phase.shortBreak => t['short']!,
      _Phase.longBreak => t['long']!,
    };

    return Scaffold(
      appBar: AppBar(title: Text(t['title']!)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phase selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _phaseChip(t['focus']!, _Phase.focus),
                const SizedBox(width: 8),
                _phaseChip(t['short']!, _Phase.shortBreak),
                const SizedBox(width: 8),
                _phaseChip(t['long']!, _Phase.longBreak),
              ],
            ),
            const SizedBox(height: 28),
            // Timer dial (tap anywhere on it to start / pause)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _running ? _pause : _start,
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(_phaseColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_fmt(_remaining),
                            style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heading)),
                        const SizedBox(height: 4),
                        Text(phaseLabel,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _phaseColor)),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ),
            const SizedBox(height: 28),
            // Controls
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _running ? _pause : _start,
                    style: FilledButton.styleFrom(backgroundColor: _phaseColor),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running
                        ? t['pause']!
                        : (_remaining == _total ? t['start']! : t['resume']!)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(t['reset']!),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Focus length selector (only meaningful for focus phase)
            Text(t['focusLength']!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [15, 25, 50].map((m) {
                final sel = _focusMin == m;
                return ChoiceChip(
                  label: Text('$m ${t['min']!}'),
                  selected: sel,
                  onSelected: (_) => _setFocusLength(m),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent.withValues(alpha: 0.22),
                  labelStyle: TextStyle(
                      color: sel ? AppColors.heading : AppColors.muted,
                      fontWeight: FontWeight.w600),
                  side: BorderSide(
                      color: sel ? AppColors.accent : AppColors.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Session counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      color: AppColors.accent3),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t['sessions']!,
                        style: const TextStyle(color: AppColors.text)),
                  ),
                  Text('$_completedFocus',
                      style: const TextStyle(
                          color: AppColors.heading,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(t['hint']!,
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _phaseChip(String label, _Phase p) {
    final sel = _phase == p;
    return GestureDetector(
      onTap: () => _switchPhase(p),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? AppColors.accent : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? AppColors.heading : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}

const Map<String, Map<String, String>> _strings = {
  'ar': {
    'title': 'بومودورو',
    'focus': 'تركيز',
    'short': 'راحة قصيرة',
    'long': 'راحة طويلة',
    'start': 'ابدأ',
    'pause': 'إيقاف مؤقت',
    'resume': 'متابعة',
    'reset': 'إعادة',
    'min': 'دقيقة',
    'focusLength': 'مدّة جلسة التركيز',
    'sessions': 'جلسات تركيز مكتملة',
    'hint':
        'ركّز مدّةً متّصلة، ثمّ خذ راحةً قصيرة. بعد أربع جلسات خذ راحةً أطول. تقنية بومودورو تعينك على بناء عادة التركيز ورفع الإنتاجية.',
    'doneFocus': 'أحسنت! انتهت جلسة التركيز، خذ قسطاً من الراحة.',
    'doneBreak': 'انتهت الراحة، هيّا نعود إلى التركيز.',
  },
  'en': {
    'title': 'Pomodoro',
    'focus': 'Focus',
    'short': 'Short break',
    'long': 'Long break',
    'start': 'Start',
    'pause': 'Pause',
    'resume': 'Resume',
    'reset': 'Reset',
    'min': 'min',
    'focusLength': 'Focus session length',
    'sessions': 'Completed focus sessions',
    'hint':
        'Focus for one uninterrupted stretch, then take a short break. After four sessions, take a longer break. The Pomodoro technique helps you build a focus habit and boost productivity.',
    'doneFocus': 'Well done! Focus session complete, take a break.',
    'doneBreak': 'Break over. Let us get back to focus.',
  },
  'fr': {
    'title': 'Pomodoro',
    'focus': 'Concentration',
    'short': 'Pause courte',
    'long': 'Pause longue',
    'start': 'Démarrer',
    'pause': 'Pause',
    'resume': 'Reprendre',
    'reset': 'Réinitialiser',
    'min': 'min',
    'focusLength': 'Durée de la session de concentration',
    'sessions': 'Sessions de concentration terminées',
    'hint':
        'Concentrez-vous sans interruption, puis faites une courte pause. Après quatre sessions, prenez une pause plus longue. La technique Pomodoro vous aide à bâtir une habitude de concentration et à gagner en productivité.',
    'doneFocus': 'Bravo ! Session de concentration terminée, faites une pause.',
    'doneBreak': 'Pause terminée. Revenons à la concentration.',
  },
};
