import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// The one recurring "white rounded card with soft shadow" surface used
/// everywhere — stat tiles, list rows, panels.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: AppRadius.lgAll,
        border: dark ? null : Border.all(color: s.border, width: 1),
        boxShadow: AppShadows.soft(dark),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.lgAll,
      child: InkWell(borderRadius: AppRadius.lgAll, onTap: onTap, child: card),
    );
  }
}
