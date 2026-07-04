import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// A floating "liquid glass" button (iOS style): translucent gradient fill, a
/// luminous border, a soft drop shadow so it floats, and a subtle top highlight.
/// No BackdropFilter (keeps the CanvasKit preview stable).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tint = primary ? AppColors.accent : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tint.withValues(alpha: primary ? 0.32 : 0.12),
                tint.withValues(alpha: primary ? 0.16 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: tint.withValues(alpha: primary ? 0.6 : 0.26), width: 1),
            boxShadow: [
              BoxShadow(
                color: (primary ? AppColors.accent : Colors.black)
                    .withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 20,
                    color: primary ? AppColors.heading : AppColors.text),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(
                      color: primary ? AppColors.heading : AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
