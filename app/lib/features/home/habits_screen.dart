import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/content/dhikr.dart';
import '../../core/models.dart';
import '../../core/notifications/notif_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/reminder_times_picker.dart';
import 'add_habit_screen.dart';

/// Settings -> "العادات / Habits": manage the user's habits (add / delete /
/// focus). Add reuses AddHabitScreen (cap + advisory); delete uses removeHabit.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  String _s(Map<String, String> m, String loc) => m[loc] ?? m['ar'] ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final breakHabits = s.habitsForTrack('break');
    final buildHabits = s.habitsForTrack('build');
    final canDelete = s.habits.length > 1; // never strand the user with zero

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(_s(_kStr['title']!, loc)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(_s(_kStr['intro']!, loc),
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.6)),
            const SizedBox(height: 18),
            _section(context, ref, loc, '🚭', _s(_kStr['breakTrack']!, loc),
                breakHabits, s.activeHabitId, 'break', s.canAddTrack('break'),
                canDelete),
            const SizedBox(height: 18),
            _section(context, ref, loc, '🌱', _s(_kStr['buildTrack']!, loc),
                buildHabits, s.activeHabitId, 'build', s.canAddTrack('build'),
                canDelete),
          ],
        ),
      ),
    );
  }

  Widget _section(
      BuildContext context,
      WidgetRef ref,
      String loc,
      String emoji,
      String title,
      List<Habit> habits,
      String? activeId,
      String track,
      bool canAdd,
      bool canDelete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.heading)),
            const Spacer(),
            Text('${habits.length}/$kMaxHabitsPerTrack',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        if (habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(_s(_kStr['none']!, loc),
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          )
        else
          ...habits.map(
              (h) => _habitTile(context, ref, loc, h, activeId, canDelete)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: canAdd
              ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()))
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: BorderSide(
                color: canAdd ? AppColors.accent : AppColors.border),
            minimumSize: const Size.fromHeight(46),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(canAdd
              ? _s(_kStr['add']!, loc)
              : _s(_kStr['full']!, loc)),
        ),
      ],
    );
  }

  Widget _habitTile(BuildContext context, WidgetRef ref, String loc, Habit h,
      String? activeId, bool canDelete) {
    final cat = h.catalogKey == null ? null : catalogByKey(h.catalogKey!);
    final icon = cat?.icon ?? (h.track == 'break' ? '🚭' : '🌱');
    final active = h.id == activeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading)),
                  if (active)
                    Text(_s(_kStr['active']!, loc),
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 11)),
                ],
              ),
            ),
            if (!active)
              TextButton(
                onPressed: () => ref
                    .read(appControllerProvider.notifier)
                    .setActiveHabit(h.id),
                child: Text(_s(_kStr['focus']!, loc),
                    style: const TextStyle(fontSize: 12)),
              ),
            IconButton(
              icon: const Icon(Icons.alarm, color: AppColors.accent, size: 20),
              tooltip: _s(_kStr['reminders']!, loc),
              onPressed: () => _editReminders(context, ref, loc, h),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: canDelete ? AppColors.danger : AppColors.border,
                  size: 20),
              tooltip: canDelete ? null : _s(_kStr['lastOne']!, loc),
              onPressed:
                  canDelete ? () => _confirmDelete(context, ref, loc, h) : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editReminders(
      BuildContext context, WidgetRef ref, String loc, Habit h) async {
    var hours = [...h.times];
    final saved = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('${_s(_kStr['reminders']!, loc)} - ${h.title}',
              style: const TextStyle(color: AppColors.heading, fontSize: 16)),
          content: ReminderTimesPicker(
            hours: hours,
            onChanged: (v) => setLocal(() => hours = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_s(_kStr['cancel']!, loc))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, hours),
                child: Text(_s(_kStr['save']!, loc))),
          ],
        ),
      ),
    );
    if (saved == null) return;
    await ref
        .read(appControllerProvider.notifier)
        .setHabitReminderHours(h.id, saved);
    // Reschedule notifications with the updated times.
    final st = ref.read(appControllerProvider);
    await applyNotificationSchedule(
      enabled: st.settings.notificationsEnabled,
      habitReminders: habitRemindersFor(st.habits, loc),
      dhikrEnabled: st.settings.dhikrEnabled,
      showReligious: st.settings.showReligiousContent,
      dhikrHour: st.settings.dhikrHour,
      dhikrTitle: kDhikrTitle[loc] ?? kDhikrTitle['ar']!,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String loc, Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_s(_kStr['delTitle']!, loc),
            style: const TextStyle(color: AppColors.heading)),
        content: Text('${_s(_kStr['delBody']!, loc)}\n\n"${h.title}"',
            style: const TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_s(_kStr['cancel']!, loc))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s(_kStr['delete']!, loc)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appControllerProvider.notifier).removeHabit(h.id);
    }
  }
}

const Map<String, Map<String, String>> _kStr = {
  'title': {'ar': 'العادات', 'en': 'Habits', 'fr': 'Habitudes'},
  'intro': {
    'ar': 'أضِف أو احذف عاداتك. بحد أقصى ٣ عادات للكسر و٣ للبناء في وقتٍ واحد.',
    'en': 'Add or remove your habits. Up to 3 break and 3 build habits at once.',
    'fr': "Ajoutez ou supprimez vos habitudes. Jusqu'à 3 à briser et 3 à bâtir."
  },
  'breakTrack': {'ar': 'عادات الكسر', 'en': 'Break habits', 'fr': 'Habitudes à briser'},
  'buildTrack': {'ar': 'عادات البناء', 'en': 'Build habits', 'fr': 'Habitudes à bâtir'},
  'none': {'ar': 'لا توجد عادات بعد', 'en': 'No habits yet', 'fr': 'Aucune habitude'},
  'add': {'ar': 'إضافة عادة', 'en': 'Add a habit', 'fr': 'Ajouter une habitude'},
  'full': {'ar': 'اكتمل العدد (٣)', 'en': 'Full (3)', 'fr': 'Complet (3)'},
  'active': {'ar': 'العادة النشطة', 'en': 'Active', 'fr': 'Active'},
  'focus': {'ar': 'تنشيط', 'en': 'Focus', 'fr': 'Activer'},
  'delTitle': {'ar': 'حذف العادة', 'en': 'Delete habit', 'fr': "Supprimer l'habitude"},
  'delBody': {
    'ar': 'سيُحذف هذا الهدف وكل سجلاته وأوسمته. لا يمكن التراجع.',
    'en': 'This goal and all its logs and badges will be deleted. This cannot be undone.',
    'fr': 'Cet objectif et tous ses journaux et badges seront supprimés. Irréversible.'
  },
  'cancel': {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler'},
  'delete': {'ar': 'حذف', 'en': 'Delete', 'fr': 'Supprimer'},
  'save': {'ar': 'حفظ', 'en': 'Save', 'fr': 'Enregistrer'},
  'reminders': {'ar': 'أوقات التذكير', 'en': 'Reminder times', 'fr': 'Heures de rappel'},
  'lastOne': {
    'ar': 'لا يمكن حذف آخر عادة. أضِف عادة أخرى أولاً.',
    'en': "Can't delete your last habit. Add another first.",
    'fr': "Impossible de supprimer la dernière habitude. Ajoutez-en une d'abord."
  },
};
