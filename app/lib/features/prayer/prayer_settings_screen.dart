// Prayer-times settings (TODO 0d Phase A): location via GPS with a bundled
// country -> city fallback, today's five times with per-prayer manual editing,
// and the «remind me 5 minutes before» toggle. Times are recomputed offline
// every day; the notification window is rebuilt on every save and app open.

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import '../../core/notifications/notifications.dart';
import '../../core/platform/reliability.dart';
import '../../core/prayer/prayer_engine.dart';
import '../../core/prayer/prayer_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';

class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});
  @override
  ConsumerState<PrayerSettingsScreen> createState() =>
      _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen>
    with WidgetsBindingObserver {
  PrayerConfig _cfg = const PrayerConfig();
  bool _locating = false;
  // Android 12+ «Alarms and reminders» grant missing: the adhan/prayer
  // notifications would be delayed by inexact batching until it is given.
  bool _exactMissing = false;
  // Adhan is on but the OS will still mute it inside Do Not Disturb.
  bool _dndMissing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final raw = ref.read(localStoreProvider).loadPrayer();
    if (raw != null) _cfg = PrayerConfig.fromJson(raw);
    _checkExact();
    _checkDnd();
  }

  Future<void> _checkDnd() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final ok = await hasDndAccess();
    if (mounted) setState(() => _dndMissing = !ok);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The user may grant «Alarms and reminders» straight from system settings:
  // re-check on return so the tile disappears and queued alarms upgrade.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    Future(() async {
      final was = _exactMissing;
      await _checkExact();
      if (mounted && was && !_exactMissing) await _save();
    });
  }

  Future<void> _checkExact() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final ok = await canUseExactAlarms();
    if (mounted) setState(() => _exactMissing = !ok);
  }

  String get _loc => Localizations.localeOf(context).languageCode;
  String _s(String k) => _kStr[k]![_loc] ?? _kStr[k]!['ar']!;

  Future<void> _save() async {
    await ref.read(localStoreProvider).savePrayer(_cfg.toJson());
    final s = ref.read(appControllerProvider);
    await applyPrayerSchedule(
      store: ref.read(localStoreProvider),
      habits: s.habits,
      notificationsEnabled: s.settings.notificationsEnabled,
      showReligious: s.settings.showReligiousContent,
      locale: _loc,
    );
  }

  Future<void> _useGps() async {
    if (kIsWeb) return;
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_s('gpsDenied'))));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 20));
      final cities = await loadCities();
      final near = nearestCity(cities, pos.latitude, pos.longitude);
      setState(() => _cfg = _cfg.copyWith(
            lat: pos.latitude,
            lng: pos.longitude,
            cityAr: near.cityAr,
            cityEn: near.cityEn,
            countryAr: near.countryAr,
            countryEn: near.countryEn,
            offsets: {},
          ));
      await _save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s('gpsFailed'))));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickCity() async {
    final cities = await loadCities();
    if (!mounted) return;
    final ar = _loc == 'ar';
    // Country first.
    final countries = <String>[];
    final seen = <String>{};
    for (final c in cities) {
      final name = ar ? c.countryAr : c.countryEn;
      if (seen.add(name)) countries.add(name);
    }
    countries.sort();
    final country = await _pickFromList(_s('pickCountry'), countries);
    if (country == null || !mounted) return;
    final inCountry = cities
        .where((c) => (ar ? c.countryAr : c.countryEn) == country)
        .toList()
      ..sort((a, b) =>
          (ar ? a.cityAr : a.cityEn).compareTo(ar ? b.cityAr : b.cityEn));
    final cityName = await _pickFromList(
        _s('pickCity'), [for (final c in inCountry) ar ? c.cityAr : c.cityEn]);
    if (cityName == null || !mounted) return;
    final city =
        inCountry.firstWhere((c) => (ar ? c.cityAr : c.cityEn) == cityName);
    setState(() => _cfg = _cfg.copyWith(
          lat: city.lat,
          lng: city.lng,
          cityAr: city.cityAr,
          cityEn: city.cityEn,
          countryAr: city.countryAr,
          countryEn: city.countryEn,
          offsets: {},
        ));
    await _save();
  }

  Future<String?> _pickFromList(String title, List<String> items) {
    var query = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final filtered = [
            for (final i in items)
              if (query.isEmpty || i.contains(query)) i
          ];
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: SizedBox(
                height: 480,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.heading)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                          hintText: _s('search'), isDense: true),
                      onChanged: (v) => setSheet(() => query = v.trim()),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(filtered[i]),
                        onTap: () => Navigator.pop(ctx, filtered[i]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editTime(String key, DateTime computed) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(computed),
    );
    if (picked == null) return;
    final base = computed
        .subtract(Duration(minutes: _cfg.offsets[key] ?? 0)); // raw astro time
    final chosen = DateTime(
        base.year, base.month, base.day, picked.hour, picked.minute);
    final off = chosen.difference(base).inMinutes;
    setState(() => _cfg = _cfg.copyWith(offsets: {..._cfg.offsets, key: off}));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final times = _cfg.configured ? timesFor(_cfg, DateTime.now()) : const <String, DateTime>{};
    final ar = _loc == 'ar';
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

    return Scaffold(
      appBar: AppBar(title: Text(_s('title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_s('locTitle'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  _cfg.configured
                      ? '${ar ? _cfg.cityAr : _cfg.cityEn} · ${ar ? _cfg.countryAr : _cfg.countryEn}'
                      : _s('noLoc'),
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  if (!kIsWeb)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _locating ? null : _useGps,
                        icon: _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, size: 18),
                        label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(_s('useGps'), maxLines: 1)),
                      ),
                    ),
                  if (!kIsWeb) const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCity,
                      icon: const Icon(Icons.location_city, size: 18),
                      label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_s('pickManually'), maxLines: 1)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_cfg.configured) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_s('todayTitle'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_s('editHint'),
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  for (final key in kPrayerKeys)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(prayerName(key, _loc),
                          style: const TextStyle(fontSize: 13.5)),
                      subtitle: (_cfg.offsets[key] ?? 0) != 0
                          ? Text(_s('adjusted'),
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.accent2))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(fmt(times[key]!),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.heading)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.muted),
                        ],
                      ),
                      onTap: () => _editTime(key, times[key]!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _cfg.preAlert,
                  activeThumbColor: AppColors.accent,
                  title: Text(_s('preAlert'),
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(_s('preAlertSub'),
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  onChanged: (v) async {
                    setState(() => _cfg = _cfg.copyWith(preAlert: v));
                    await _save();
                  },
                ),
                if (!kIsWeb) ...[
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _cfg.adhanSound,
                    activeThumbColor: AppColors.accent,
                    title: Text(_s('adhanSound'),
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(_s('adhanSoundSub'),
                        style:
                            TextStyle(fontSize: 11, color: AppColors.muted)),
                    onChanged: (v) async {
                      setState(() => _cfg = _cfg.copyWith(adhanSound: v));
                      // The bypass channel must exist before the first adhan
                      // is scheduled onto it.
                      await _checkDnd();
                      await _save();
                    },
                  ),
                  // Honest DND note: the adhan can only pierce Do Not Disturb
                  // if the user grants that access, so we say so plainly
                  // instead of quietly failing at prayer time.
                  if (_cfg.adhanSound && _dndMissing)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.do_not_disturb_on_outlined,
                          color: AppColors.accent2),
                      title: Text(_s('dnd'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(_s('dndSub'),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                      onTap: () async {
                        await openDndAccessSettings();
                        await _checkDnd();
                        // Re-create the channel now that access may have been
                        // granted: setBypassDnd only sticks while held.
                        if (!_dndMissing) {
                          await createAdhanBypassChannel(
                              name: _s('dndChName'), description: _s('dndChDesc'));
                        }
                      },
                    ),
                ],
                if (_exactMissing) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.alarm_on, color: AppColors.accent2),
                    title: Text(_s('exactAlarm'),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(_s('exactAlarmSub'),
                        style:
                            TextStyle(fontSize: 11, color: AppColors.muted)),
                    onTap: () async {
                      await requestExactAlarmsPermission();
                      await _checkExact();
                      // Re-run scheduling so the already-queued prayer
                      // notifications upgrade to exact delivery.
                      await _save();
                    },
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            Text(_s('note'),
                style: TextStyle(
                    color: AppColors.muted, fontSize: 11.5, height: 1.6)),
          ],
        ],
      ),
    );
  }
}

const Map<String, Map<String, String>> _kStr = {
  'title': {
    'ar': 'مواقيت الصلاة والتذكير',
    'en': 'Prayer times and reminders',
    'fr': 'Horaires de priere et rappels'
  },
  'locTitle': {'ar': 'موقعك', 'en': 'Your location', 'fr': 'Votre position'},
  'noLoc': {
    'ar': 'لم يُحدد بعد. استخدم موقعك الحالي أو اختر مدينتك يدوياً.',
    'en': 'Not set yet. Use GPS or pick your city manually.',
    'fr': 'Non defini. Utilisez le GPS ou choisissez votre ville.'
  },
  'useGps': {
    'ar': 'موقعي الحالي',
    'en': 'Use my location',
    'fr': 'Ma position'
  },
  'pickManually': {
    'ar': 'اختيار المدينة',
    'en': 'Pick a city',
    'fr': 'Choisir une ville'
  },
  'pickCountry': {
    'ar': 'اختر دولتك',
    'en': 'Choose your country',
    'fr': 'Choisissez votre pays'
  },
  'pickCity': {
    'ar': 'اختر أقرب مدينة إليك',
    'en': 'Choose the nearest city',
    'fr': 'Choisissez la ville la plus proche'
  },
  'search': {'ar': 'ابحث...', 'en': 'Search...', 'fr': 'Rechercher...'},
  'gpsDenied': {
    'ar': 'لم يُسمح بالوصول إلى الموقع. اختر مدينتك يدوياً.',
    'en': 'Location permission denied. Pick your city manually.',
    'fr': 'Localisation refusee. Choisissez votre ville manuellement.'
  },
  'gpsFailed': {
    'ar': 'تعذر تحديد الموقع الآن. اختر مدينتك يدوياً.',
    'en': 'Could not get a location fix. Pick your city manually.',
    'fr': 'Position introuvable. Choisissez votre ville manuellement.'
  },
  'todayTitle': {
    'ar': 'مواقيت اليوم',
    'en': "Today's times",
    'fr': "Horaires d'aujourd'hui"
  },
  'editHint': {
    'ar': 'اضغط أي وقت لتعديله يدوياً بما يوافق مسجد حيّك.',
    'en': 'Tap any time to adjust it to your local masjid.',
    'fr': 'Touchez un horaire pour l ajuster a votre mosquee.'
  },
  'adjusted': {
    'ar': 'مُعدّل يدوياً',
    'en': 'Manually adjusted',
    'fr': 'Ajuste manuellement'
  },
  'preAlert': {
    'ar': 'ذكّرني قبل الصلاة بخمس دقائق',
    'en': 'Remind me 5 minutes before prayer',
    'fr': 'Rappel 5 minutes avant la priere'
  },
  'preAlertSub': {
    'ar': 'تنبيه إضافي قبل كل صلاة من الصلوات الخمس',
    'en': 'An extra alert before each of the five prayers',
    'fr': 'Une alerte avant chacune des cinq prieres'
  },
  'adhanSound': {
    'ar': 'صوت الأذان مع التنبيه',
    'en': 'Play the adhan with the alert',
    'fr': "Jouer l'adhan avec l'alerte"
  },
  'adhanSoundSub': {
    'ar': 'يُشغّل الأذان عند دخول وقت كل صلاة (أندرويد).',
    'en': 'Plays the call to prayer when each prayer time enters (Android).',
    'fr': "Joue l'appel a la priere a l'entree de chaque priere (Android)."
  },
  'dndChName': {
    'ar': 'الأذان',
    'en': 'Adhan (prayer call)',
    'fr': "Adhan (appel à la prière)"
  },
  'dndChDesc': {
    'ar':
        'تنبيه الأذان عند دخول وقت كل صلاة، ويتجاوز وضع عدم الإزعاج إن سمحت له بذلك من إعدادات النظام.',
    'en':
        'The call to prayer at each prayer time. It bypasses Do Not Disturb if you grant that access in system settings.',
    'fr':
        "L'appel à la prière à chaque heure de prière. Il outrepasse le mode Ne pas déranger si vous accordez cet accès dans les réglages."
  },
  'dnd': {
    'ar': 'اسمح للأذان بتجاوز عدم الإزعاج',
    'en': 'Let the adhan bypass Do Not Disturb',
    'fr': "Laisser l'adhan outrepasser le mode Ne pas déranger"
  },
  'dndSub': {
    'ar':
        'بدون هذا الإذن يكتم النظام الأذان أثناء وضع عدم الإزعاج. امنح عوّاد «الوصول إلى عدم الإزعاج» ليصلك الأذان في وقته.',
    'en':
        'Without this access the system mutes the adhan during Do Not Disturb. Grant Awwad "Do Not Disturb access" so the adhan still reaches you.',
    'fr':
        "Sans cet accès, le système coupe l'adhan en mode Ne pas déranger. Accordez à Awwad l'accès « Ne pas déranger »."
  },
  'exactAlarm': {
    'ar': 'فعّل دقة المواعيد',
    'en': 'Enable exact timing',
    'fr': "Activer l'heure exacte"
  },
  'exactAlarmSub': {
    'ar':
        'امنح إذن «المنبهات والتذكيرات» ليصل تنبيه الأذان في وقته تماماً دون تأخير من النظام.',
    'en':
        'Grant the "Alarms and reminders" permission so prayer alerts arrive exactly on time.',
    'fr':
        "Accordez l'autorisation « Alarmes et rappels » pour des alertes à l'heure exacte."
  },
  'note': {
    'ar':
        'التذكيرات تصل لأصحاب عادة «المحافظة على الصلاة في وقتها» أو «الاستيقاظ للفجر»، وأذكار الصباح والمساء لأصحاب عادة الأذكار: بعد الفجر بنصف ساعة وبعد العصر بنصف ساعة. الحساب فلكي على جهازك ولا يحتاج إنترنت.',
    'en':
        'Prayer reminders arrive for the pray-on-time or wake-for-Fajr habits; morning and evening adhkar arrive 30 minutes after Fajr and Asr for the adhkar habit. Everything is computed on-device, offline.',
    'fr':
        'Les rappels concernent les habitudes de priere; les adhkar arrivent 30 minutes apres Fajr et Asr. Tout est calcule hors ligne.'
  },
};
