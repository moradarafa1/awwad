import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/content/dhikr.dart';
import '../../core/notifications/notifications.dart';
import '../../core/notifications/notif_scheduler.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_screen.dart';
import '../phone/usage_screen.dart';
import '../shield/dns_shield_screen.dart';
import 'fields_manager_screen.dart';
import 'habits_screen.dart';
import 'profile_screen.dart';

const _linkedInUrl = 'https://www.facebook.com/MoradArafaOfficial/';

// Share links per platform. The Play link is deterministic (package id) and
// starts working the moment the app is published; the App Store link is a
// TODO until Apple assigns an id - until then iOS shares the website.
const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.awwad.awwad';
// TODO(stores): replace with the real App Store URL after iOS publishing.
const _appStoreUrl = 'https://moradarafa1.github.io/';
const _siteUrl = 'https://moradarafa1.github.io/';

String shareLinkForPlatform() {
  if (kIsWeb) return _siteUrl;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return _playStoreUrl;
    case TargetPlatform.iOS:
      return _appStoreUrl;
    default:
      return _siteUrl;
  }
}

const Map<String, Map<String, String>> _kSet = {
  'darkMode': {'ar': 'الوضع الداكن', 'en': 'Dark mode', 'fr': 'Mode sombre'},
  'darkModeSub': {
    'ar': 'أطفئه للتبديل إلى الوضع الفاتح',
    'en': 'Turn off to switch to the light theme',
    'fr': 'Désactivez pour passer au thème clair'
  },
  'notif': {'ar': 'الإشعارات', 'en': 'Notifications', 'fr': 'Notifications'},
  'notifSub': {
    'ar': 'تذكير يومي وتهنئة بالأوسمة',
    'en': 'Daily reminder and badge congratulations',
    'fr': 'Rappel quotidien et félicitations'
  },
  'dhikr': {'ar': 'ذكر الصباح اليومي', 'en': 'Daily morning dhikr', 'fr': 'Dhikr du matin'},
  'dhikrSub': {
    'ar': 'الصلاة الإبراهيمية كما في صحيح مسلم',
    'en': 'The Ibrahimic prayer as in Sahih Muslim',
    'fr': "La prière ibrahimique (Sahih Muslim)"
  },
  'profile': {'ar': 'ملفّي وأوسمتي', 'en': 'My profile & badges', 'fr': 'Mon profil et badges'},
  'habits': {'ar': 'العادات', 'en': 'Habits', 'fr': 'Habitudes'},
  'permDenied': {
    'ar': 'الإشعارات غير مسموح بها. فعّلها لعوّاد من إعدادات النظام.',
    'en': 'Notifications are blocked. Enable them for Awwad in system settings.',
    'fr': "Les notifications sont bloquées. Activez-les pour Awwad dans les réglages système."
  },
  'share': {
    'ar': 'شارك عوّاد مع من تحب',
    'en': 'Share Awwad with someone',
    'fr': 'Partager Awwad'
  },
  'shareCopied': {
    'ar': 'تم نسخ رابط عوّاد. الصقه في أي محادثة.',
    'en': 'Awwad link copied. Paste it anywhere.',
    'fr': 'Lien copié. Collez-le où vous voulez.'
  },
  'shareMsg': {
    'ar': 'جرّب تطبيق «عوّاد»: رفيقك لكسر العادات السيئة وبناء عادات حسنة.',
    'en': 'Try "Awwad": your companion to break bad habits and build good ones.',
    'fr': "Essayez « Awwad » : votre compagnon pour briser les mauvaises habitudes et en bâtir de bonnes."
  },
  'contact': {
    'ar': 'تواصل معنا',
    'en': 'Contact us',
    'fr': 'Nous contacter'
  },
  'privacy': {
    'ar': 'سياسة الخصوصية',
    'en': 'Privacy policy',
    'fr': 'Politique de confidentialité'
  },
  'version': {
    'ar': 'الإصدار',
    'en': 'Version',
    'fr': 'Version'
  },
  'yourAccount': {
    'ar': 'حسابك',
    'en': 'Your account',
    'fr': 'Votre compte'
  },
  'createOrSignIn': {
    'ar': 'إنشاء حساب / تسجيل الدخول',
    'en': 'Create account / Sign in',
    'fr': 'Créer un compte / Se connecter'
  },
  'accountSub': {
    'ar': 'سجّل الدخول كي تتزامن بياناتك على جميع أجهزتك.',
    'en': 'Sign in so your data syncs across all your devices.',
    'fr': 'Connectez-vous pour synchroniser vos données sur tous vos appareils.'
  },
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);
    final ctrl = ref.read(appControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.settingsTitle,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),

          // language
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.language,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _lang('العربية', 'ar', s.settings.locale, ctrl),
                    const SizedBox(width: 8),
                    _lang('English', 'en', s.settings.locale, ctrl),
                    const SizedBox(width: 8),
                    _lang('Français', 'fr', s.settings.locale, ctrl),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // account (right after language): reactive to auth state so it
          // shows the real session even when it is restored asynchronously.
          if (SupabaseService.configured) ...[
            ValueListenableBuilder<int>(
              valueListenable: SupabaseService.authRevision,
              builder: (context, _, child) => _accountCard(context, loc),
            ),
            const SizedBox(height: 12),
          ],

          // appearance: dark / light mode
          SectionCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.settings.darkMode,
              activeThumbColor: AppColors.accent,
              title: Text(_set('darkMode', loc),
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(_set('darkModeSub', loc),
                  style:
                      TextStyle(fontSize: 11, color: AppColors.muted)),
              secondary: Icon(
                  s.settings.darkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: AppColors.accent2),
              onChanged: (v) => ctrl.setDarkMode(v),
            ),
          ),
          const SizedBox(height: 12),

          // notifications + reminders + dhikr + religious content
          SectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.settings.notificationsEnabled,
                  activeThumbColor: AppColors.accent,
                  title: Text(_set('notif', loc),
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(_set('notifSub', loc),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                  onChanged: (v) async {
                    // Turning ON: request OS permission first (skip on web,
                    // where notifications are a no-op). If denied, stay off.
                    if (v && !kIsWeb) {
                      final granted = await ensureNotificationPermission();
                      if (!granted) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_set('permDenied', loc))));
                        }
                        return;
                      }
                    }
                    await ctrl.setNotificationsEnabled(v);
                    await _applySchedule(ref, loc);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.settings.dhikrEnabled,
                  activeThumbColor: AppColors.accent,
                  title: Text(_set('dhikr', loc),
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(_set('dhikrSub', loc),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.muted)),
                  onChanged: (v) async {
                    await ctrl.setDhikrEnabled(v);
                    await _applySchedule(ref, loc);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.settings.showReligiousContent,
                  activeThumbColor: AppColors.accent,
                  title: Text(l10n.showReligiousContent,
                      style: const TextStyle(fontSize: 13)),
                  onChanged: (v) async {
                    await ctrl.setShowReligiousContent(v);
                    await _applySchedule(ref, loc);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // badges + habits management (account moved up under language)
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.workspace_premium_outlined,
                      color: AppColors.accent),
                  title: Text(_set('profile', loc),
                      style: const TextStyle(fontSize: 13)),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ProfileScreen())),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.flag_outlined, color: AppColors.accent),
                  title: Text(_set('habits', loc),
                      style: const TextStyle(fontSize: 13)),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HabitsScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // content shield + phone usage (protection tools)
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shield_outlined,
                      color: AppColors.accent2),
                  title: Text(
                      dnsShieldTitle(
                          Localizations.localeOf(context).languageCode),
                      style: const TextStyle(fontSize: 13)),
                  trailing:
                      Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const DnsShieldScreen())),
                ),
                if (!kIsWeb) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.timelapse, color: AppColors.accent2),
                    title: Text(usageScreenTitle(loc),
                        style: const TextStyle(fontSize: 13)),
                    trailing:
                        Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const UsageScreen())),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // personalization
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tune, color: AppColors.accent),
              title:
                  Text(l10n.customizeFields, style: const TextStyle(fontSize: 13)),
              trailing: Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const FieldsManagerScreen())),
            ),
          ),
          const SizedBox(height: 12),

          // data actions
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download_outlined,
                      color: AppColors.accent2),
                  title: Text(l10n.exportData,
                      style: const TextStyle(fontSize: 13)),
                  onTap: () => _export(context, ref),
                ),
                const Divider(),
                // NOTE (owner decision 2026-07-12): NO in-app delete-account
                // entry. Store policy is satisfied by the website's
                // delete-account page, which the store listing links to.
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline,
                      color: AppColors.danger),
                  title: Text(l10n.resetData,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.danger)),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // community & support (share / contact / privacy)
          SectionCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.ios_share, color: AppColors.accent),
                  title: Text(_set('share', loc),
                      style: const TextStyle(fontSize: 13)),
                  onTap: () async {
                    final text =
                        '${_set('shareMsg', loc)}\n${shareLinkForPlatform()}';
                    try {
                      // Native OS share sheet (WhatsApp, Telegram, etc.).
                      await SharePlus.instance
                          .share(ShareParams(text: text));
                    } catch (_) {
                      // Fallback (e.g. desktop web browsers without the
                      // Web Share API): copy the message instead.
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(_set('shareCopied', loc))));
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.mail_outline, color: AppColors.accent),
                  title: Text(_set('contact', loc),
                      style: const TextStyle(fontSize: 13)),
                  onTap: () => _openUrl(
                      'mailto:moradarafa600@gmail.com?subject=عوّاد'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: AppColors.accent),
                  title: Text(_set('privacy', loc),
                      style: const TextStyle(fontSize: 13)),
                  onTap: () =>
                      _openUrl('https://moradarafa1.github.io/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // about + attribution footer
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(l10n.appName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.heading)),
                Text(l10n.slogan,
                    style: TextStyle(
                        color: AppColors.accent2, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${_set('version', loc)} 1.0.0',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 10.5)),
                const SizedBox(height: 12),
                Text(l10n.medicalDisclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 11, height: 1.5)),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('© جميع الحقوق محفوظة، ',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    InkWell(
                      onTap: _openLinkedIn,
                      child: Text('Morad Arafa',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _set(String key, String loc) =>
      _kSet[key]?[loc] ?? _kSet[key]?['ar'] ?? key;

  /// Account card, reactive to auth state (built inside a ValueListenableBuilder
  /// on SupabaseService.authRevision). Signed in -> «حسابك» opening the account
  /// screen; signed out -> create-account / sign-in entry.
  Widget _accountCard(BuildContext context, String loc) {
    final signedIn = SupabaseService.signedIn;
    final email = signedIn ? (SupabaseService.currentUser?.email ?? '') : '';
    return SectionCard(
      child: signedIn
          ? ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.account_circle_outlined,
                  color: AppColors.accent2),
              title: Text(_set('yourAccount', loc),
                  style: const TextStyle(fontSize: 13)),
              subtitle: email.isEmpty
                  ? null
                  : Text(email,
                      textDirection: TextDirection.ltr,
                      style:
                          TextStyle(fontSize: 11, color: AppColors.muted)),
              trailing:
                  Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            )
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.cloud_outlined, color: AppColors.accent),
              title: Text(_set('createOrSignIn', loc),
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(_set('accountSub', loc),
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
              trailing:
                  Icon(Icons.chevron_right, color: AppColors.muted),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AuthScreen(startInSignUp: true))),
            ),
    );
  }

  Future<void> _applySchedule(WidgetRef ref, String loc) async {
    final state = ref.read(appControllerProvider);
    final st = state.settings;
    await applyNotificationSchedule(
      enabled: st.notificationsEnabled,
      habitReminders: habitRemindersFor(state.habits, loc),
      dhikrEnabled: st.dhikrEnabled,
      showReligious: st.showReligiousContent,
      dhikrHour: st.dhikrHour,
      dhikrTitle: kDhikrTitle[loc] ?? kDhikrTitle['ar']!,
    );
  }

  Widget _lang(
      String label, String code, String? current, AppController ctrl) {
    final sel = current == code;
    return Expanded(
      child: ChoiceChipTile(
        label: label,
        selected: sel,
        onTap: () => ctrl.setLocale(code),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLinkedIn() => _openUrl(_linkedInUrl);

  // Message language follows the RESOLVED UI locale (system-derived when the
  // user never picked one), not settings.locale which stays null by default.
  String _sync(String key, BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode;
    return _kSyncErr[key]![loc] ?? _kSyncErr[key]!['ar']!;
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appControllerProvider);
    final data = {
      'habits': s.habits.map((h) => h.toJson()).toList(),
      'entries': s.entries.map((e) => e.toJson()).toList(),
      'badges': s.badges.map((b) => b.toJson()).toList(),
    };
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    AnalyticsService.instance.track('data_exported', {'format': 'json'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sync('exported', context))),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.resetData),
        content: Text(l10n.resetConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appControllerProvider.notifier).resetAll();
    }
  }
}

// Localized sync feedback: raw exceptions must never be shown to users.
const Map<String, Map<String, String>> _kSyncErr = {
  'network': {
    'ar': 'تعذّر الاتصال بالخادم. تأكّد من اتصالك بالإنترنت ثم أعد المحاولة.',
    'en': 'Could not reach the server. Check your internet connection and try again.',
    'fr': 'Impossible de joindre le serveur. Vérifiez votre connexion internet puis réessayez.',
  },
  'generic': {
    'ar': 'حدث خطأ غير متوقّع. أعد المحاولة لاحقاً.',
    'en': 'Something went wrong. Please try again later.',
    'fr': "Une erreur s'est produite. Réessayez plus tard.",
  },
  'syncedOk': {
    'ar': 'تمت المزامنة ✅',
    'en': 'Synced ✅',
    'fr': 'Synchronisé ✅',
  },
  'exported': {
    'ar': 'تم نسخ بياناتك (JSON) إلى الحافظة ✅',
    'en': 'Your data (JSON) was copied to the clipboard ✅',
    'fr': 'Vos données (JSON) ont été copiées dans le presse-papiers ✅',
  },
};
