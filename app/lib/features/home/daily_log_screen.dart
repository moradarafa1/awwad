import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/catalog/badge_catalog.dart';
import '../../core/catalog/default_fields.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/widgets/tasbih_counter.dart';
import '../../core/catalog/habit_content.dart';
import '../../core/catalog/habit_daily_content.dart';
import '../../core/catalog/habit_stages.dart';
import '../../core/catalog/motivation.dart';
import '../../core/connectivity/online.dart';
import '../../core/models.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import '../quran/quran_player_screen.dart';
import '../radio/radio_player_screen.dart';
import 'badge_celebration.dart';
import 'habit_switcher.dart';
import 'home_shell.dart';
import '../auth/auth_screen.dart';
import '../phone/usage_screen.dart';
import '../sos/sos_screen.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';

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
const Map<String, String> _kTriggerQ = {
  'ar': 'ما الذي دفعك إلى التعثر؟ (اختياري، يساعدك على كشف النمط)',
  'en': 'What triggered the slip? (optional, reveals your pattern)',
  'fr': "Qu'est-ce qui a déclenché l'écart ? (facultatif)",
};

const Map<String, Map<String, String>> _kSkip = {
  'btn': {
    'ar': 'يوم سفر أو مرض؟ أعفِ هذا اليوم من السلسلة',
    'en': 'Traveling or sick? Excuse today from the streak',
    'fr': "Voyage ou maladie ? Exempter ce jour de la série",
  },
  'title': {
    'ar': 'إعفاء اليوم',
    'en': 'Excuse today',
    'fr': "Exempter ce jour",
  },
  'body': {
    'ar':
        'اليوم المُعفى لا يكسر سلسلتك ولا يزيدها، ويُعرض بلون مختلف في السجل. استخدمه للسفر والمرض والأعذار الحقيقية فقط.',
    'en':
        'An excused day neither breaks nor extends your streak and shows differently in history. Use it for real excuses only.',
    'fr':
        "Un jour exempté ne casse ni n'allonge votre série. À réserver aux vraies excuses.",
  },
  'cancel': {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler'},
  'ok': {'ar': 'إعفاء اليوم', 'en': 'Excuse it', 'fr': 'Exempter'},
  'remaining': {
    'ar': 'المتبقي لك: {w} هذا الأسبوع · {m} هذا الشهر',
    'en': 'Remaining: {w} this week · {m} this month',
    'fr': 'Restant : {w} cette semaine · {m} ce mois',
  },
  'quotaTitle': {
    'ar': 'انتهت فرص الإعفاء',
    'en': 'No excuse days left',
    'fr': "Plus de jours d'exemption",
  },
  'quotaWeek': {
    'ar':
        'استنفدت فرص الإعفاء لهذا الأسبوع (٢ أسبوعياً). تتجدد فرصك في بداية أسبوعك القادم. الثبات الحقيقي يُبنى بالاستمرار.',
    'en':
        'You have used all your excuse days this week (2 per week). They renew at the start of your next week.',
    'fr':
        "Vous avez épuisé vos exemptions cette semaine (2 par semaine). Elles se renouvellent la semaine prochaine.",
  },
  'quotaMonth': {
    'ar':
        'استنفدت فرص الإعفاء لهذا الشهر (٤ شهرياً). تتجدد فرصك في بداية شهرك القادم. واصل، أنت أقوى مما تظن.',
    'en':
        'You have used all your excuse days this month (4 per month). They renew at the start of your next month.',
    'fr':
        "Vous avez épuisé vos exemptions ce mois (4 par mois). Elles se renouvellent le mois prochain.",
  },
  'quotaOk': {'ar': 'حسناً', 'en': 'OK', 'fr': 'OK'},
};

const Map<String, Map<String, String>> _kRepair = {
  'q': {
    'ar': 'فاتك تسجيل يوم أمس. أنقذ سلسلتك الآن.',
    'en': "You missed logging yesterday. Rescue your streak now.",
    'fr': "Vous n'avez pas enregistré hier. Sauvez votre série.",
  },
  'fix': {'ar': 'استدراك', 'en': 'Fix it', 'fr': 'Corriger'},
  'title': {
    'ar': 'كيف كان يوم أمس؟',
    'en': 'How was yesterday?',
    'fr': "Comment était hier ?",
  },
  'clean': {
    'ar': 'كان يوماً موفقاً بلا تعثر',
    'en': 'A clean day, no slip',
    'fr': 'Une bonne journée, sans écart',
  },
  'slip': {
    'ar': 'حدث تعثر بالأمس',
    'en': 'There was a slip',
    'fr': 'Il y a eu un écart',
  },
  'skip': {
    'ar': 'كان عذراً (سفر أو مرض)، أعفِه',
    'en': 'It was an excuse (travel/sick), exempt it',
    'fr': "C'était une excuse, exempter",
  },
};

const Map<String, Map<String, String>> _kRank = {
  'label': {'ar': 'رتبتك', 'en': 'Your rank', 'fr': 'Votre rang'},
  'toNext': {
    'ar': 'أيام إلى الرتبة التالية',
    'en': 'days to the next rank',
    'fr': 'jours avant le rang suivant',
  },
  'top': {
    'ar': 'أعلى رتبة، ثبّتك الله',
    'en': 'Top rank, keep it up',
    'fr': 'Rang maximal, continuez',
  },
};

// Passive stat chips under the rank line: personal record, money saved so
// far, and the excuse days still available this week.
const Map<String, Map<String, String>> _kChips = {
  'best': {'ar': 'أفضل سلسلة', 'en': 'Best streak', 'fr': 'Meilleure série'},
  'strength': {
    'ar': 'قوة العادة',
    'en': 'Habit strength',
    'fr': "Force de l'habitude"
  },
  'saved': {'ar': 'وفّرت', 'en': 'Saved', 'fr': 'Économisé'},
  'skips': {
    'ar': 'إعفاءات متبقية',
    'en': 'Excuse days left',
    'fr': 'Jours excusés restants',
  },
  'record': {
    'ar': 'رقم قياسي جديد',
    'en': 'New personal record',
    'fr': 'Nouveau record personnel',
  },
  'recordBody': {
    'ar': 'تجاوزت أطول سلسلة لك حتى الآن. واصل، فالثبات هو الطريق.',
    'en': 'You just beat your longest streak. Keep going; consistency is the way.',
    'fr': 'Vous venez de battre votre plus longue série. Continuez, la constance est la voie.',
  },
};

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
  String? _trigger; // slip trigger key (relapse journal)
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
    if (_loadedHabitId == activeId) {
      // The SOS screen can hand back an outcome for the SAME habit, so this
      // has to be honored even when there is nothing to re-hydrate.
      _consumeSosOutcome();
      return;
    }
    // Reset, then load today's entry for the (possibly newly-selected) habit.
    _urge = 5;
    _resistance = 5;
    _didSlip = null;
    _moodEmoji = null;
    _moodLabel = null;
    _trigger = null;
    _noteCtrl.clear();
    _selectedCR.clear();
    _selectedEnv.clear();
    final e = s.entryForToday();
    if (e != null && !e.isSkip) {
      _urge = e.urge.toDouble();
      _resistance = e.resistance.toDouble();
      _didSlip = e.didSlip;
      _moodEmoji = e.moodEmoji;
      _moodLabel = e.moodLabel;
      _trigger = e.trigger;
      _noteCtrl.text = e.note ?? '';
      _selectedCR.addAll(e.competingResponses);
      _selectedEnv.addAll(e.environment);
    }
    _loadedHabitId = activeId;
    _consumeSosOutcome();
  }

  /// Applies (once) an outcome handed over by the SOS screen: a slip
  /// preselects the answer so the user lands directly on the trigger
  /// question while the moment is still fresh.
  void _consumeSosOutcome() {
    final pending = ref.read(sosSlipPendingProvider);
    if (pending == null) return;
    _didSlip = pending;
    // Clear AFTER this frame: writing to a provider during build throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sosSlipPendingProvider.notifier).state = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    // Snapshot the record AND the running streak before saving. Both are
    // needed: a user whose CURRENT run is already their all-time best beats
    // "the record" every single day, so celebrating on longestStreak alone
    // would fire a modal on every save forever.
    final stateBefore = ref.read(appControllerProvider);
    final bestBefore = stateBefore.longestStreak;
    final streakBefore = stateBefore.currentStreak;
    final newBadges = await ref.read(appControllerProvider.notifier).saveEntry(
          urge: _urge.round(),
          resistance: _resistance.round(),
          didSlip: _didSlip ?? false,
          moodEmoji: _moodEmoji,
          moodLabel: _moodLabel,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          trigger: _trigger,
          competingResponses: _selectedCR.toList(),
          environment: _selectedEnv.toList(),
        );
    // Auto-sync: signed-in users should never need a manual "sync now"
    // button - every saved entry is pushed in the background (silent
    // fail-open; offline-first is preserved).
    if (SupabaseService.signedIn) {
      final st = ref.read(appControllerProvider);
      unawaited(SyncService.pushAll(
              habits: st.habits, entries: st.entries, survey: st.survey)
          .catchError((_) {}));
    }
    // Analytics flush after every save (anonymous events allowed; fail-open).
    unawaited(AnalyticsService.instance.flush().catchError((_) {}));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.entrySaved), backgroundColor: AppColors.success),
    );
    final notifOn = ref.read(appControllerProvider).settings.notificationsEnabled;
    final loc = Localizations.localeOf(context).languageCode;
    // Personal record: beating your own longest streak deserves its own
    // moment, independent of the badge thresholds (a user between two badge
    // tiers otherwise gets nothing for weeks).
    final stateAfter = ref.read(appControllerProvider);
    final bestAfter = stateAfter.longestStreak;
    final streakAfter = stateAfter.currentStreak;
    // Fire ONLY when this run overtakes a record set by an EARLIER run.
    if (bestBefore > 0 &&
        streakBefore < bestBefore &&
        streakAfter >= bestBefore &&
        mounted) {
      final title = '🏆 ${_dl(_kChips, 'record', loc)}';
      final body = _dl(_kChips, 'recordBody', loc);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title,
              style: TextStyle(fontSize: 16, color: AppColors.accent3)),
          content: Text('$body\n\n${_dl(_kChips, 'best', loc)}: $bestAfter',
              style: const TextStyle(fontSize: 13.5, height: 1.6)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx).done),
            ),
          ],
        ),
      );
      if (notifOn) {
        // Fixed id from the documented namespace, not a hashCode: badge ids
        // are 2000 + key.hashCode, so a hashed literal could collide.
        await showBadgeNotification(1006, title, body);
      }
    }
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
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AuthScreen(startInSignUp: true)));
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

  String _dl(Map<String, Map<String, String>> m, String k, String locale) =>
      m[k]?[locale] ?? m[k]?['ar'] ?? '';

  /// Personal record + savings + remaining excuse days. Each chip appears
  /// only when it carries real information, so a fresh user sees none.
  Widget _statChips(AppState s, Habit? habit, String locale) {
    final best = s.longestStreak;
    final cost = habit?.costPerDay ?? 0;
    final money = cost > 0 ? cost * s.cleanDays : 0;
    // The chip must match what skipBlockedBy() actually enforces: a skip is
    // refused when EITHER quota is exhausted, so show the binding one.
    final wk = s.weeklySkipUsage;
    final mo = s.monthlySkipUsage;
    final skipsLeft =
        (wk.limit - wk.used) < (mo.limit - mo.used)
            ? wk.limit - wk.used
            : mo.limit - mo.used;

    final strength = s.habitStrength;
    final chips = <Widget>[
      // Strength before the record: it is the honest "how am I doing"
      // number, and it survives the bad day that zeroes the streak.
      if (strength > 0)
        _chip('💪', '${_dl(_kChips, 'strength', locale)}: $strength%',
            AppColors.accent),
      if (best > 0)
        _chip('🏆', '${_dl(_kChips, 'best', locale)}: $best', AppColors.accent3),
      if (money > 0)
        _chip('💰',
            '${_dl(_kChips, 'saved', locale)}: ${money.toStringAsFixed(0)}',
            AppColors.success),
      if (skipsLeft > 0)
        _chip('🧊', '${_dl(_kChips, 'skips', locale)}: $skipsLeft',
            AppColors.muted),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _chip(String emoji, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Text('$emoji $text',
            style: TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _rankLine(int streak, String locale) {
    final r = rankForStreak(streak);
    final nx = nextRank(streak);
    final nextTxt = nx == null
        ? _dl(_kRank, 'top', locale)
        : '${nx.minStreak - streak} ${_dl(_kRank, 'toNext', locale)} ${nx.emoji}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent2.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent2.withValues(alpha: 0.35)),
      ),
      // Both texts are flexible: the rank name and the "days to next rank"
      // hint are long in Arabic and a non-flex trailing Text overflowed the
      // row on narrow screens / large font scales.
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('${r.emoji} ${_dl(_kRank, 'label', locale)}: ${r.n(locale)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: AppColors.accent2)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(nextTxt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _yesterdayBanner(String locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent3.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent3.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: AppColors.accent3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_dl(_kRepair, 'q', locale),
                style: TextStyle(
                    fontSize: 12, color: AppColors.text, height: 1.5)),
          ),
          TextButton(
            onPressed: () => _repairSheet(locale),
            child: Text(_dl(_kRepair, 'fix', locale),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _repairSheet(String locale) {
    final ctrl = ref.read(appControllerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_dl(_kRepair, 'title', locale),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading)),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await ctrl.backfillYesterday(didSlip: false);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(_dl(_kRepair, 'clean', locale)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ctrl.backfillYesterday(didSlip: true);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(_dl(_kRepair, 'slip', locale)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (await _skipQuotaBlocked(locale)) return;
                  await ctrl.skipDay(dayKey(
                      DateTime.now().subtract(const Duration(days: 1))));
                },
                child: Text(_dl(_kRepair, 'skip', locale)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Enforces the per-habit excused-day quota (2/week, 4/month): when the
  /// quota is exhausted, shows the explanatory dialog and returns true.
  Future<bool> _skipQuotaBlocked(String locale) async {
    final blocked = ref.read(appControllerProvider).skipBlockedBy();
    if (blocked == null) return false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_dl(_kSkip, 'quotaTitle', locale),
            style: TextStyle(color: AppColors.heading)),
        content: Text(
            _dl(_kSkip, blocked == 'week' ? 'quotaWeek' : 'quotaMonth',
                locale),
            style: TextStyle(color: AppColors.text, height: 1.6)),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_dl(_kSkip, 'quotaOk', locale))),
        ],
      ),
    );
    return true;
  }

  Future<void> _confirmSkipToday(String locale) async {
    if (await _skipQuotaBlocked(locale)) return;
    if (!mounted) return;

    final w = ref.read(appControllerProvider).weeklySkipUsage;
    final m = ref.read(appControllerProvider).monthlySkipUsage;
    final remainInfo = _dl(_kSkip, 'remaining', locale)
        .replaceFirst('{w}', '${w.limit - w.used}')
        .replaceFirst('{m}', '${m.limit - m.used}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_dl(_kSkip, 'title', locale),
            style: TextStyle(color: AppColors.heading)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dl(_kSkip, 'body', locale),
                style: TextStyle(color: AppColors.text, height: 1.6)),
            const SizedBox(height: 10),
            Text(remainInfo,
                style: TextStyle(
                    color: AppColors.accent2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_dl(_kSkip, 'cancel', locale))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_dl(_kSkip, 'ok', locale))),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(appControllerProvider.notifier)
          .skipDay(dayKey(DateTime.now()));
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
    final metrics = resolveMetrics(
      catalogKey: habit?.catalogKey,
      track: habit?.track ?? 'break',
      customPrimary: habit?.customMetricPrimary,
      customSecondary: habit?.customMetricSecondary,
      generatedOverride: kHabitMetricsOverrides[habit?.catalogKey],
    );
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
          // Rank chip (levels): streak-based, consistent with the shields.
          const SizedBox(height: 10),
          _rankLine(s.currentStreak, locale),
          // Personal record + savings + remaining excuse days: three passive
          // chips that answer "how am I really doing" at a glance.
          _statChips(s, habit, locale),
          // Streak repair: yesterday has no entry -> offer quick backfill or
          // an excused day, so one forgotten evening does not kill the streak.
          // Weekly habits are exempt: yesterday is a transparent off-day for
          // them, so a "you missed yesterday" banner would be nonsense.
          if (habit != null &&
              weeklyWeekdayFor(habit.catalogKey) == null &&
              s.entryForYesterday() == null &&
              DateTime.now().difference(habit.createdAt).inDays >= 1) ...[
            const SizedBox(height: 10),
            _yesterdayBanner(locale),
          ],
          // Urge-surfing SOS entry: break habits fight cravings in the moment.
          if (isBreak) ...[
            const SizedBox(height: 14),
            const SosEntryButton(),
          ],
          // Phone-usage monitor entry for the phone-addiction habit.
          if (habit?.catalogKey == 'phone_addiction') ...[
            const SizedBox(height: 10),
            const UsageEntryButton(),
          ],
          const SizedBox(height: 14),
          // Daily rotating line: deterministic per day, offline, and the
          // faith pool joins only when religious content is on. Replaces the
          // banner that showed the same two sentences every single day.
          MotivationBanner(
            emoji: '🤍',
            title: dailyLineFor(dayKey(DateTime.now()),
                    showReligious: s.settings.showReligiousContent)
                .t(locale),
            subtitle: s.settings.showReligiousContent && s.currentStreak > 0
                ? l10n.motivationPatience
                : null,
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
          // Counted worship (istighfar, salawat, adhkar, gratitude, dua): a
          // tap counter fits «مئة أو أكثر» far better than a 1-10 slider. The
          // count DRIVES the primary metric, so nothing downstream changes.
          if (habit != null && habitUsesTasbih(habit.catalogKey))
            TasbihCounter(
              // Keyed so a habit switch or a midnight rollover rebuilds the
              // state instead of showing the previous habit's count.
              key: ValueKey('tasbih-${habit.id}-${dayKey(DateTime.now())}'),
              habitId: habit.id,
              dayKey: dayKey(DateTime.now()),
              target: tasbihTargetFor(habit.catalogKey!),
              onChanged: (count) {
                final v = tasbihToMetric(
                    count, tasbihTargetFor(habit.catalogKey!));
                if (v != _urge.round()) setState(() => _urge = v.toDouble());
              },
            ),
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
                // Relapse journal: capture WHAT triggered the slip so the
                // stats screen can reveal the user's recurring patterns.
                if (_didSlip == true) ...[
                  const SizedBox(height: 12),
                  Text(_kTriggerQ[locale] ?? _kTriggerQ['ar']!,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in kSlipTriggers)
                        ChoiceChipTile(
                          label: '${t.emoji} ${t.l(locale)}',
                          selected: _trigger == t.key,
                          color: AppColors.accent3,
                          onTap: () => setState(() =>
                              _trigger = _trigger == t.key ? null : t.key),
                        ),
                    ],
                  ),
                ],
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
          // Excused day (travel/sickness): transparent to the streak.
          if (s.entryForToday() == null)
            TextButton(
              onPressed: () => _confirmSkipToday(locale),
              child: Text(_kSkip['btn']![locale] ?? _kSkip['btn']!['ar']!,
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
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

    // The hadith wird opens the live Sunnah/hadith radio player.
    if (key == 'hadith_wird') {
      final w = const {
        'ar': {
          'title': 'ورد الاستماع للسنة',
          'body': 'استمع مباشرة لأحاديث البخاري ومسلم ورياض الصالحين. يُسجَّل وردك تلقائياً بعد الاستماع.',
          'button': 'افتح الإذاعة'
        },
        'en': {
          'title': 'Sunnah listening wird',
          'body': 'Listen live to hadith from Bukhari, Muslim and Riyad as-Salihin. Auto-logged after listening.',
          'button': 'Open the radio'
        },
        'fr': {
          'title': "Wird d'écoute de la Sunna",
          'body': 'Écoutez en direct les hadiths de Bukhari, Muslim et Riyad as-Salihin.',
          'button': 'Ouvrir la radio'
        },
      }[locale] ?? const {'title': '', 'body': '', 'button': ''};
      return _solutionCard(
          title: w['title']!,
          body: w['body']!,
          buttonLabel: w['button']!,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RadioPlayerScreen(
                  category: 'hadith', habitId: habit?.id))));
    }

    // The listening wird opens the in-app Quran audio player instead of a link.
    if (key == 'listening_wird') {
      final w = const {
        'ar': {
          'title': 'ورد الاستماع',
          'body': 'استمع إلى القرآن بصوت قارئك المفضّل من ٥٠ قارئاً.',
          'button': 'افتح المشغّل'
        },
        'en': {
          'title': 'Listening wird',
          'body': 'Listen to the Quran in your favourite voice from 50 reciters.',
          'button': 'Open the player'
        },
        'fr': {
          'title': "Wird d'écoute",
          'body': 'Écoutez le Coran par votre récitateur préféré parmi 50.',
          'button': 'Ouvrir le lecteur'
        },
      }[locale] ?? const {'title': '', 'body': '', 'button': ''};
      return _solutionCard(
          title: w['title']!,
          body: w['body']!,
          buttonLabel: w['button']!,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => QuranPlayerScreen(habitId: habit?.id))));
    }

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
            // Expanded (not Text + Spacer): the label can be a long seeded
            // metric name or a label the user typed for a custom habit, and a
            // non-flex Text would hard-overflow the row.
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 8),
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
            Flexible(
              child: Text(low,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(high,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }
}
