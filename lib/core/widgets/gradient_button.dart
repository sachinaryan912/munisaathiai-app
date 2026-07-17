import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [AppColors.saffron500, AppColors.saffron400, AppColors.saffron300];
    final disabled = onPressed == null || loading;

    return AnimatedOpacity(
      opacity: disabled && loading ? 0.85 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: disabled ? null : onPressed,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: disabled && !loading ? [Colors.grey.shade400, Colors.grey.shade400] : gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 19),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
