// PRAYER home-screen widget (Android): the next prayer, a LIVE countdown to
// the adhan, the Hijri date and today's five times - the shape every
// mainstream adhan app ships. The widget itself is native
// (PrayerWidgetProvider.kt + res/layout/prayer_widget.xml); this file is the
// Dart side: it computes the times with the SAME astronomical engine the
// notifications use and pushes a 30-day table plus every user-visible string
// to the widget's data store.
//
// Why a 30-DAY table instead of "today's times": a home-screen widget cannot
// run Dart, and the app may not be opened for weeks. The native side picks
// the next entry at render time, so one push keeps a month of countdowns
// correct. Mirrors the native adhan chain's own table (kAdhanNativeTableDays).
//
// Why the countdown is NOT pushed as text: RemoteViews cannot tick and the
// widget update floor is 30 minutes, so a pushed "01:12 remaining" would be a
// lie within a minute. The native layout uses a Chronometer in countdown
// mode, which the SYSTEM ticks for free, second by second, without ever
// waking the app.
//
// Why the Hijri date is NOT pushed as text either: it would go stale at the
// first midnight. Only the twelve MONTH NAMES are pushed (localized here, per
// the rule that nothing native hardcodes a language); the native side does
// the Umm al-Qura conversion at render time.
//
// Fail-open everywhere: web/errors are silent no-ops.

import 'package:home_widget/home_widget.dart';

import '../prayer/prayer_engine.dart';
import 'widget_sync.dart' show ensureWidgetAppGroup, homeWidgetsSupported;

/// Android provider class name + iOS WidgetKit kind.
const String kPrayerWidgetAndroid = 'PrayerWidgetProvider';
const String kPrayerWidgetIos = 'PrayerWidget';

/// Days of prayer moments the widget table carries. Same horizon as the
/// native adhan chain, for the same reason: the app may never be opened.
const int kPrayerWidgetDays = 30;

const _kNextLabel = {
  'ar': 'الصلاة القادمة',
  'en': 'Next prayer',
  'fr': 'Prochaine prière',
};

const _kEmpty = {
  'ar': 'حدّد موقعك من إعدادات الصلاة',
  'en': 'Set your location in prayer settings',
  'fr': 'Definissez votre lieu dans les reglages',
};

/// Hijri month names, index 0 = Muharram. The native side only produces the
/// NUMBERS (Umm al-Qura), never a name, so no language is hardcoded there.
const _kHijriMonths = {
  'ar': [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ],
  'en': [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhul-Qi'dah",
    'Dhul-Hijjah',
  ],
  'fr': [
    'Mouharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Joumada I',
    'Joumada II',
    'Rajab',
    "Cha'ban",
    'Ramadan',
    'Chawwal',
    "Dhou al-Qi'da",
    'Dhou al-Hijja',
  ],
};

/// Year marker after the Hijri year («1448 هـ»).
const _kHijriSuffix = {'ar': 'هـ', 'en': 'AH', 'fr': 'AH'};

String _t(Map<String, String> m, String loc) => m[loc] ?? m['ar']!;

String _two(int n) => n.toString().padLeft(2, '0');

/// The widget's time table: `epochMillis|key|HH:mm` entries, comma-joined,
/// for [days] days starting with [now]'s date. ALL five times of every day
/// are included (not only future ones): the native side needs today's full
/// set to draw the five-times row, and picks the next entry itself.
///
/// Date-component arithmetic, NOT `.add(Duration(days: d))`: a Duration is 24
/// wall-clock hours, so a 23/25-hour DST day would duplicate or skip a
/// calendar day over a 30-day horizon (Egypt observes DST again).
String encodePrayerWidgetTimes(
  PrayerConfig cfg, {
  DateTime? now,
  int days = kPrayerWidgetDays,
}) {
  if (!cfg.configured) return '';
  final ref = now ?? DateTime.now();
  final out = <String>[];
  for (var d = 0; d < days; d++) {
    final day = DateTime(ref.year, ref.month, ref.day + d);
    final times = timesFor(cfg, day);
    for (final key in kPrayerKeys) {
      final t = times[key];
      if (t == null) continue;
      out.add('${t.millisecondsSinceEpoch}|$key|${_two(t.hour)}:${_two(t.minute)}');
    }
  }
  return out.join(',');
}

/// Display order of the five-times row. The row's layout direction is LOCKED
/// to ltr natively, because a widget follows the DEVICE locale while its
/// content follows the APP language and the two can disagree. So Arabic is
/// reversed here: the first entry is drawn leftmost, which puts الفجر on the
/// right where an Arabic reader starts.
String prayerRowOrder(String locale) =>
    (locale == 'ar' ? kPrayerKeys.reversed.toList() : kPrayerKeys).join(',');

/// `key=name` pairs, comma-joined (the native side hardcodes no prayer name).
String encodePrayerNames(String locale) =>
    kPrayerKeys.map((k) => '$k=${prayerName(k, locale)}').join(',');

/// The twelve Hijri month names, pipe-joined, index 0 = Muharram.
String hijriMonthNames(String locale) =>
    (_kHijriMonths[locale] ?? _kHijriMonths['ar']!).join('|');

/// The city line shown next to the Hijri date, empty when unknown.
String prayerWidgetCity(PrayerConfig cfg, String locale) =>
    ((locale == 'ar' ? cfg.cityAr : cfg.cityEn) ?? '').trim();

class PrayerWidgetSync {
  PrayerWidgetSync._();

  /// Pushes the whole widget payload and asks the OS to re-render. Cheap and
  /// idempotent; called from applyPrayerSchedule, which is the single funnel
  /// for "the prayer configuration may have changed" (app open, settings
  /// edit, onboarding location step).
  static Future<void> push(PrayerConfig cfg, {required String locale}) async {
    if (!homeWidgetsSupported) return;
    try {
      await ensureWidgetAppGroup();
      final table = encodePrayerWidgetTimes(cfg);
      // `configured` alone is not enough: a config can be configured and yet
      // produce no times (a corrupt lat/lng), and the widget must then show
      // its guidance line instead of an empty card.
      await HomeWidget.saveWidgetData<bool>(
          'pw_has', cfg.configured && table.isNotEmpty);
      await HomeWidget.saveWidgetData<String>('pw_times', table);
      await HomeWidget.saveWidgetData<String>(
          'pw_names', encodePrayerNames(locale));
      await HomeWidget.saveWidgetData<String>(
          'pw_order', prayerRowOrder(locale));
      await HomeWidget.saveWidgetData<String>(
          'pw_next', _t(_kNextLabel, locale));
      await HomeWidget.saveWidgetData<String>('pw_empty', _t(_kEmpty, locale));
      await HomeWidget.saveWidgetData<String>(
          'pw_hmonths', hijriMonthNames(locale));
      await HomeWidget.saveWidgetData<String>(
          'pw_hsuffix', _t(_kHijriSuffix, locale));
      await HomeWidget.saveWidgetData<String>(
          'pw_city', prayerWidgetCity(cfg, locale));
      await HomeWidget.updateWidget(
          androidName: kPrayerWidgetAndroid, iOSName: kPrayerWidgetIos);
    } catch (_) {
      // Fail-open: the widget keeps its previous content, which is still
      // correct for up to 30 days.
    }
  }
}
