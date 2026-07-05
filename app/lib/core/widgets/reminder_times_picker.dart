import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Lets the user pick one or more daily reminder times for a habit (e.g. water
/// at several times of day). Times are whole hours (0-23). Optional: the list
/// may be empty (no reminders).
class ReminderTimesPicker extends StatelessWidget {
  const ReminderTimesPicker(
      {super.key, required this.hours, required this.onChanged});

  final List<int> hours;
  final ValueChanged<List<int>> onChanged;

  String _fmt(int h) => '${h.toString().padLeft(2, '0')}:00';

  Future<void> _addTime(BuildContext context) async {
    final loc = Localizations.localeOf(context).languageCode;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
      helpText: const {
            'ar': 'اختر وقت تذكير',
            'en': 'Pick a reminder time',
            'fr': 'Choisir une heure de rappel',
          }[loc] ??
          'Pick a reminder time',
    );
    if (picked == null) return;
    if (hours.contains(picked.hour)) return;
    final next = [...hours, picked.hour]..sort();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    final addLabel = const {
          'ar': 'أضف وقتًا',
          'en': 'Add a time',
          'fr': 'Ajouter une heure',
        }[loc] ??
        'Add a time';
    final emptyLabel = const {
          'ar': 'بدون تذكير',
          'en': 'No reminders',
          'fr': 'Aucun rappel',
        }[loc] ??
        'No reminders';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hours.isEmpty)
          Text(emptyLabel,
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ...hours.map((h) => Container(
              padding: const EdgeInsets.only(left: 6, right: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onChanged([...hours]..remove(h)),
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: AppColors.accent),
                    ),
                  ),
                  Text(_fmt(h),
                      style: TextStyle(
                          color: AppColors.heading,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            )),
        InkWell(
          onTap: () => _addTime(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_alarm, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(addLabel,
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
