import 'dart:ui';

import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Saturation-boost matrix (s = 1.4): part of the "liquid glass" recipe -
/// the backdrop is blurred AND slightly over-saturated, like iOS glass.
const List<double> _kGlassSaturation = <double>[
  1.3148, -0.2860, -0.0288, 0, 0,
  -0.0852, 1.1140, -0.0288, 0, 0,
  -0.0852, -0.2860, 1.3712, 0, 0,
  0, 0, 0, 1, 0,
];

/// An iOS-style "Liquid Glass" button: it refracts whatever sits behind it
/// (BackdropFilter blur + saturation boost), with a specular top highlight,
/// a luminous hairline border, a floating shadow and a springy press-scale.
class GlassButton extends StatefulWidget {
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
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final neutral = AppColors.isDark ? Colors.white : Colors.black;
    final tint = widget.primary ? AppColors.accent : neutral;
    final fg = widget.primary ? AppColors.heading : AppColors.text;
    final radius = BorderRadius.circular(20);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.965 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            // The shadow lives OUTSIDE the clip so the glass stays crisp.
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: (widget.primary ? AppColors.accent : Colors.black)
                      .withValues(alpha: _pressed ? 0.16 : 0.26),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  outer: const ColorFilter.matrix(_kGlassSaturation),
                  inner: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                ),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tint.withValues(alpha: widget.primary ? 0.30 : 0.10),
                        tint.withValues(alpha: widget.primary ? 0.14 : 0.04),
                      ],
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color:
                          tint.withValues(alpha: widget.primary ? 0.55 : 0.24),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Specular top highlight: the "wet" light edge.
                      Positioned(
                        top: 1,
                        left: 10,
                        right: 10,
                        height: widget.height * 0.46,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: fg),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
