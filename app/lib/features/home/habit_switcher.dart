import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_catalog.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart';
import 'add_habit_screen.dart';

/// Horizontal selector that lets the user switch the active habit (which the
/// Today / Stats / History tabs follow) and add a new one via "+".
/// Hidden when the user only has a single habit, to keep the UI clean.
class HabitSwitcher extends ConsumerWidget {
  const HabitSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appControllerProvider);
    final loc = Localizations.localeOf(context).languageCode;
    if (s.habits.isEmpty) return const SizedBox.shrink();
    final activeId = s.activeHabitId;
    // Always show the active-habit chip(s), even with a single habit, so its
    // name is visible at the top of Today / Stats / History / Badges, plus the
    // "+" to add another.
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final h in s.habits) ...[
            _HabitChip(
              habit: h,
              locale: loc,
              active: h.id == activeId,
              onTap: () =>
                  ref.read(appControllerProvider.notifier).setActiveHabit(h.id),
              onRemove: s.habits.length > 1
                  ? () => _confirmRemove(context, ref, h, loc)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          _AddChip(onTap: () => _openAdd(context)),
        ],
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddHabitScreen()));
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Habit h, String loc) async {
    String tr(Map<String, String> m) => m[loc] ?? m['ar'] ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr(_kRemoveTitle),
            style: const TextStyle(color: AppColors.heading)),
        content: Text('${tr(_kRemoveBody)}\n\n"${h.title}"',
            style: const TextStyle(color: AppColors.text)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(_kCancel))),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(_kRemove))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appControllerProvider.notifier).removeHabit(h.id);
    }
  }
}

class _HabitChip extends StatelessWidget {
  const _HabitChip({
    required this.habit,
    required this.locale,
    required this.active,
    required this.onTap,
    this.onRemove,
  });
  final Habit habit;
  final String locale;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cat = habit.catalogKey == null ? null : catalogByKey(habit.catalogKey!);
    final icon = cat?.icon ?? (habit.track == 'break' ? '🚭' : '🌱');
    final accent =
        habit.track == 'break' ? AppColors.danger : AppColors.success;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRemove,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.16) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? accent : AppColors.border,
              width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                habit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? AppColors.heading : AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final label = const {
      'ar': 'أضف هدفًا',
      'en': 'Add goal',
      'fr': 'Ajouter'
    }[loc] ?? 'Add goal';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 18, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _kRemoveTitle = {
  'ar': 'حذف الهدف',
  'en': 'Remove goal',
  'fr': "Supprimer l'objectif"
};
const Map<String, String> _kRemoveBody = {
  'ar': 'سيُحذف هذا الهدف وكل سجلاته وأوسمته. لا يمكن التراجع.',
  'en': 'This goal and all its logs and badges will be deleted. This cannot be undone.',
  'fr': "Cet objectif et tous ses journaux et badges seront supprimés. Action irréversible."
};
const Map<String, String> _kRemove = {'ar': 'حذف', 'en': 'Remove', 'fr': 'Supprimer'};
const Map<String, String> _kCancel = {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler'};
