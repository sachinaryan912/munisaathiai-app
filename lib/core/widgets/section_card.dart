import 'package:flutter/material.dart';
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
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.045), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: card),
    );
  }
}
