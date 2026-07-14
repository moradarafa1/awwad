import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/content/dhikr.dart';
import '../../core/notifications/notifications.dart';
import '../../core/notifications/notif_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/ambient_background.dart';
import 'daily_log_screen.dart';
import 'stats_screen.dart';
import 'badges_screen.dart';
import 'settings_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../sos/sos_screen.dart';

/// Selected bottom-nav tab index, shared so any screen can switch tabs
/// (e.g. the daily log jumps to Stats after saving).
final homeTabProvider = StateProvider<int>((ref) => 0);


class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  bool _nudged = false;

  // Nav index 3 is the «هُدنة» ACTION (opens the truce flow), not a screen,
  // so its stack slot is an unused placeholder that is never displayed.
  static const _screens = [
    DailyLogScreen(),
    StatsScreen(), // history now lives inside Stats as an internal tab
    BadgesScreen(),
    SizedBox.shrink(), // index 3 = هُدنة action (intercepted, never shown)
    PomodoroScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeNudge();
      _setupNotifications();
      _autoSync();
    });
  }

  // Auto-sync on app open: replaces the removed manual "sync now" button.
  // Push-only upserts (idempotent), silent fail-open, never blocks startup.
  Future<void> _autoSync() async {
    if (!SupabaseService.signedIn) return;
    try {
      final s = ref.read(appControllerProvider);
      await SyncService.pushAll(
          habits: s.habits, entries: s.entries, survey: s.survey);
    } catch (_) {
      // Offline or transient failure: the next open / save retries.
    }
  }

  // Ask for notification consent once (with an in-app rationale), then schedule
  // the daily habit reminder + the daily Ibrahimic-prayer dhikr. All no-ops on
  // web; gated by the user's toggles.
  Future<void> _setupNotifications() async {
    if (!mounted) return;
    final ctrl = ref.read(appControllerProvider.notifier);
    var s = ref.read(appControllerProvider);
    final loc = Localizations.localeOf(context).languageCode;

    // First open: request the OS notification permission directly (no extra
    // in-app dialog). Covers users who skipped the first-open auth screen.
    if (!s.settings.notifPromptShown) {
      await ensureNotificationPermission();
      await ctrl.markNotifPromptShown();
      if (!mounted) return;
      s = ref.read(appControllerProvider);
    }

    if (!mounted) return;
    await applyNotificationSchedule(
      enabled: s.settings.notificationsEnabled,
      habitReminders: habitRemindersFor(s.habits, loc),
      dhikrEnabled: s.settings.dhikrEnabled,
      showReligious: s.settings.showReligiousContent,
      dhikrHour: s.settings.dhikrHour,
      dhikrTitle: kDhikrTitle[loc] ?? kDhikrTitle['ar']!,
    );
  }


  // Respectful retention pop-up: at most once per app open, only when there is
  // a streak at risk and today is not yet logged.
  void _maybeNudge() {
    if (_nudged || !mounted) return;
    final s = ref.read(appControllerProvider);
    if (s.entryForToday() != null) return;
    if (s.currentStreak <= 0) return;
    _nudged = true;
    final l10n = AppLocalizations.of(context);
    AnalyticsService.instance.track('popup_shown', {'type': 'streak_risk'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        duration: const Duration(seconds: 6),
        content: Text(
          '🔥 ${l10n.statsCurrentStreak}: ${s.currentStreak} · ${l10n.saveEntry}',
          style: TextStyle(color: AppColors.text),
        ),
        action: SnackBarAction(
          label: l10n.navToday,
          textColor: AppColors.accent,
          onPressed: () {
            AnalyticsService.instance
                .track('popup_cta_clicked', {'type': 'streak_risk'});
            ref.read(homeTabProvider.notifier).state = 0;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = ref.watch(homeTabProvider);
    final pomodoroLabel = const {
      'ar': 'بومودورو',
      'en': 'Pomodoro',
      'fr': 'Pomodoro',
    }[Localizations.localeOf(context).languageCode] ?? 'Pomodoro';
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(child: IndexedStack(index: index, children: _screens)),
      ),
      backgroundColor: AppColors.bg,
      // Floating "liquid glass" dock: blurred, translucent, luminous hairline.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface
                    .withValues(alpha: AppColors.isDark ? 0.58 : 0.72),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.hairline),
              ),
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: _buildNavBar(l10n, index, pomodoroLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _truceLabel() {
    final loc = Localizations.localeOf(context).languageCode;
    return const {'ar': 'هُدنة', 'en': 'Truce', 'fr': 'Trêve'}[loc] ?? 'Truce';
  }

  // «هُدنة» flow: pick which break habit needs help right now, then open the
  // SOS screen tailored to that habit. If there is exactly one break habit,
  // skip the picker. If none, gently point to adding one.
  Future<void> _openTruce() async {
    final s = ref.read(appControllerProvider);
    final loc = Localizations.localeOf(context).languageCode;
    final breakHabits =
        s.habits.where((h) => h.track == 'break').toList();

    if (breakHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(const {
                'ar': 'أضف عادة تريد الإقلاع عنها أولاً لتستفيد من الهُدنة.',
                'en': 'Add a break habit first to use Truce.',
                'fr': "Ajoutez d'abord une habitude à arrêter pour utiliser la Trêve.",
              }[loc] ??
              'Add a break habit first.')));
      return;
    }

    String targetId = breakHabits.first.id;
    if (breakHabits.length > 1) {
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Text(
                    const {
                          'ar': 'أي عادة تحتاج هُدنة الآن؟',
                          'en': 'Which habit needs a truce now?',
                          'fr': 'Quelle habitude a besoin d\'une trêve ?',
                        }[loc] ??
                        'Which habit?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.heading)),
              ),
              for (final h in breakHabits)
                ListTile(
                  leading: Icon(Icons.health_and_safety_outlined,
                      color: AppColors.danger),
                  title: Text(h.title,
                      style: TextStyle(color: AppColors.text)),
                  onTap: () => Navigator.pop(ctx, h.id),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
      if (picked == null) return; // dismissed
      targetId = picked;
    }

    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SosScreen(habitId: targetId)));
  }

  Widget _buildNavBar(
      AppLocalizations l10n, int index, String pomodoroLabel) {
    return NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          height: 66,
          indicatorColor: AppColors.accent.withValues(alpha: 0.22),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.heading
                  : AppColors.muted)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          // Index 3 = «هُدنة»: an action, not a tab. Intercept it (open the
          // truce flow) and leave the selected tab unchanged.
          onDestinationSelected: (i) {
            if (i == 3) {
              _openTruce();
              return;
            }
            ref.read(homeTabProvider.notifier).state = i;
          },
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l10n.navToday),
            NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: l10n.navStats),
            NavigationDestination(
                icon: const Icon(Icons.emoji_events_outlined),
                selectedIcon: const Icon(Icons.emoji_events),
                label: l10n.navBadges),
            NavigationDestination(
                icon: Icon(Icons.health_and_safety_outlined,
                    color: AppColors.danger),
                selectedIcon: Icon(Icons.health_and_safety,
                    color: AppColors.danger),
                label: _truceLabel()),
            NavigationDestination(
                icon: const Icon(Icons.timer_outlined),
                selectedIcon: const Icon(Icons.timer),
                label: pomodoroLabel),
            NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings),
          ],
        ));
  }
}
