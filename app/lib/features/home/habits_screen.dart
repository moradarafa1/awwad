import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/catalog/habit_icons.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/content/dhikr.dart';
import '../../core/models.dart';
import '../../core/notifications/notif_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/reminder_times_picker.dart';
import 'add_habit_screen.dart';
import 'habit_customizer.dart';

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
                style: TextStyle(
                    color: AppColors.muted, fontSize: 13, height: 1.6)),
            const SizedBox(height: 18),
            _section(context, ref, loc, Icons.smoke_free_rounded,
                _s(_kStr['breakTrack']!, loc),
                breakHabits, s.activeHabitId, 'break', s.canAddTrack('break'),
                canDelete),
            const SizedBox(height: 18),
            _section(context, ref, loc, Icons.eco_rounded,
                _s(_kStr['buildTrack']!, loc),
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
      IconData icon,
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
            Icon(icon, size: 20, color: AppColors.muted),
            const SizedBox(width: 8),
            // Expanded (not Text + Spacer): the French section titles alone
            // overflow this row at the DEFAULT font scale.
            Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.heading)),
            ),
            const SizedBox(width: 8),
            Text('${habits.length}/$kMaxHabitsPerTrack',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        if (habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(_s(_kStr['none']!, loc),
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
    final emoji = cat?.icon ?? (h.track == 'break' ? '🚭' : '🌱');
    final active = h.id == activeId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        child: InkWell(
          onTap: () => _editHabit(context, ref, loc, h),
          borderRadius: BorderRadius.circular(14),
          child: Row(
          children: [
            HabitIcon(
                habitKey: h.catalogKey,
                iconName: h.iconName,
                emoji: emoji,
                size: 22,
                color: habitAccentColor(h.accentColor)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading)),
                  if (active)
                    Text(_s(_kStr['active']!, loc),
                        style: TextStyle(
                            color: AppColors.accent, fontSize: 11)),
                ],
              ),
            ),
            // The three trailing controls are compact: at their default sizes
            // they alone exceed the card on a narrow screen and squeezed the
            // title out of the row.
            if (!active)
              TextButton(
                onPressed: () => ref
                    .read(appControllerProvider.notifier)
                    .setActiveHabit(h.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_s(_kStr['focus']!, loc),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
            IconButton(
              icon: Icon(Icons.alarm, color: AppColors.accent, size: 20),
              tooltip: _s(_kStr['reminders']!, loc),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _editReminders(context, ref, loc, h),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: canDelete ? AppColors.danger : AppColors.border,
                  size: 20),
              tooltip: canDelete ? null : _s(_kStr['lastOne']!, loc),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed:
                  canDelete ? () => _confirmDelete(context, ref, loc, h) : null,
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// Full edit sheet: name, why, icon (custom habits), accent color and the
  /// weekday schedule. One sheet for everything, so customization is not
  /// scattered (owner brief 2026-07-20). Saves through updateHabit; the
  /// reminder schedule rebuilds on the next app open via the single pass in
  /// home_shell.
  Future<void> _editHabit(
      BuildContext context, WidgetRef ref, String loc, Habit h) async {
    final nameCtrl = TextEditingController(text: h.title);
    final whyCtrl = TextEditingController(text: h.reason ?? '');
    String? icon = h.iconName;
    String? color = h.accentColor;
    Set<int> days = (h.scheduleDays == null || h.scheduleDays!.length >= 7)
        ? {1, 2, 3, 4, 5, 6, 7}
        : h.scheduleDays!.toSet();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_s(_kStr['editTitle']!, loc),
                      style: headingStyle(19)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    maxLength: 40,
                    decoration: InputDecoration(
                        labelText: _s(_kStr['editName']!, loc),
                        counterText: ''),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: whyCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                        labelText: _s(_kStr['editWhy']!, loc)),
                  ),
                  if (h.isCustom) ...[
                    const SizedBox(height: 14),
                    Text(tr(ctx, kLblIcon),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 8),
                    IconGridPicker(
                        selected: icon,
                        onChanged: (v) => setSheet(() => icon = v)),
                  ],
                  const SizedBox(height: 14),
                  Text(tr(ctx, kLblColor),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 8),
                  AccentColorRow(
                      selected: color,
                      onChanged: (v) => setSheet(() => color = v)),
                  const SizedBox(height: 14),
                  Text(tr(ctx, kLblDays),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(tr(ctx, kLblDaysSub),
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          height: 1.6)),
                  const SizedBox(height: 8),
                  WeekdayChips(
                      selected: days,
                      onChanged: (v) => setSheet(() => days = v)),
                  const SizedBox(height: 16),
                  Row(children: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(_s(_kStr['editCancel']!, loc),
                            style: TextStyle(color: AppColors.muted))),
                    const Spacer(),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(_s(_kStr['editSave']!, loc))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    final title = nameCtrl.text.trim();
    // copyWith cannot null a field, so a full-week schedule is normalized to
    // all seven days rather than back to null. isScheduledOn treats a
    // complete week exactly like null, so behaviour is identical.
    await ref.read(appControllerProvider.notifier).updateHabit(h.copyWith(
          title: title.isEmpty ? h.title : title,
          reason: whyCtrl.text.trim().isEmpty ? h.reason : whyCtrl.text.trim(),
          iconName: icon,
          accentColor: color,
          scheduleDays: days.length >= 7
              ? const [1, 2, 3, 4, 5, 6, 7]
              : (days.toList()..sort()),
        ));
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
              style: TextStyle(color: AppColors.heading, fontSize: 16)),
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
      locale: loc,
      snoozeMinutes: st.settings.snoozeMinutes,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String loc, Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_s(_kStr['delTitle']!, loc),
            style: TextStyle(color: AppColors.heading)),
        content: Text('${_s(_kStr['delBody']!, loc)}\n\n"${h.title}"',
            style: TextStyle(color: AppColors.text)),
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
      // Tombstone the cloud copy too, or the habit resurrects on the next
      // pull (fire-and-forget; a miss self-heals on a later delete/push).
      if (SupabaseService.signedIn) {
        unawaited(SyncService.deleteHabitCloud(h.id).catchError((_) {}));
      }
    }
  }
}

const Map<String, Map<String, String>> _kStr = {
  'editTitle': {'ar': 'تحرير العادة', 'en': 'Edit habit', 'fr': "Modifier l'habitude"},
  'editName': {'ar': 'اسم العادة', 'en': 'Habit name', 'fr': 'Nom'},
  'editWhy': {'ar': 'دافعك للتغيير', 'en': 'Your why', 'fr': 'Votre raison'},
  'editCancel': {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler'},
  'editSave': {'ar': 'حفظ', 'en': 'Save', 'fr': 'Enregistrer'},
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
  'reminders': {'ar': 'أوقات تذكيرك بتسجيل التقدم', 'en': 'Progress reminder times', 'fr': 'Heures de rappel de progrès'},
  'lastOne': {
    'ar': 'لا يمكن حذف آخر عادة. أضِف عادة أخرى أولاً.',
    'en': "Can't delete your last habit. Add another first.",
    'fr': "Impossible de supprimer la dernière habitude. Ajoutez-en une d'abord."
  },
};
