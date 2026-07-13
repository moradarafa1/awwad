import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:intl/intl.dart' hide TextDirection;

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/state/app_state.dart' show dayKey;

/// Monthly calendar heatmap for the active habit ("سجل الشهر").
///
/// Best-in-class habit-tracker calendar: month navigation, locale-aware week
/// start (Saturday for Arabic via MaterialLocalizations), RTL-mirrored grid
/// for free (rows inherit Directionality), role-based theme colors (dark AND
/// light palettes resolve through AppColors getters - never const), a legend,
/// a month-completion summary, and a per-day details bottom sheet.
///
/// Pure widget: everything it needs is passed in; no providers, no new deps.
class MonthHeatmapCard extends StatefulWidget {
  const MonthHeatmapCard({
    super.key,
    required this.entries,
    required this.habit,
    required this.primaryMetricLabel,
    required this.secondaryMetricLabel,
    this.onLogToday,
  });

  /// Entries of the ACTIVE habit only (any order).
  final List<DailyEntry> entries;
  final Habit habit;

  /// Localized labels of the two sliders (urge/progress etc.) for the sheet.
  final String primaryMetricLabel;
  final String secondaryMetricLabel;

  /// Invoked from the "log today" button in the empty-today sheet.
  final VoidCallback? onLogToday;

  @override
  State<MonthHeatmapCard> createState() => _MonthHeatmapCardState();
}

/// Leading blank cells before day 1, for a week starting at [firstDow]
/// (0=Sunday .. 6=Saturday, as MaterialLocalizations.firstDayOfWeekIndex).
/// DateTime.weekday is Mon=1..Sun=7; `% 7` converts it to Sun=0..Sat=6.
int leadingOffset(DateTime firstOfMonth, int firstDow) =>
    (firstOfMonth.weekday % 7 - firstDow + 7) % 7;

/// Number of days in the month containing [month] (day-0 trick handles
/// leap years and 28-31 day months without any tables).
int daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

class _MonthHeatmapCardState extends State<MonthHeatmapCard> {
  late DateTime _shown; // first day of the displayed month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _shown = DateTime(now.year, now.month, 1);
  }

  @override
  void didUpdateWidget(covariant MonthHeatmapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // HabitSwitcher swaps the active habit in place (key-less widget, same
    // slot -> same State). A month browsed for habit A may predate habit B,
    // so reset to the current month whenever the habit changes.
    if (oldWidget.habit.id != widget.habit.id) {
      final now = DateTime.now();
      _shown = DateTime(now.year, now.month, 1);
    }
  }

  String _tr(String k) {
    final loc = Localizations.localeOf(context).languageCode;
    return (_calStrings[loc] ?? _calStrings['en']!)[k]!;
  }

  bool get _isBreak => widget.habit.track != 'build';

  int _monthIndex(DateTime d) => d.year * 12 + d.month;

  void _nav(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _shown = DateTime(_shown.year, _shown.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final mat = MaterialLocalizations.of(context);
    final firstDow = mat.firstDayOfWeekIndex; // 0=Sun..6=Sat (ar -> 6)
    final now = DateTime.now();
    final todayKey = dayKey(now);

    // O(1) day lookup, built once per build.
    final byDay = <String, DailyEntry>{
      for (final e in widget.entries) e.date: e,
    };

    final created = widget.habit.createdAt;
    final minMonth = _monthIndex(DateTime(created.year, created.month));
    final maxMonth = _monthIndex(DateTime(now.year, now.month));
    final shownIdx = _monthIndex(_shown);
    final canPrev = shownIdx > minMonth;
    final canNext = shownIdx < maxMonth;

    final leading = leadingOffset(_shown, firstDow);
    final dim = daysInMonth(_shown);
    final rows = (leading + dim + 6) ~/ 7;

    // RTL note: Icons.chevron_left / chevron_right carry
    // matchTextDirection=true in their IconData, so the framework already
    // mirrors the GLYPH under RTL while Row mirrors the POSITION. Passing
    // them as-is gives correct arrows in BOTH directions - never hand-swap
    // (that double-mirrors and inverts the navigation affordance).
    const prevIcon = Icons.chevron_left;
    const nextIcon = Icons.chevron_right;

    // Month summary: logged days / elapsed days (mid-month starts forgiven).
    final monthPrefix =
        '${_shown.year.toString().padLeft(4, '0')}-${_shown.month.toString().padLeft(2, '0')}';
    final logged =
        widget.entries.where((e) => e.date.startsWith(monthPrefix)).length;
    var elapsed = shownIdx == maxMonth ? now.day : dim;
    if (shownIdx == minMonth) {
      elapsed = (elapsed - created.day + 1).clamp(1, dim);
    }
    final pct = ((logged / elapsed) * 100).clamp(0, 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: prev / month title / next (Row mirrors under RTL).
          Row(
            children: [
              IconButton(
                onPressed: canPrev ? () => _nav(-1) : null,
                icon: Opacity(
                  opacity: canPrev ? 1 : 0.35,
                  child: Icon(prevIcon),
                ),
                color: AppColors.muted,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(_shown),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.heading),
                ),
              ),
              IconButton(
                onPressed: canNext ? () => _nav(1) : null,
                icon: Opacity(
                  opacity: canNext ? 1 : 0.35,
                  child: Icon(nextIcon),
                ),
                color: AppColors.muted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Weekday initials, starting at the locale's first day of week.
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      mat.narrowWeekdays[(firstDow + i) % 7],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Day grid: rows of 7 Expanded square cells (no GridView needed;
          // Row inherits Directionality so RTL mirroring is automatic).
          for (var r = 0; r < rows; r++) ...[
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _cell(r * 7 + c, leading, dim, todayKey, byDay)),
              ],
            ),
            if (r < rows - 1) const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          // Legend.
          Wrap(
            spacing: 14,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legendItem(AppColors.accent2,
                  _isBreak ? _tr('legendClean') : _tr('legendDone')),
              _legendItem(_isBreak ? AppColors.danger : AppColors.accent3,
                  _isBreak ? _tr('legendSlip') : _tr('legendMissed')),
              _legendItem(
                  AppColors.muted.withValues(alpha: 0.30), _tr('legendSkip')),
              _legendItem(null, _tr('legendEmpty')),
            ],
          ),
          const SizedBox(height: 10),
          // Month summary line.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.accent2.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_tr('monthLogged')}: $logged   ·   ${_tr('monthCompletion')}: $pct%',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int i, int leading, int dim, String todayKey,
      Map<String, DailyEntry> byDay) {
    final day = i - leading + 1;
    if (day < 1 || day > dim) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }
    final key =
        '${_shown.year.toString().padLeft(4, '0')}-${_shown.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final entry = byDay[key];
    final isToday = key == todayKey;
    final isFuture = key.compareTo(todayKey) > 0;

    Color? fill;
    Color ink;
    Border? border;
    if (entry != null && entry.isSkip) {
      // Excused day (travel/sickness): distinct neutral fill.
      fill = AppColors.muted.withValues(alpha: 0.30);
      ink = AppColors.heading;
    } else if (entry != null) {
      fill = entry.didSlip
          ? (_isBreak ? AppColors.danger : AppColors.accent3)
          : AppColors.accent2;
      ink = AppColors.isDark ? AppColors.bg : Colors.white;
    } else if (isFuture) {
      ink = AppColors.muted.withValues(alpha: 0.4);
    } else {
      ink = AppColors.muted;
      border = Border.all(color: AppColors.border);
    }

    final cell = AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: AppColors.accent, width: 2)
              : border,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ink),
        ),
      ),
    );

    if (isFuture) return cell;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showDaySheet(key, entry, isToday),
      child: cell,
    );
  }

  Widget _legendItem(Color? color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: color == null
                ? Border.all(color: AppColors.border)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    );
  }

  void _showDaySheet(String key, DailyEntry? entry, bool isToday) {
    final locale = Localizations.localeOf(context).toString();
    final parts = key.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], parts[2]);
    final title = DateFormat.yMMMMEEEEd(locale).format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        // Scrollable: long journaling notes would otherwise overflow the
        // sheet's 9/16-height cap on small phones.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.heading)),
              const SizedBox(height: 14),
              if (entry != null && entry.isSkip) ...[
                Text(_tr('skippedDay'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
              ] else if (entry == null) ...[
                Text(_tr('noEntry'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
                if (isToday && widget.onLogToday != null) ...[
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onLogToday!();
                    },
                    child: Text(_tr('logNow')),
                  ),
                ],
              ] else ...[
                // Status chip + mood.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (entry.moodEmoji != null) ...[
                      Text(entry.moodEmoji!,
                          style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (entry.didSlip
                                ? (_isBreak
                                    ? AppColors.danger
                                    : AppColors.accent3)
                                : AppColors.accent2)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.didSlip
                            ? (_isBreak
                                ? _tr('legendSlip')
                                : _tr('legendMissed'))
                            : (_isBreak
                                ? _tr('legendClean')
                                : _tr('legendDone')),
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: entry.didSlip
                                ? (_isBreak
                                    ? AppColors.danger
                                    : AppColors.accent3)
                                : AppColors.accent2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _metricBar(widget.primaryMetricLabel, entry.urge,
                    AppColors.accent3),
                const SizedBox(height: 10),
                _metricBar(widget.secondaryMetricLabel, entry.resistance,
                    AppColors.accent2),
                if ((entry.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(entry.note!.trim(),
                        style: TextStyle(
                            color: AppColors.text, height: 1.6, fontSize: 13)),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              for (var i = 1; i <= 10; i++) ...[
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= value
                          ? color
                          : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 10) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$value/10',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

const Map<String, Map<String, String>> _calStrings = {
  'ar': {
    'legendClean': 'يوم نظيف',
    'legendSlip': 'يوم به تعثر',
    'legendDone': 'أُنجزت العادة',
    'legendMissed': 'لم تُنجَز',
    'legendEmpty': 'بدون تسجيل',
    'legendSkip': 'يوم مُعفى',
    'skippedDay': 'يوم مُعفى (سفر أو مرض): لا يؤثر في سلسلتك.',
    'monthLogged': 'أيام مسجّلة هذا الشهر',
    'monthCompletion': 'نسبة الالتزام',
    'noEntry': 'لا يوجد تسجيل في هذا اليوم.',
    'logNow': 'سجّل اليوم الآن',
  },
  'en': {
    'legendClean': 'Clean day',
    'legendSlip': 'Day with a slip',
    'legendDone': 'Habit done',
    'legendMissed': 'Missed',
    'legendEmpty': 'Not logged',
    'legendSkip': 'Excused day',
    'skippedDay': 'Excused day (travel/sickness): does not affect your streak.',
    'monthLogged': 'Days logged this month',
    'monthCompletion': 'Consistency',
    'noEntry': 'No entry on this day.',
    'logNow': 'Log today now',
  },
  'fr': {
    'legendClean': 'Journée réussie',
    'legendSlip': 'Journée avec écart',
    'legendDone': 'Habitude accomplie',
    'legendMissed': 'Manquée',
    'legendEmpty': 'Non enregistré',
    'legendSkip': 'Jour exempté',
    'skippedDay': "Jour exempté (voyage/maladie) : sans effet sur la série.",
    'monthLogged': 'Jours enregistrés ce mois',
    'monthCompletion': 'Assiduité',
    'noEntry': "Aucune entrée ce jour-là.",
    'logNow': "Enregistrer aujourd'hui",
  },
};
