import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/analytics/analytics.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/cloud/sync_service.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common.dart';
import '../auth/auth_screen.dart';
import 'fields_manager_screen.dart';

const _linkedInUrl = 'https://www.linkedin.com/in/moradarafa/';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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

          // religious content + reminder
          SectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.settings.showReligiousContent,
                  activeThumbColor: AppColors.accent,
                  title: Text(l10n.showReligiousContent,
                      style: const TextStyle(fontSize: 13)),
                  onChanged: ctrl.setShowReligiousContent,
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.reminderTime,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    DropdownButton<int>(
                      value: s.settings.reminderHour,
                      dropdownColor: AppColors.surface,
                      underline: const SizedBox.shrink(),
                      items: List.generate(
                          24,
                          (h) => DropdownMenuItem(
                              value: h,
                              child: Text(
                                  '${h.toString().padLeft(2, '0')}:00'))),
                      onChanged: (v) => ctrl.setReminderHour(v ?? 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // cloud account & sync (only when the build was given Supabase keys)
          if (SupabaseService.configured) ...[
            SectionCard(
              child: SupabaseService.signedIn
                  ? Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sync, color: AppColors.accent2),
                          title: Text(l10n.syncNow,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () => _syncNow(context, ref),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout, color: AppColors.muted),
                          title: Text(l10n.signOut,
                              style: const TextStyle(fontSize: 13)),
                          onTap: () => SupabaseService.signOut(),
                        ),
                      ],
                    )
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_outlined,
                          color: AppColors.accent),
                      title: Text(l10n.syncTitle,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(l10n.syncDesc,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.muted),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AuthScreen())),
                    ),
            ),
            const SizedBox(height: 12),
          ],

          // personalization
          SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune, color: AppColors.accent),
              title:
                  Text(l10n.customizeFields, style: const TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
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
                  leading: const Icon(Icons.download_outlined,
                      color: AppColors.accent2),
                  title: Text(l10n.exportData,
                      style: const TextStyle(fontSize: 13)),
                  onTap: () => _export(context, ref),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_remove_outlined,
                      color: AppColors.danger),
                  title: Text(l10n.deleteAccountTitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.danger)),
                  onTap: () => _confirmDelete(context, ref),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                  title: Text(l10n.resetData,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.danger)),
                  onTap: () => _confirmReset(context, ref),
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
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.heading)),
                Text(l10n.slogan,
                    style: const TextStyle(
                        color: AppColors.accent2, fontSize: 12)),
                const SizedBox(height: 12),
                Text(l10n.medicalDisclaimer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11, height: 1.5)),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('© جميع الحقوق محفوظة — ',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    InkWell(
                      onTap: _openLinkedIn,
                      child: const Text('Morad Arafa',
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

  Future<void> _openLinkedIn() async {
    final uri = Uri.parse(_linkedInUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appControllerProvider);
    try {
      await SyncService.pushAll(
          habit: s.habit, entries: s.entries, survey: s.survey);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تمت المزامنة ✅')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appControllerProvider);
    final data = {
      'habit': s.habit?.toJson(),
      'entries': s.entries.map((e) => e.toJson()).toList(),
      'badges': s.badges.map((b) => b.toJson()).toList(),
    };
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    AnalyticsService.instance.track('data_exported', {'format': 'json'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ بياناتك (JSON) إلى الحافظة ✅')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
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
      AnalyticsService.instance
          .track('account_deletion_requested', {'source': 'in_app'});
      // Cloud path (P2): call account-export-delete edge function, then sign out.
      await ref.read(appControllerProvider.notifier).resetAll();
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
