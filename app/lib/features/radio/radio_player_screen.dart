// Live-radio player for the listening habits (hadith / Quran). Plays a chosen
// SBA/qurango public stream and, after the user has actually listened for a
// couple of minutes, auto-logs today's entry for the associated habit (owner
// request: "تسجّل تلقائيًا في يوميات العادة بعد الاستماع").

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme.dart';
import '../../core/radio/radio_stations.dart';
import '../../core/state/app_state.dart';

class RadioPlayerScreen extends ConsumerStatefulWidget {
  const RadioPlayerScreen({
    super.key,
    required this.category, // 'hadith' | 'quran'
    this.habitId, // when set, listening auto-logs this habit
  });
  final String category;
  final String? habitId;

  @override
  ConsumerState<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends ConsumerState<RadioPlayerScreen> {
  final _player = AudioPlayer();
  late List<RadioStation> _stations;
  RadioStation? _station;
  StreamSubscription<Duration>? _posSub;
  int _listenedSeconds = 0;
  bool _autoLogged = false;

  // Auto-log the habit once the user has genuinely listened this long.
  static const _autoLogAfter = 120; // seconds

  @override
  void initState() {
    super.initState();
    _stations = radioByCategory(widget.category);
    _station = _stations.isNotEmpty ? _stations.first : null;
    // Count real listening time (only while actually playing).
    _posSub = _player.positionStream.listen((_) {
      if (_player.playing && !_autoLogged) {
        _listenedSeconds++;
        if (_listenedSeconds >= _autoLogAfter) _autoLog();
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _s(String k) =>
      _kStr[k]![Localizations.localeOf(context).languageCode] ?? _kStr[k]!['ar']!;

  Future<void> _autoLog() async {
    if (_autoLogged || widget.habitId == null) return;
    _autoLogged = true;
    final created = await ref
        .read(appControllerProvider.notifier)
        .quickLogHabit(widget.habitId!, note: _s('autoNote'));
    if (created && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text(_s('autoLogged'))));
    }
  }

  Future<void> _play(RadioStation s) async {
    setState(() {
      _station = s;
      _listenedSeconds = 0;
    });
    try {
      await _player.setUrl(s.url);
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s('playError'))));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_station == null) return;
    if (_player.playing) {
      await _player.pause();
    } else if (_player.audioSource != null) {
      await _player.play();
    } else {
      await _play(_station!);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.category == 'hadith'
              ? _s('titleHadith')
              : _s('titleQuran'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(_s('pickStation'),
              style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          const SizedBox(height: 10),
          for (final s in _stations)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _stationTile(s),
            ),
          const SizedBox(height: 20),
          if (widget.habitId != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Text('✅', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_s('autoHint'),
                      style: TextStyle(
                          color: AppColors.text, fontSize: 11.5, height: 1.6)),
                ),
              ]),
            ),
          const SizedBox(height: 14),
          Text(_s('note'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.muted, fontSize: 11, height: 1.6)),
        ],
      ),
    );
  }

  Widget _stationTile(RadioStation s) {
    final loc = Localizations.localeOf(context).languageCode;
    final selected = _station?.id == s.id;
    final isPlayingThis = selected && _player.playing;
    return InkWell(
      onTap: () => selected ? _toggle() : _play(s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Row(children: [
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snap) {
              final buffering = selected &&
                  (snap.data?.processingState == ProcessingState.loading ||
                      snap.data?.processingState == ProcessingState.buffering);
              if (buffering) {
                return const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2));
              }
              return Icon(
                  isPlayingThis
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: AppColors.accent,
                  size: 30);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(s.t(loc),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.heading)),
          ),
          if (isPlayingThis)
            Text(_s('live'),
                style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
        ]),
      ),
    );
  }
}

const Map<String, Map<String, String>> _kStr = {
  'titleHadith': {
    'ar': 'إذاعة السنة والأحاديث',
    'en': 'Sunnah & hadith radio',
    'fr': 'Radio de la Sunna et du hadith'
  },
  'titleQuran': {
    'ar': 'إذاعة القرآن الكريم',
    'en': 'Holy Quran radio',
    'fr': 'Radio du Saint Coran'
  },
  'pickStation': {
    'ar': 'اختر الإذاعة واستمع مباشرة:',
    'en': 'Pick a station and listen live:',
    'fr': 'Choisissez une station et écoutez en direct :'
  },
  'live': {'ar': '● مباشر', 'en': '● LIVE', 'fr': '● EN DIRECT'},
  'autoHint': {
    'ar': 'يُسجَّل وردك تلقائياً بعد أن تستمع دقيقتين.',
    'en': 'Your wird is logged automatically after two minutes of listening.',
    'fr': 'Votre wird est enregistré automatiquement après deux minutes.'
  },
  'autoLogged': {
    'ar': 'أحسنت! سُجِّل وردك لليوم تلقائياً ✅',
    'en': "Well done! Today's wird was logged automatically ✅",
    'fr': "Bravo ! Votre wird du jour a été enregistré ✅"
  },
  'autoNote': {
    'ar': 'سُجِّل تلقائياً بعد الاستماع',
    'en': 'Auto-logged after listening',
    'fr': "Enregistré après l'écoute"
  },
  'playError': {
    'ar': 'تعذّر تشغيل البث. تأكّد من اتصالك بالإنترنت.',
    'en': 'Could not start the stream. Check your connection.',
    'fr': "Impossible de démarrer le flux. Vérifiez votre connexion."
  },
  'note': {
    'ar': 'بث مباشر من إذاعات هيئة الإعلام السعودية، يحتاج اتصالاً بالإنترنت. لا يُحمَّل أي محتوى على جهازك.',
    'en': 'Live broadcast from the Saudi media authority stations; needs an internet connection. Nothing is downloaded to your device.',
    'fr': "Diffusion en direct des stations saoudiennes; nécessite une connexion. Rien n'est téléchargé."
  },
};
