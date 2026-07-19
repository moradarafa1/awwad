import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/catalog/badge_catalog.dart';
import '../../core/cloud/net_errors.dart';
import '../../core/cloud/supabase_service.dart';
import '../../core/state/app_state.dart';
import '../auth/auth_screen.dart';

/// Profile: shows who the user is (signed in vs guest) and, prominently, their
/// highest earned shield + all earned badges. Reachable from Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _tierRank = {
    'bronze': 0,
    'silver': 1,
    'gold': 2,
    'diamond': 3,
    'special': 2,
  };

  Color _tierColor(String tier) {
    switch (tier) {
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return AppColors.accent3;
      case 'diamond':
        return AppColors.accent2;
      case 'special':
        return const Color(0xFFA78BFA);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _s(Map<String, String> m, String loc) => m[loc] ?? m['ar'] ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = Localizations.localeOf(context).languageCode;
    final s = ref.watch(appControllerProvider);

    // Earned badge keys across ALL habits (union), newest first by earnedAt.
    final earned = [...s.badges]..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    final earnedKeys = <String>{for (final b in earned) b.badgeKey};
    final earnedDefs = earnedKeys
        .map(badgeByKey)
        .whereType<BadgeDef>()
        .toList()
      ..sort((a, b) =>
          (_tierRank[b.tier] ?? 0).compareTo(_tierRank[a.tier] ?? 0));
    final topBadge = earnedDefs.isEmpty ? null : earnedDefs.first;

    final signedIn = SupabaseService.configured && SupabaseService.signedIn;
    final email = signedIn ? (SupabaseService.currentUser?.email ?? '') : '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(_s(_kStr['title']!, loc)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // identity
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                    child: Icon(signedIn ? Icons.person : Icons.person_outline,
                        color: AppColors.accent, size: 38),
                  ),
                  const SizedBox(height: 10),
                  Text(signedIn ? email : _s(_kStr['guest']!, loc),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.heading)),
                  Text(
                      signedIn
                          ? _s(_kStr['synced']!, loc)
                          : _s(_kStr['guestSub']!, loc),
                      style:
                          TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!signedIn && SupabaseService.configured)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen())),
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(_s(_kStr['signin']!, loc)),
              ),
            if (signedIn) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock_outline,
                          color: AppColors.accent),
                      title: Text(_s(_kAcc['changePw']!, loc),
                          style: const TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.chevron_right,
                          color: AppColors.muted),
                      onTap: () => _changePassword(context, loc),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: AppColors.muted),
                      title: Text(_s(_kAcc['signOut']!, loc),
                          style: const TextStyle(fontSize: 14)),
                      onTap: () => _signOut(context, loc),
                    ),
                    const Divider(height: 1),
                    // Store policy (Play account deletion + Apple 5.1.1(v)):
                    // deletion must be reachable IN THE APP, not only on the
                    // website. Two confirmations: it is irreversible.
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: AppColors.danger),
                      title: Text(_s(_kAcc['deleteAcc']!, loc),
                          style: TextStyle(
                              fontSize: 14, color: AppColors.danger)),
                      subtitle: Text(_s(_kAcc['deleteAccSub']!, loc),
                          style: TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                      onTap: () => _deleteAccount(context, ref, loc),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // featured shield
            _featuredShield(loc, topBadge, earnedKeys.length),
            const SizedBox(height: 20),

            // all badges
            Text(_s(_kStr['myBadges']!, loc),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            // Fixed-WIDTH cells in a Wrap, not a fixed-aspect grid: a pinned
            // cell height cannot grow with the OS font scale and clipped the
            // badge labels (see badges_screen for the same fix).
            LayoutBuilder(builder: (context, c) {
              final cellW = (c.maxWidth - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kBadges.map((b) {
                  final got = earnedKeys.contains(b.key);
                  final color = _tierColor(b.tier);
                  return SizedBox(
                    width: cellW,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: got
                            ? color.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: got ? color : AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                              opacity: got ? 1 : 0.3,
                              child: Text(b.icon,
                                  style: const TextStyle(fontSize: 30))),
                          const SizedBox(height: 6),
                          Text(b.t(loc),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: got
                                      ? AppColors.heading
                                      : AppColors.muted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, String loc) async {
    final ctrl = TextEditingController();
    var obscure = true;
    final newPass = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(_s(_kAcc['changePw']!, loc),
              style: TextStyle(color: AppColors.heading)),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: _s(_kAcc['newPw']!, loc),
              suffixIcon: IconButton(
                onPressed: () => setLocal(() => obscure = !obscure),
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.muted),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_s(_kAcc['cancel']!, loc))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: Text(_s(_kAcc['save']!, loc))),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (newPass == null) return;
    if (newPass.length < 6) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s(_kAcc['tooShort']!, loc))));
      }
      return;
    }
    try {
      await SupabaseService.changePassword(newPass);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_s(_kAcc['done']!, loc))));
      }
    } catch (e) {
      if (context.mounted) {
        final key = isNetworkError(e) ? 'errNetwork' : 'errGeneric';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_s(_kAcc[key]!, loc))));
      }
    }
  }

  Future<void> _signOut(BuildContext context, String loc) async {
    await SupabaseService.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_s(_kAcc['signedOut']!, loc))));
      Navigator.of(context).maybePop();
    }
  }

  /// Irreversible account deletion, in-app (store requirement). Confirms
  /// twice, calls the edge function with the caller's JWT, then wipes the
  /// device so no orphan copy of the data survives locally.
  Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref, String loc) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_s(_kAcc['deleteAcc']!, loc),
            style: TextStyle(fontSize: 16, color: AppColors.danger)),
        content: Text(_s(_kAcc['deleteBody']!, loc),
            style: const TextStyle(fontSize: 13.5, height: 1.7)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_s(_kAcc['cancel']!, loc))),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_s(_kAcc['deleteConfirm']!, loc))),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    // Second gate: the first tap can be a mis-tap; this one cannot.
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Text(_s(_kAcc['deleteSure']!, loc),
            style: const TextStyle(fontSize: 13.5, height: 1.7)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_s(_kAcc['cancel']!, loc))),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_s(_kAcc['deleteFinal']!, loc))),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await SupabaseService.deleteAccount();
      // The cloud rows are gone; the local copy must go too, otherwise the
      // next sign-in would push the deleted data straight back up.
      await ref.read(appControllerProvider.notifier).resetAll();
      messenger.showSnackBar(
          SnackBar(content: Text(_s(_kAcc['deleted']!, loc))));
      navigator.maybePop();
    } catch (e) {
      final key = isNetworkError(e) ? 'errNetwork' : 'errGeneric';
      messenger.showSnackBar(SnackBar(
          content: Text(_s(_kAcc[key]!, loc)),
          backgroundColor: AppColors.danger));
    }
  }

  Widget _featuredShield(String loc, BadgeDef? top, int count) {
    if (top == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(_s(_kStr['noBadges']!, loc),
                  style: TextStyle(
                      color: AppColors.muted, height: 1.5, fontSize: 13)),
            ),
          ],
        ),
      );
    }
    final color = _tierColor(top.tier);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.06),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Text(top.icon, style: const TextStyle(fontSize: 46)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_s(_kStr['topShield']!, loc),
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(top.t(loc),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.heading)),
                const SizedBox(height: 4),
                Text('${_s(_kStr['earnedCount']!, loc)}: $count / ${kBadges.length}',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const Map<String, Map<String, String>> _kStr = {
  'title': {'ar': 'ملفّي', 'en': 'My profile', 'fr': 'Mon profil'},
  'guest': {'ar': 'زائر', 'en': 'Guest', 'fr': 'Invité'},
  'guestSub': {
    'ar': 'بياناتك محفوظة على هذا الجهاز فقط',
    'en': 'Your data is saved on this device only',
    'fr': 'Vos données sont enregistrées sur cet appareil uniquement'
  },
  'synced': {
    'ar': 'حسابك مُزامَن عبر أجهزتك',
    'en': 'Your account is synced across devices',
    'fr': 'Votre compte est synchronisé'
  },
  'signin': {
    'ar': 'سجّل الدخول لحفظ تقدّمك',
    'en': 'Sign in to save your progress',
    'fr': 'Connectez-vous pour sauvegarder'
  },
  'topShield': {'ar': 'أعلى درعٍ حصلت عليه', 'en': 'Your top shield', 'fr': 'Votre meilleur bouclier'},
  'earnedCount': {'ar': 'الأوسمة', 'en': 'Badges', 'fr': 'Badges'},
  'myBadges': {'ar': 'أوسمتي', 'en': 'My badges', 'fr': 'Mes badges'},
  'noBadges': {
    'ar': 'لم تحصل على أوسمة بعد. سجّل أيامك لتكسب أوّل درع.',
    'en': 'No badges yet. Log your days to earn your first shield.',
    'fr': "Pas encore de badges. Enregistrez vos jours pour gagner votre premier bouclier."
  },
};

const Map<String, Map<String, String>> _kAcc = {
  'changePw': {'ar': 'تغيير كلمة المرور', 'en': 'Change password', 'fr': 'Changer le mot de passe'},
  'newPw': {'ar': 'كلمة المرور الجديدة', 'en': 'New password', 'fr': 'Nouveau mot de passe'},
  'save': {'ar': 'حفظ', 'en': 'Save', 'fr': 'Enregistrer'},
  'cancel': {'ar': 'إلغاء', 'en': 'Cancel', 'fr': 'Annuler'},
  'tooShort': {
    'ar': 'كلمة المرور يجب ألا تقل عن ٦ أحرف',
    'en': 'Password must be at least 6 characters',
    'fr': 'Le mot de passe doit comporter au moins 6 caractères'
  },
  'done': {'ar': 'تم تغيير كلمة المرور ✅', 'en': 'Password changed ✅', 'fr': 'Mot de passe changé ✅'},
  'signOut': {'ar': 'تسجيل الخروج', 'en': 'Sign out', 'fr': 'Se déconnecter'},
  'signedOut': {'ar': 'تم تسجيل الخروج', 'en': 'Signed out', 'fr': 'Déconnecté'},
  'deleteAcc': {
    'ar': 'حذف الحساب نهائياً',
    'en': 'Delete account permanently',
    'fr': 'Supprimer le compte définitivement'
  },
  'deleteAccSub': {
    'ar': 'يمحو حسابك وكل بياناتك من التطبيق والخوادم.',
    'en': 'Erases your account and all your data from the app and our servers.',
    'fr': 'Efface votre compte et toutes vos données de l\'application et des serveurs.'
  },
  'deleteBody': {
    'ar':
        'سيُحذف حسابك وكل ما يتعلق به: عاداتك وسجلّك اليومي وأوسمتك وبياناتك الشخصية، من هذا الجهاز ومن خوادمنا معاً. لا يمكن التراجع عن هذه الخطوة ولا استعادة البيانات بعدها.',
    'en':
        'Your account and everything tied to it will be deleted: your habits, daily log, badges, and personal data, from this device and from our servers. This cannot be undone and the data cannot be recovered.',
    'fr':
        'Votre compte et tout ce qui s\'y rattache seront supprimés : habitudes, journal quotidien, badges et données personnelles, de cet appareil et de nos serveurs. Cette action est irréversible.'
  },
  'deleteConfirm': {'ar': 'متابعة الحذف', 'en': 'Continue', 'fr': 'Continuer'},
  'deleteSure': {
    'ar': 'تأكيد أخير: هل تريد فعلاً حذف حسابك وكل بياناتك؟',
    'en': 'Final confirmation: do you really want to delete your account and all your data?',
    'fr': 'Confirmation finale : voulez-vous vraiment supprimer votre compte et toutes vos données ?'
  },
  'deleteFinal': {'ar': 'نعم، احذف', 'en': 'Yes, delete', 'fr': 'Oui, supprimer'},
  'deleted': {
    'ar': 'تم حذف حسابك وبياناتك نهائياً.',
    'en': 'Your account and data have been permanently deleted.',
    'fr': 'Votre compte et vos données ont été définitivement supprimés.'
  },
  'errNetwork': {
    'ar': 'تعذّر الاتصال بالخادم. تأكّد من اتصالك بالإنترنت ثم أعد المحاولة.',
    'en': 'Could not reach the server. Check your internet connection and try again.',
    'fr': 'Impossible de joindre le serveur. Vérifiez votre connexion internet puis réessayez.'
  },
  'errGeneric': {
    'ar': 'حدث خطأ غير متوقّع. أعد المحاولة لاحقاً.',
    'en': 'Something went wrong. Please try again later.',
    'fr': "Une erreur s'est produite. Réessayez plus tard."
  },
};
