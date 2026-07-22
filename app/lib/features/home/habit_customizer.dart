import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/catalog/habit_icons.dart';

/// The three PRO-customization controls (icon, accent color, weekday
/// schedule), shared VERBATIM between the add-habit flow and the edit sheet
/// so the two can never drift apart. Owner brief 2026-07-20: everything about
/// a habit should be customizable, professionally.
///
/// All controls are stateless and callback-driven; the parent owns the values.

String _loc(BuildContext c) => Localizations.localeOf(c).languageCode;

String tr(BuildContext c, Map<String, String> m) =>
    m[_loc(c)] ?? m['ar'] ?? '';

const kLblIcon = {'ar': 'الأيقونة', 'en': 'Icon', 'fr': 'Icône'};
const kLblDays = {
  'ar': 'أيام العادة في الأسبوع',
  'en': 'Days of the week',
  'fr': 'Jours de la semaine'
};
const kLblDaysSub = {
  'ar': 'اتركها كلها مفعّلة لعادة يومية. اليوم غير المختار لا يقطع سلسلتك.',
  'en': 'Keep all on for a daily habit. An unselected day never breaks your streak.',
  'fr': "Tout laisser actif pour une habitude quotidienne. Un jour non choisi ne brise jamais votre série."
};

/// Weekday initials, ISO order 1(Mon)..7(Sun). The UI renders Saturday-first
/// for Arabic (the working week there), Monday-first otherwise.
const Map<String, List<String>> _dayInitials = {
  'ar': ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
  'en': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  'fr': ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
};

List<int> weekdayDisplayOrder(String locale) =>
    locale == 'ar' ? const [6, 7, 1, 2, 3, 4, 5] : const [1, 2, 3, 4, 5, 6, 7];

class IconGridPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const IconGridPicker(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final keys = kCustomHabitIcons.keys.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in keys)
          InkWell(
            onTap: () => onChanged(k == selected ? null : k),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: k == selected
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        k == selected ? AppColors.accent : AppColors.border),
              ),
              child: Icon(kCustomHabitIcons[k],
                  size: 22,
                  color: k == selected ? AppColors.accent : AppColors.text),
            ),
          ),
      ],
    );
  }
}

class WeekdayChips extends StatelessWidget {
  /// ISO weekdays currently selected. Empty or full set = daily.
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  const WeekdayChips(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = _loc(context);
    final initials = _dayInitials[locale] ?? _dayInitials['ar']!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final day in weekdayDisplayOrder(locale))
          InkWell(
            onTap: () {
              final next = {...selected};
              if (!next.remove(day)) next.add(day);
              // Clearing every chip silently reverts to daily (owner rule):
              // an empty schedule is meaningless, not an error to scold over.
              onChanged(next.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : next);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected.contains(day)
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected.contains(day)
                        ? AppColors.accent
                        : AppColors.border),
              ),
              child: Text(initials[day - 1],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected.contains(day)
                          ? AppColors.accent
                          : AppColors.muted)),
            ),
          ),
      ],
    );
  }
}
