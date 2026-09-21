import 'package:flutter/material.dart';
import '../theme/app_shadows.dart';

/// The refined iOS Inset Grouped surface used across the app — clean hairline border,
/// subtle ambient diffuse elevation, and squircle corner radius.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(16);

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF161B26) : Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB),
          width: 0.6,
        ),
        boxShadow: AppShadows.soft(dark),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius is BorderRadius ? radius : BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
