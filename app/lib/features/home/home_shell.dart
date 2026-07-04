import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/content/dhikr.dart';
import '../../core/notifications/notifications.dart';
import '../../core/notifications/notif_scheduler.dart';
import '../../core/state/app_state.dart';
import 'daily_log_screen.dart';
import 'stats_screen.dart';
import 'badges_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../pomodoro/pomodoro_screen.dart';

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

  static const _screens = [
    DailyLogScreen(),
    StatsScreen(),
    BadgesScreen(),
    HistoryScreen(),
    PomodoroScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeNudge();
      _setupNotifications();
    });
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
          style: const TextStyle(color: AppColors.text),
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
      body: SafeArea(child: IndexedStack(index: index, children: _screens)),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(homeTabProvider.notifier).state = i,
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
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: l10n.navHistory),
            NavigationDestination(
                icon: const Icon(Icons.timer_outlined),
                selectedIcon: const Icon(Icons.timer),
                label: pomodoroLabel),
            NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings),
          ],
        ),
      ),
    );
  }
}
