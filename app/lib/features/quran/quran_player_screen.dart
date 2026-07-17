// Quran listening-wird player (TODO 0d Phase B). Streams surah mp3s from the
// free mp3quran.net servers via just_audio. The user picks a reciter and a
// surah; the choice persists so the wird resumes where they left off.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme.dart';
import '../../core/quran/quran_data.dart';
import '../../core/state/app_state.dart';

class QuranPlayerScreen extends ConsumerStatefulWidget {
  const QuranPlayerScreen({super.key, this.habitId});

  /// When set, listening for a couple of minutes auto-logs this habit's day.
  final String? habitId;

  @override
  ConsumerState<QuranPlayerScreen> createState() => _QuranPlayerScreenState();
}

class _QuranPlayerScreenState extends ConsumerState<QuranPlayerScreen> {
  final _player = AudioPlayer();
  List<Reciter> _reciters = [];
  Reciter? _reciter;
  int _surah = 18; // default to Al-Kahf
  bool _loading = true;
  String? _error;
  StreamSubscription<Duration>? _posSub;
  int _listenedSeconds = 0;
  bool _autoLogged = false;
  static const _autoLogAfter = 120; // seconds of real listening

  @override
  void initState() {
    super.initState();
    _init();
    _posSub = _player.positionStream.listen((_) {
      if (_player.playing && !_autoLogged) {
        _listenedSeconds++;
        if (_listenedSeconds >= _autoLogAfter) _autoLog();
      }
    });
  }

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

  Future<void> _init() async {
    try {
      _reciters = await loadReciters();
      final saved = ref.read(localStoreProvider).loadQuranWird();
      if (saved != null) {
        _surah = (saved['surah'] as num?)?.toInt() ?? 18;
        final rid = (saved['reciter'] as num?)?.toInt();
        _reciter = _reciters.firstWhere((r) => r.id == rid,
            orElse: () => _reciters.first);
      } else {
        _reciter = _reciters.first;
      }
    } catch (_) {
      _error = 'load';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _s(String k) =>
      _kStr[k]![Localizations.localeOf(context).languageCode] ?? _kStr[k]!['ar']!;

  Future<void> _persist() async {
    if (_reciter == null) return;
    await ref.read(localStoreProvider).saveQuranWird({
      'reciter': _reciter!.id,
      'surah': _surah,
    });
  }

  Future<void> _load() async {
    if (_reciter == null) return;
    try {
      await _player.setUrl(surahUrl(_reciter!, _surah));
      await _persist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s('playError'))));
      }
    }
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.audioSource == null) await _load();
      await _player.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickReciter() async {
    final r = await showModalBottomSheet<Reciter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 460,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(_s('pickReciter'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.heading)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _reciters.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(_reciters[i].nameAr),
                  subtitle: Text(_reciters[i].rewaya,
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  onTap: () => Navigator.pop(ctx, _reciters[i]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    if (r != null) {
      setState(() => _reciter = r);
      await _player.stop();
      await _load();
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickSurah() async {
    final n = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 460,
          child: ListView.builder(
            itemCount: 114,
            itemBuilder: (_, i) => ListTile(
              dense: true,
              leading: Text('${i + 1}',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              title: Text(kSurahNames[i]),
              onTap: () => Navigator.pop(ctx, i + 1),
            ),
          ),
        ),
      ),
    );
    if (n != null) {
      setState(() => _surah = n);
      await _player.stop();
      await _load();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_s('title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_s('loadError')))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _selector(Icons.record_voice_over,
                          _s('reciter'), _reciter?.nameAr ?? '', _pickReciter),
                      const SizedBox(height: 12),
                      _selector(Icons.menu_book, _s('surah'),
                          surahName(_surah), _pickSurah),
                      const SizedBox(height: 32),
                      // Progress + position.
                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snap) {
                          final pos = snap.data ?? Duration.zero;
                          final total = _player.duration ?? Duration.zero;
                          final max = total.inMilliseconds.toDouble();
                          return Column(children: [
                            Slider(
                              value: max <= 0
                                  ? 0
                                  : pos.inMilliseconds
                                      .clamp(0, total.inMilliseconds)
                                      .toDouble(),
                              max: max <= 0 ? 1 : max,
                              onChanged: max <= 0
                                  ? null
                                  : (v) => _player
                                      .seek(Duration(milliseconds: v.round())),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                                Text(_fmt(total),
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                              ],
                            ),
                          ]);
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snap) {
                            final playing = snap.data?.playing ?? false;
                            final buffering = snap.data?.processingState ==
                                    ProcessingState.loading ||
                                snap.data?.processingState ==
                                    ProcessingState.buffering;
                            return GestureDetector(
                              onTap: _toggle,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent
                                      .withValues(alpha: 0.16),
                                  border:
                                      Border.all(color: AppColors.accent, width: 2),
                                ),
                                child: buffering
                                    ? const Padding(
                                        padding: EdgeInsets.all(26),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 44,
                                        color: AppColors.heading),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(_s('note'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              height: 1.6)),
                    ],
                  ),
                ),
    );
  }

  Widget _selector(
      IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.accent2, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          Icon(Icons.expand_more, color: AppColors.muted, size: 20),
        ]),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

const Map<String, Map<String, String>> _kStr = {
  'title': {
    'ar': 'ورد الاستماع للقرآن',
    'en': 'Quran listening wird',
    'fr': "Wird d'écoute du Coran"
  },
  'reciter': {'ar': 'القارئ', 'en': 'Reciter', 'fr': 'Récitateur'},
  'surah': {'ar': 'السورة', 'en': 'Surah', 'fr': 'Sourate'},
  'pickReciter': {
    'ar': 'اختر القارئ',
    'en': 'Choose a reciter',
    'fr': 'Choisir un récitateur'
  },
  'playError': {
    'ar': 'تعذّر تشغيل التلاوة. تأكّد من اتصالك بالإنترنت.',
    'en': 'Could not play the recitation. Check your connection.',
    'fr': "Lecture impossible. Vérifiez votre connexion."
  },
  'loadError': {
    'ar': 'تعذّر تحميل قائمة القرّاء.',
    'en': 'Could not load the reciters list.',
    'fr': 'Impossible de charger la liste des récitateurs.'
  },
  'note': {
    'ar': 'التلاوات تُبَثّ من خوادم mp3quran.net المجانية وتحتاج اتصالاً بالإنترنت. اختيارك يُحفظ ليستأنف وردك.',
    'en': 'Recitations stream from the free mp3quran.net servers and need an internet connection. Your choice is saved to resume your wird.',
    'fr': "Les récitations proviennent des serveurs gratuits mp3quran.net et nécessitent une connexion. Votre choix est enregistré."
  },
  'autoNote': {
    'ar': 'سُجِّل تلقائياً بعد الاستماع',
    'en': 'Auto-logged after listening',
    'fr': "Enregistré après l'écoute"
  },
  'autoLogged': {
    'ar': 'أحسنت! سُجِّل وردك لليوم تلقائياً ✅',
    'en': "Well done! Today's wird was logged automatically ✅",
    'fr': "Bravo ! Votre wird du jour a été enregistré ✅"
  },
};
