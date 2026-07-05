import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Ambient backdrop used behind every screen: the dark base with soft radial
/// color glows (teal / blue / green). Pure gradients - no blur, no filters -
/// so it is cheap on every device, while giving the liquid-glass surfaces
/// above it something to refract.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Softer glows on the light theme so text contrast never suffers.
    final k = AppColors.isDark ? 1.0 : 0.55;
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.bg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            right: -90,
            child: _Glow(color: AppColors.accent2, size: 360, alpha: 0.16 * k),
          ),
          Positioned(
            top: 220,
            left: -150,
            child: _Glow(color: AppColors.accent, size: 320, alpha: 0.12 * k),
          ),
          Positioned(
            bottom: -170,
            right: 30,
            child: _Glow(color: AppColors.success, size: 340, alpha: 0.10 * k),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.alpha});

  final Color color;
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
