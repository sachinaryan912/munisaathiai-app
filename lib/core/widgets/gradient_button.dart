import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final List<Color>? colors;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.colors,
    this.height = 54,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.colors ?? [AppColors.saffron500, AppColors.saffron400, AppColors.saffron300];
    final disabled = widget.onPressed == null || widget.loading;

    return AnimatedOpacity(
      opacity: disabled && widget.loading ? 0.85 : 1,
      duration: const Duration(milliseconds: 150),
      child: AnimatedScale(
        scale: _pressed && !disabled ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: disabled ? null : widget.onPressed,
            onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Ink(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: disabled && !widget.loading ? [Colors.grey.shade400, Colors.grey.shade400] : gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.mdAll,
                boxShadow: disabled ? [] : AppShadows.glow(gradientColors.first),
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 19),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
