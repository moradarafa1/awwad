import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import 'package:awwad/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/catalog/badge_catalog.dart';

Future<void> showBadgeCelebration(BuildContext context, BadgeDef def) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _BadgeCelebrationDialog(def: def),
  );
}

class _BadgeCelebrationDialog extends StatefulWidget {
  final BadgeDef def;
  const _BadgeCelebrationDialog({required this.def});
  @override
  State<_BadgeCelebrationDialog> createState() =>
      _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<_BadgeCelebrationDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.accent3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.def.icon, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(l10n.badgeCongrats,
                    style: TextStyle(
                        color: AppColors.accent3,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Text(widget.def.t(locale),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.heading)),
                const SizedBox(height: 8),
                Text(widget.def.d(locale),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 24,
          colors: [
            AppColors.accent,
            AppColors.accent2,
            AppColors.accent3,
            AppColors.success,
          ],
        ),
      ],
    );
  }
}
