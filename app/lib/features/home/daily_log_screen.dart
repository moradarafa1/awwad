import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/catalog/badge_catalog.dart';
import '../../core/catalog/default_fields.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/habit_content.dart';
import '../../core/catalog/habit_daily_content.dart';
import '../../core/catalog/habit_stages.dart';
import '../../core/connectivity/online.dart';
import '../../core/models.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import 'badge_celebration.dart';
import 'habit_switcher.dart';
import 'home_shell.dart';
import '../auth/auth_screen.dart';
import '../../core/cloud/supabase_service.dart';

// "Stage X of 4" prefix for the progressive stage card (see habit_stages.dart).
const Map<String, String> _kStageOf = {
  'ar': 'المرحلة {i} من ٤',
  'en': 'Stage {i} of 4',
  'fr': 'Étape {i} sur 4',
};
const Map<String, String> _kStageNext = {
  'ar': 'المرحلة التالية عند اليوم {d} من التتابع',
  'en': 'Next stage at streak day {d}',
  'fr': "Prochaine étape au jour {d} de la série",
};
// Group titles for BUILD habits (break habits use the seeded HRT group titles).
const Map<String, Map<String, String>> _kBuildGroupTitles = {
  'competing_response': {
    'ar': 'خطوات اليوم',
    'en': "Today's steps",
    'fr': 'Étapes du jour'
  },
  'environment_action': {
    'ar': 'تهيئة البيئة',
    'en': 'Set up your environment',
    'fr': 'Préparez votre environnement'
  },
};

const List<(String, Map<String, String>)> _moods = [
  ('😊', {'ar': 'مرتاح', 'en': 'Content', 'fr': 'Serein'}),
  ('😰', {'ar': 'قلق', 'en': 'Anxious', 'fr': 'Anxieux'}),
  ('😤', {'ar': 'متوتر', 'en': 'Stressed', 'fr': 'Stressé'}),
  ('😑', {'ar': 'ضَجِر', 'en': 'Bored', 'fr': 'Ennuyé'}),
  ('😴', {'ar': 'مُتعَب', 'en': 'Tired', 'fr': 'Fatigué'}),
  ('🔥', {'ar': 'نشيط', 'en': 'Energetic', 'fr': 'Énergique'}),
  ('😢', {'ar': 'حزين', 'en': 'Sad', 'fr': 'Triste'}),
  ('😶', {'ar': 'محايد', 'en': 'Neutral', 'fr': 'Neutre'}),
];

const Map<String, Map<String, String>> _accountStrings = {
  'ar': {
    'title': 'احفظ تقدّمك',
    'body':
        'أنشئ حسابًا مجانيًا لمزامنة بياناتك وحفظها على جميع أجهزتك حتى لا تفقدها.',
    'later': 'لاحقًا',
    'signup': 'إنشاء حساب',
  },
  'en': {
    'title': 'Save your progress',
    'body':
        'Create a free account to sync and back up your data across all your devices.',
    'later': 'Later',
    'signup': 'Create account',
  },
  'fr': {
    'title': 'Sauvegardez votre progression',
    'body':
        'Créez un compte gratuit pour synchroniser et sauvegarder vos données sur tous vos appareils.',
    'later': 'Plus tard',
    'signup': 'Créer un compte',
  },
};

// Trilingual congratulation copy for the badge/shield notification.
const Map<String, Map<String, String>> _kBadgeCongrats = {
  'ar': {
    'title': 'تهانينا! درعٌ جديد 🛡️',
    'body': 'حصلت على درع «{name}». ثباتك يستحقّ التقدير، فواصِل على البركة.'
  },
  'en': {
    'title': 'Congrats! New shield 🛡️',
    'body': 'You earned the "{name}" shield. Your consistency deserves it, keep going.'
  },
  'fr': {
    'title': 'Bravo ! Nouveau bouclier 🛡️',
    'body': 'Vous avez obtenu le bouclier « {name} ». Votre régularité le mérite, continuez.'
  },
};

// "Did you do the habit today?" for build habits (break habits ask "did you slip?").
const Map<String, String> _kDoneQuestion = {
  'ar': 'هل أدّيت العادة اليوم؟',
  'en': 'Did you do the habit today?',
  'fr': "Avez-vous fait l'habitude aujourd'hui ?",
};

// Suggested scholar-video card. Shown ONLY when online AND the habit has a
// curated, duration-verified (< 30 min) video in kHabitVideos.
const Map<String, Map<String, String>> _kVideoCard = {
  'ar': {
    'title': 'حلٌّ مقترح: فيديو ذو صلة',
    'body': 'مقطع قصير موثوق (أقل من ٣٠ دقيقة) له صلة مباشرة بهذه العادة، يعينك على فهمها وتجاوزها:',
    'button': 'شاهد الفيديو'
  },
  'en': {
    'title': 'Suggested help: a relevant video',
    'body': 'A short, trusted clip (under 30 minutes) directly related to this habit, to help you understand and overcome it:',
    'button': 'Watch the video'
  },
  'fr': {
    'title': 'Aide suggérée : une vidéo pertinente',
    'body': 'Une courte vidéo de confiance (moins de 30 minutes) directement liée à cette habitude :',
    'button': 'Regarder la vidéo'
  },
};

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});
  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  double _urge = 5, _resistance = 5;
  bool? _didSlip;
  String? _moodEmoji, _moodLabel;
  final _noteCtrl = TextEditingController();
  final Set<String> _selectedCR = {};
  final Set<String> _selectedEnv = {};
  String? _loadedHabitId; // re-hydrate the form when the active habit changes

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromToday(AppState s) {
    final activeId = s.activeHabitId;
    if (_loadedHabitId == activeId) return;
    // Reset, then load today's entry for the (possibly newly-selected) habit.
    _urge = 5;
    _resistance = 5;
    _didSlip = null;
    _moodEmoji = null;
    _moodLabel = null;
    _noteCtrl.clear();
    _selectedCR.clear();
    _selectedEnv.clear();
    final e = s.entryForToday();
    if (e != null) {
      _urge = e.urge.toDouble();
      _resistance = e.resistance.toDouble();
      _didSlip = e.didSlip;
      _moodEmoji = e.moodEmoji;
      _moodLabel = e.moodLabel;
      _noteCtrl.text = e.note ?? '';
      _selectedCR.addAll(e.competingResponses);
      _selectedEnv.addAll(e.environment);
    }
    _loadedHabitId = activeId;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final newBadges = await ref.read(appControllerProvider.notifier).saveEntry(
          urge: _urge.round(),
          resistance: _resistance.round(),
          didSlip: _didSlip ?? false,
          moodEmoji: _moodEmoji,
          moodLabel: _moodLabel,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          competingResponses: _selectedCR.toList(),
          environment: _selectedEnv.toList(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.entrySaved), backgroundColor: AppColors.success),
    );
    final notifOn = ref.read(appControllerProvider).settings.notificationsEnabled;
    final loc = Localizations.localeOf(context).languageCode;
    for (final b in newBadges) {
      final def = badgeByKey(b.badgeKey);
      if (def != null && mounted) {
        await showBadgeCelebration(context, def);
        await ref
            .read(appControllerProvider.notifier)
            .markBadgeCelebrated(b.badgeKey);
        // Also drop a congratulation into the notification tray.
        if (notifOn) {
          final cg = _kBadgeCongrats[loc] ?? _kBadgeCongrats['ar']!;
          await showBadgeNotification(def.key.hashCode,
              cg['title']!, cg['body']!.replaceFirst('{name}', def.t(loc)));
        }
      }
    }
    // After the first ever log, suggest creating an account (sync/back up).
    // Shown once per user (firstLogPromptShown), then never again.
    if (!ref.read(appControllerProvider).settings.firstLogPromptShown) {
      await _maybeSuggestAccount();
    }
    if (mounted) ref.read(homeTabProvider.notifier).state = 1;
  }

  Future<void> _maybeSuggestAccount() async {
    final ctrl = ref.read(appControllerProvider.notifier);
    await ctrl.markFirstLogPromptShown(); // only ever prompt once
    if (!SupabaseService.configured || SupabaseService.signedIn) return;
    if (!mounted) return;
    final s = _accountStrings[Localizations.localeOf(context).languageCode] ??
        _accountStrings['en']!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:
            Text(s['title']!, style: TextStyle(color: AppColors.heading)),
        content: Text(s['body']!, style: TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s['later']!)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s['signup']!)),
        ],
      ),
    );
    if (go == true) {
      AnalyticsService.instance.track('account_prompt_accepted', {});
      await cancelReengageNudge();
      if (mounted) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AuthScreen()));
      }
    } else {
      AnalyticsService.instance.track('account_prompt_declined', {});
      // Gently re-engage in 3 days with a sign-up nudge (mobile; no-op on web).
      if (ref.read(appControllerProvider).settings.notificationsEnabled) {
        await scheduleReengageNudge(
            const Duration(days: 3), s['title']!, s['body']!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    _hydrateFromToday(s);
    final habit = s.habit;
    final isBreak = habit?.track == 'break';
    // The two daily sliders are habit-aware: break = urge/resistance, build =
    // progress/quality, prayer = delay/early+sunnah (see metricsForHabit).
    // Generated per-habit overrides (habit_daily_content) beat both.
    final metrics = kHabitMetricsOverrides[habit?.catalogKey] ??
        metricsForHabit(habit?.catalogKey, habit?.track ?? 'break');
    // Per-habit tailored checklists (fall back to the generic seeded fields).
    final crLabels = _labelsFor(habit?.catalogKey, 'competing_response', s, locale);
    final envLabels = _labelsFor(habit?.catalogKey, 'environment_action', s, locale);
    // Hide the suggested-solutions / video card when the device is offline.
    final online =
        ref.watch(onlineProvider).maybeWhen(data: (v) => v, orElse: () => true);
    // The "did you do it / slip" question is track-aware: a break habit asks
    // "did you slip?" (No = good), a build habit asks "did you do it?" (Yes =
    // good). didSlip == false is always the GOOD outcome (clean / done).
    // A generated per-habit wording (kHabitQuestions) beats the generic one.
    // NOTE for overrides: break-style questions are phrased so that "yes" is
    // the BAD outcome, matching the isBreak chip mapping below.
    final qOverride = kHabitQuestions[habit?.catalogKey];
    final doneQuestion = qOverride != null
        ? (qOverride[locale] ?? qOverride['ar']!)
        : (isBreak
            ? l10n.didSlipQuestion
            : (_kDoneQuestion[locale] ?? _kDoneQuestion['ar']!));
    final goodLabel = isBreak ? l10n.no : l10n.yes; // green chip, didSlip=false
    final badLabel = isBreak ? l10n.yes : l10n.no; // red chip, didSlip=true

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header
          Text(habit?.title ?? l10n.appName,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.heading)),
          const SizedBox(height: 2),
          Text(l10n.slogan,
              style: TextStyle(color: AppColors.accent2, fontSize: 12)),
          const SizedBox(height: 12),
          // switch between habits / add a new one
          const HabitSwitcher(),
          const SizedBox(height: 14),
          // stats row
          Row(
            children: [
              Expanded(
                  child: StatTile(
                      value: '${s.daysLogged}',
                      label: l10n.statsDaysLogged)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.cleanDays}',
                      label: l10n.statsCleanDays,
                      color: AppColors.accent2)),
              const SizedBox(width: 10),
              Expanded(
                  child: StatTile(
                      value: '${s.currentStreak}',
                      label: l10n.statsCurrentStreak,
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 14),
          if (s.settings.showReligiousContent)
            MotivationBanner(
              emoji: '🤍',
              title: l10n.motivationIntention,
              subtitle: s.currentStreak > 0 ? l10n.motivationPatience : null,
            ),
          const SizedBox(height: 12),
          // Progressive stage card: the recovery / commitment journey evolves
          // with the streak (thresholds aligned with the 30/60/90 shields).
          _stageCard(s, habit, locale),
          const SizedBox(height: 16),
          Text(l10n.todayTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          // primary slider (urge / progress / prayer-delay ...)
          SectionCard(
            child: _slider(
              label: metrics.primary.l(locale),
              value: _urge,
              color: AppColors.accent3,
              low: metrics.primary.lo(locale),
              high: metrics.primary.hi(locale),
              onChanged: (v) => setState(() => _urge = v),
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: _slider(
              label: metrics.secondary.l(locale),
              value: _resistance,
              color: AppColors.accent2,
              low: metrics.secondary.lo(locale),
              high: metrics.secondary.hi(locale),
              onChanged: (v) => setState(() => _resistance = v),
            ),
          ),
          const SizedBox(height: 10),
          // did slip
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doneQuestion,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChipTile(
                        label: goodLabel,
                        selected: _didSlip == false,
                        color: AppColors.success,
                        onTap: () => setState(() => _didSlip = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChipTile(
                        label: badLabel,
                        selected: _didSlip == true,
                        color: AppColors.danger,
                        onTap: () => setState(() => _didSlip = true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // mood
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.moodLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _moods.map((m) {
                    final label = m.$2[locale] ?? m.$2['ar']!;
                    final sel = _moodEmoji == m.$1;
                    return InkWell(
                      onTap: () => setState(() {
                        _moodEmoji = m.$1;
                        _moodLabel = label;
                      }),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel ? AppColors.accent : AppColors.border),
                        ),
                        child: Text('${m.$1} $label',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Checklists for BOTH tracks. Their order follows the current stage:
          // from stage 3 (environment control / consolidation) the environment
          // list leads; before that the competing/steps list leads.
          ...(stageIndexForStreak(habit?.track ?? 'break', s.currentStreak) >= 3
              ? [
                  _checklistSection('environment_action', envLabels,
                      _selectedEnv, locale, isBreak),
                  const SizedBox(height: 10),
                  _checklistSection('competing_response', crLabels,
                      _selectedCR, locale, isBreak),
                  const SizedBox(height: 10),
                ]
              : [
                  _checklistSection('competing_response', crLabels,
                      _selectedCR, locale, isBreak),
                  const SizedBox(height: 10),
                  _checklistSection('environment_action', envLabels,
                      _selectedEnv, locale, isBreak),
                  const SizedBox(height: 10),
                ]),
          _resourceCard(habit, locale, online),
          // note
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.noteLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: l10n.noteHint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _didSlip == null ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.saveEntry),
          ),
          if (s.entryForToday() != null) ...[
            const SizedBox(height: 8),
            Text(l10n.alreadyLoggedToday,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  // The progressive recovery/commitment stage card. Content and emphasis
  // evolve with the streak (stage thresholds align with the 30/60/90 shields):
  // stage name + coaching focus + 3 stage tips + progress to the next stage.
  Widget _stageCard(AppState s, Habit? habit, String locale) {
    if (habit == null) return const SizedBox.shrink();
    final track = habit.track;
    final streak = s.currentStreak;
    final stage = stageForStreak(track, streak);
    final idx = stageIndexForStreak(track, streak);
    final nextAt = nextStageAt(track, streak);
    final stageOf = (_kStageOf[locale] ?? _kStageOf['ar']!)
        .replaceFirst('{i}', '$idx');
    // Progress within the current stage toward the next one.
    double? progress;
    String? nextLabel;
    if (nextAt != null) {
      final span = nextAt - stage.minDays;
      progress = span <= 0 ? null : ((streak - stage.minDays) / span).clamp(0.0, 1.0);
      nextLabel = (_kStageNext[locale] ?? _kStageNext['ar']!)
          .replaceFirst('{d}', '$nextAt');
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0x1F4F8EF7), Color(0x122DD4BF)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x394F8EF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text('$idx',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.accent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stageOf,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                    Text(stage.n(locale),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.heading,
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(stage.f(locale),
              style: TextStyle(
                  color: AppColors.text, fontSize: 12.5, height: 1.6)),
          const SizedBox(height: 8),
          ...stage.t(locale).map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            color: AppColors.accent2,
                            fontWeight: FontWeight.w900)),
                    Expanded(
                      child: Text(tip,
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.55)),
                    ),
                  ],
                ),
              )),
          if (progress != null && nextLabel != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.accent2),
              ),
            ),
            const SizedBox(height: 6),
            Text(nextLabel,
                style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  // Curated help for habits that ship a resource (e.g. the secret-habit track
  // recommends the واعي YouTube channel). Hidden for habits with no resource.
  Widget _resourceCard(Habit? habit, String locale, bool online) {
    // The suggested-solutions / video card needs the internet, so hide it when
    // the device is offline.
    if (!online) return const SizedBox.shrink();
    final key = habit?.catalogKey;
    if (key == null) return const SizedBox.shrink();

    // A curated channel (the secret-habit واعي recommendation) takes precedence.
    final res = catalogByKey(key)?.resource;
    if (res != null) {
      final openLabel = const {
        'ar': 'افتح القناة (واعي)',
        'en': 'Open the channel',
        'fr': 'Ouvrir la chaîne',
      }[locale] ?? 'Open the channel';
      return _solutionCard(
          title: res.t(locale),
          body: res.b(locale),
          buttonLabel: openLabel,
          onTap: () => _openUrl(res.url));
    }

    // Otherwise: ONLY a curated + verified scholar video (< 30 min) for THIS
    // habit. No verified video for the habit => no card at all (owner rule).
    final videos = kHabitVideos[key];
    if (videos == null || videos.isEmpty) return const SizedBox.shrink();
    final v = _kVideoCard[locale] ?? _kVideoCard['ar']!;
    final first = videos.first;
    final mins = const {
      'ar': '{t} ({m} دقيقة) - {s}',
      'en': '{t} ({m} min) - {s}',
      'fr': '{t} ({m} min) - {s}',
    }[locale]!
        .replaceFirst('{t}', first.title)
        .replaceFirst('{m}', '${first.minutes}')
        .replaceFirst('{s}', first.scholar);
    return _solutionCard(
        title: v['title']!,
        body: '${v['body']!}\n$mins',
        buttonLabel: v['button']!,
        onTap: () => _openUrl(first.url));
  }

  Widget _solutionCard({
    required String title,
    required String body,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0x222DD4BF), Color(0x11F59E0B)]),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.accent2.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.heading)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12, height: 1.6)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent2,
                  foregroundColor: Colors.black),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Tailored per-habit checklist labels, or the generic seeded fields as fallback.
  List<String> _labelsFor(
      String? key, String group, AppState s, String locale) {
    final tailored = habitChecklistLabels(key, group, locale);
    if (tailored.isNotEmpty) return tailored;
    final extra = extraChecklistLabels(key, group, locale);
    if (extra.isNotEmpty) return extra;
    // The generic seeded fields are HRT/break-oriented: they are a sensible
    // fallback for break habits only. Build habits without tailored content
    // simply show no checklist (empty => section hidden).
    final isBreak = (ref.read(appControllerProvider).habit?.track ?? 'break') ==
        'break';
    if (!isBreak) return const [];
    return s.visibleFields(group).map((f) => f.label).toList();
  }

  Widget _checklistSection(String group, List<String> labels,
      Set<String> selected, String locale, bool isBreak) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final title = isBreak
        ? groupTitle(group, locale)
        : (_kBuildGroupTitles[group]?[locale] ??
            _kBuildGroupTitles[group]?['ar'] ??
            groupTitle(group, locale));
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          ...labels.map((label) {
            final on = selected.contains(label);
            return InkWell(
              onTap: () => setState(() {
                if (on) {
                  selected.remove(label);
                } else {
                  selected.add(label);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(on ? Icons.check_box : Icons.check_box_outline_blank,
                        color: on ? AppColors.success : AppColors.muted,
                        size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 13,
                              color: on ? AppColors.text : AppColors.muted)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required Color color,
    required String low,
    required String high,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Text('${value.round()}',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(low, style: TextStyle(color: AppColors.muted, fontSize: 11)),
            Text(high, style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
