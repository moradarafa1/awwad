import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// A simple, flat pill button used on the onboarding (language) and the
/// sign-in / guest screens. It mirrors the habit-switcher chip look: a light
/// tinted fill, a thin colored border, and clear text. Deliberately flat -
/// no backdrop blur, no specular highlight, no heavy shadow.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
    this.height = 54,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = primary
        ? AppColors.accent.withValues(alpha: 0.16)
        : AppColors.surface;
    final borderColor =
        primary ? AppColors.accent : AppColors.border;
    final fg = primary ? AppColors.heading : AppColors.text;
    final radius = BorderRadius.circular(16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: primary ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: primary ? AppColors.accent : fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
