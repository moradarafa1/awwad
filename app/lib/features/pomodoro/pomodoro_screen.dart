import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/data/local_store.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';

/// Pomodoro focus timer. A productivity tool that complements habit building:
/// focus in short, repeatable sprints (25m focus / 5m short break / 15m long
/// break after 4 focus sprints). Fully self-contained and trilingual.
class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

enum _Phase { focus, shortBreak, longBreak }

class _PomodoroScreenState extends ConsumerState<PomodoroScreen>
    with TickerProviderStateMixin {
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

  // ----- animation (only while the timer is RUNNING; idle = a still dial) ---
  // _frame is a 1s repeating clock that rebuilds the dial every frame, so the
  // ring sweeps CONTINUOUSLY instead of jumping once per second. _pulse drives
  // the breathing glow behind it. _deadline gives sub-second precision (and
  // survives a backgrounded tab, where 1s timers get throttled).
  late final AnimationController _frame;
  late final AnimationController _pulse;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _frame = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _restoreSession();
  }

  // ---- session persistence: a running timer survives app restarts ---------
  void _persist() {
    final LocalStore store;
    try {
      store = ref.read(localStoreProvider);
    } catch (_) {
      return; // store not wired (bare widget tests): timer still works
    }
    store.savePomodoro({
      'phase': _phase.name,
      'focusMin': _focusMin,
      'completedFocus': _completedFocus,
      'running': _running,
      'remaining': _remaining,
      'deadlineMs': _deadline?.millisecondsSinceEpoch,
    });
  }

  void _restoreSession() {
    final Map<String, dynamic>? saved;
    try {
      saved = ref.read(localStoreProvider).loadPomodoro();
    } catch (_) {
      return; // store not wired (bare widget tests)
    }
    if (saved == null) return;
    _phase = _Phase.values.asNameMap()[saved['phase']] ?? _Phase.focus;
    _focusMin = (saved['focusMin'] as num?)?.toInt() ?? 25;
    _completedFocus = (saved['completedFocus'] as num?)?.toInt() ?? 0;
    final wasRunning = saved['running'] == true;
    final deadlineMs = (saved['deadlineMs'] as num?)?.toInt();
    if (wasRunning && deadlineMs != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(deadlineMs);
      final left = deadline.difference(DateTime.now()).inSeconds;
      if (left > 1) {
        // Resume mid-phase: the end notification from the original _start()
        // is still armed with the OS, so only the in-app timer restarts.
        _remaining = left;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_running) _start(resume: true);
        });
        return;
      }
      // The phase finished while the app was closed (the OS notification
      // already fired). Land on the NEXT phase, idle.
      if (_phase == _Phase.focus) {
        _completedFocus++;
        _phase = (_completedFocus % _roundsBeforeLong == 0)
            ? _Phase.longBreak
            : _Phase.shortBreak;
      } else {
        _phase = _Phase.focus;
      }
      _remaining = _total;
      _persist();
      return;
    }
    _remaining =
        ((saved['remaining'] as num?)?.toInt() ?? _total).clamp(1, _total);
  }

  void _startAnim() {
    _frame.repeat();
    _pulse.repeat(reverse: true);
  }

  void _stopAnim() {
    _frame.stop();
    _pulse.stop();
    _pulse.value = 0;
  }

  /// Seconds left with sub-second precision while running (for a smooth ring).
  double get _remainingExact {
    final d = _deadline;
    if (!_running || d == null) return _remaining.toDouble();
    final ms = d.difference(DateTime.now()).inMilliseconds;
    return (ms / 1000).clamp(0, _total.toDouble()).toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frame.dispose();
    _pulse.dispose();
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

  void _start({bool resume = false}) {
    if (_running) return;
    setState(() {
      _running = true;
      _deadline = DateTime.now().add(Duration(seconds: _remaining));
    });
    _startAnim();
    if (!resume) {
      AnalyticsService.instance
          .track('pomodoro_start', {'phase': _phase.name});
      // OS alarm at phase end: the chime arrives on time even if the app is
      // killed mid-session. (On resume the original alarm is still armed.)
      final lang = Localizations.localeOf(context).languageCode;
      final s = _strings[lang] ?? _strings['en']!;
      schedulePomodoroDone(
          Duration(seconds: _remaining),
          s['title']!,
          _phase == _Phase.focus ? s['doneFocus']! : s['doneBreak']!);
    }
    _persist();
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
    _stopAnim();
    cancelPomodoroDone();
    setState(() {
      _running = false;
      _deadline = null;
    });
    _persist();
  }

  void _reset() {
    _timer?.cancel();
    _stopAnim();
    cancelPomodoroDone();
    setState(() {
      _running = false;
      _deadline = null;
      _remaining = _total;
    });
    _persist();
  }

  void _switchPhase(_Phase p) {
    _timer?.cancel();
    _stopAnim();
    cancelPomodoroDone();
    setState(() {
      _phase = p;
      _running = false;
      _deadline = null;
      _remaining = _total;
    });
    _persist();
  }

  void _setFocusLength(int min) {
    _timer?.cancel();
    _stopAnim();
    cancelPomodoroDone();
    setState(() {
      _focusMin = min;
      _running = false;
      _deadline = null;
      if (_phase == _Phase.focus) _remaining = min * 60;
    });
    _persist();
  }

  void _completePhase() {
    _timer?.cancel();
    _stopAnim();
    final lang = Localizations.localeOf(context).languageCode;
    final s = _strings[lang] ?? _strings['en']!;
    final wasFocus = _phase == _Phase.focus;
    AnalyticsService.instance.track('pomodoro_complete', {'phase': _phase.name});
    setState(() {
      _running = false;
      _deadline = null;
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
    _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(wasFocus ? s['doneFocus']! : s['doneBreak']!,
            style: TextStyle(color: AppColors.text)),
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
            // Phase selector. A Wrap (not a Row): the three pills together are
            // wider than a 360dp screen in French, so they must flow to a
            // second line instead of overflowing.
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _phaseChip(t['focus']!, _Phase.focus),
                _phaseChip(t['short']!, _Phase.shortBreak),
                _phaseChip(t['long']!, _Phase.longBreak),
              ],
            ),
            const SizedBox(height: 28),
            // Timer dial (tap anywhere on it to start / pause). While the timer
            // RUNS it is alive: a breathing glow behind the ring, a ring that
            // sweeps continuously (not a once-per-second jump) and a bright
            // head dot riding the arc. Idle, everything is still.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _running ? _pause : _start,
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_frame, _pulse]),
                    builder: (context, _) {
                      final exact = _remainingExact;
                      final p = _total == 0
                          ? 0.0
                          : (1 - exact / _total).clamp(0.0, 1.0);
                      final beat = _running ? _pulse.value : 0.0;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Breathing glow.
                          Transform.scale(
                            scale: 1 + 0.05 * beat,
                            child: Container(
                              width: 216,
                              height: 216,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _phaseColor
                                    .withValues(alpha: 0.05 + 0.09 * beat),
                                boxShadow: [
                                  BoxShadow(
                                    color: _phaseColor.withValues(
                                        alpha: 0.10 + 0.16 * beat),
                                    blurRadius: 26 + 18 * beat,
                                    spreadRadius: 2 + 6 * beat,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: CircularProgressIndicator(
                              value: p,
                              strokeWidth: 12,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(_phaseColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Head dot riding the arc (starts at 12 o'clock).
                          if (_running)
                            Transform.rotate(
                              angle: p * 2 * math.pi,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.heading,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _phaseColor.withValues(
                                            alpha: 0.6 + 0.4 * beat),
                                        blurRadius: 10 + 6 * beat,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // The dial is a fixed 240x240 circle: at a large OS
                          // font scale the 56px digits alone overflow it, so
                          // scale the stack down to fit instead of clipping it.
                          Padding(
                            padding: const EdgeInsets.all(28),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_fmt(exact.ceil()),
                                      style: TextStyle(
                                          fontSize: 56,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.heading)),
                                  const SizedBox(height: 4),
                                  Text(phaseLabel,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _phaseColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Controls
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: _running ? _pause : _start,
                    style: FilledButton.styleFrom(backgroundColor: _phaseColor),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          _running
                              ? t['pause']!
                              : (_remaining == _total
                                  ? t['start']!
                                  : t['resume']!),
                          maxLines: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Flexible (never a bare child) + a FINITE minimumSize: a bare
                // child of a Row gets UNBOUNDED width, and Size.fromHeight(52)
                // means an INFINITE minimum width, which together threw
                // "BoxConstraints forces an infinite width" on every frame.
                // The loose fit lets the label scale down on narrow screens
                // instead of pushing the row into an overflow.
                Flexible(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      minimumSize: const Size(64, 52),
                      side: BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t['reset']!, maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Focus length selector (only meaningful for focus phase)
            Text(t['focusLength']!,
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
                  Icon(Icons.local_fire_department,
                      color: AppColors.accent3),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t['sessions']!,
                        style: TextStyle(color: AppColors.text)),
                  ),
                  Text('$_completedFocus',
                      style: TextStyle(
                          color: AppColors.heading,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(t['hint']!,
                style: TextStyle(
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
