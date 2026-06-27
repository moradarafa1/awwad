import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/notifications/notifications.dart';
import '../../core/state/app_state.dart';
import 'daily_log_screen.dart';
import 'stats_screen.dart';
import 'badges_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _nudged = false;

  static const _screens = [
    DailyLogScreen(),
    StatsScreen(),
    BadgesScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeNudge();
      _scheduleReminder();
    });
  }

  void _scheduleReminder() {
    if (!mounted) return;
    final s = ref.read(appControllerProvider);
    if (!s.settings.notificationsEnabled) {
      cancelReminders();
      return;
    }
    final l10n = AppLocalizations.of(context);
    scheduleDailyReminder(s.settings.reminderHour, l10n.appName, l10n.saveEntry);
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
          '🔥 ${l10n.statsCurrentStreak}: ${s.currentStreak} — ${l10n.saveEntry}',
          style: const TextStyle(color: AppColors.text),
        ),
        action: SnackBarAction(
          label: l10n.navToday,
          textColor: AppColors.accent,
          onPressed: () {
            AnalyticsService.instance
                .track('popup_cta_clicked', {'type': 'streak_risk'});
            setState(() => _index = 0);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: _screens)),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.navSettings),
          ],
        ),
      ),
    );
  }
}
