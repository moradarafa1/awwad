// عدّاد الذكر (tasbih): a big tap target for the count-based worship habits
// (istighfar, salawat, adhkar, gratitude, dua), where a 1-10 slider is a poor
// fit for "a hundred or more". The count resets each day and is stored under
// its own local key, so nothing about the entry schema, sync, or stats
// changes: the count is MAPPED onto the habit's primary metric when the user
// logs the day (see tasbihToMetric).
//
// Offline, zero cost, no new permission. Haptics only (no audio) so it can be
// used discreetly.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme.dart';

/// Catalog keys whose habit is naturally COUNTED, not rated.
const Set<String> kTasbihHabits = {
  'istighfar',
  'salawat',
  'adhkar',
  'gratitude',
  'dua',
};

bool habitUsesTasbih(String? catalogKey) =>
    catalogKey != null && kTasbihHabits.contains(catalogKey);

/// The daily target used for the ring and for the metric mapping. 100 is the
/// classic istighfar/salawat portion; 33 fits the post-prayer adhkar.
int tasbihTargetFor(String catalogKey) =>
    catalogKey == 'adhkar' || catalogKey == 'gratitude' ? 33 : 100;

/// Maps a raw count onto the primary metric the entry actually stores, so
/// counts need no schema change. Reaching the target is a full 10. The floor
/// is 1, NOT 0: the metric feeds a Slider whose minimum is 1, and a 0 would
/// both break that slider and persist an out-of-domain value. Pure.
int tasbihToMetric(int count, int target) {
  if (count <= 0) return 1;
  if (target <= 0) return 10;
  final v = (count * 10 / target).round();
  return v < 1 ? 1 : (v > 10 ? 10 : v);
}

/// Per-habit, per-day storage. Yesterday's count is never shown as today's.
class TasbihStore {
  TasbihStore._();
  static const _prefix = 'awwad_tasbih_v1_';

  static String _key(String habitId, String dayKey) =>
      '$_prefix${habitId}_$dayKey';

  static Future<int> load(String habitId, String dayKey) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getInt(_key(habitId, dayKey)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> save(String habitId, String dayKey, int count) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_key(habitId, dayKey), count);
      // Keep the store from growing forever: drop this habit's older days.
      final stale = sp
          .getKeys()
          .where((k) => k.startsWith('$_prefix$habitId') && !k.endsWith(dayKey))
          .toList();
      for (final k in stale) {
        await sp.remove(k);
      }
    } catch (_) {}
  }
}

/// Localized labels, kept pure so they are unit-testable.
String tasbihTitle(String locale) => switch (locale) {
      'en' => 'Dhikr counter',
      'fr' => 'Compteur de dhikr',
      _ => 'عدّاد الذكر',
    };

String tasbihHint(String locale) => switch (locale) {
      'en' => 'Tap the circle for each one',
      'fr' => 'Touchez le cercle à chaque fois',
      _ => 'اضغط الدائرة مع كل ذكر',
    };

String tasbihReset(String locale) => switch (locale) {
      'en' => 'Reset',
      'fr' => 'Réinitialiser',
      _ => 'تصفير',
    };

String tasbihDone(String locale) => switch (locale) {
      'en' => 'Portion complete, may it be accepted',
      'fr' => 'Portion accomplie, qu\'elle soit agréée',
      _ => 'تمّت وردك، تقبّل الله',
    };

/// The counter itself. [onChanged] reports every new count so the host screen
/// can map it onto the metric slider.
class TasbihCounter extends StatefulWidget {
  const TasbihCounter({
    super.key,
    required this.habitId,
    required this.dayKey,
    required this.target,
    this.onChanged,
  });

  final String habitId;
  final String dayKey;
  final int target;
  final ValueChanged<int>? onChanged;

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter> {
  int _count = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TasbihCounter old) {
    super.didUpdateWidget(old);
    // The daily-log screen is a preserved stack slot: switching habits (or
    // crossing midnight) rebuilds it in place, so the count MUST reload or
    // the previous habit's number would linger.
    if (old.habitId != widget.habitId || old.dayKey != widget.dayKey) {
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    final c = await TasbihStore.load(widget.habitId, widget.dayKey);
    if (!mounted) return;
    setState(() {
      _count = c;
      _loaded = true;
    });
    // Deliberately NOT calling onChanged here: loading must never overwrite
    // the metric the screen already hydrated from today's saved entry, and a
    // zero count must never be pushed into a slider whose minimum is 1.
    // Only real user taps move the slider.
  }

  Future<void> _bump() async {
    final next = _count + 1;
    setState(() => _count = next);
    // A light tick per count, a heavier one when the portion completes.
    if (next == widget.target) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onChanged?.call(next);
    await TasbihStore.save(widget.habitId, widget.dayKey, next);
  }

  Future<void> _reset() async {
    setState(() => _count = 0);
    widget.onChanged?.call(0);
    await TasbihStore.save(widget.habitId, widget.dayKey, 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox(height: 4);
    final locale = Localizations.localeOf(context).languageCode;
    final done = _count >= widget.target;
    final progress =
        widget.target <= 0 ? 0.0 : (_count / widget.target).clamp(0.0, 1.0);
    final color = done ? AppColors.success : AppColors.accent2;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(tasbihTitle(locale),
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(done ? tasbihDone(locale) : tasbihHint(locale),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 12),
          // Big, forgiving tap target: this is used repeatedly and often
          // without looking at the screen.
          Semantics(
            button: true,
            label: tasbihTitle(locale),
            value: '$_count',
            child: InkWell(
              onTap: _bump,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_count',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppColors.heading)),
                        Text('/ ${widget.target}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _count == 0 ? null : _reset,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(tasbihReset(locale),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Kept for callers that want to serialize a count into a note without a
/// schema change (e.g. the auto-log path). Pure.
String tasbihNote(int count) => jsonEncode({'tasbih': count});
