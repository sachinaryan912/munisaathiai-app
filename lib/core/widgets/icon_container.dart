import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

/// The "icon in a tinted rounded box" pattern repeated ad-hoc across stat
/// tiles, list rows, and headers — one reusable widget instead of a fresh
/// `Container(decoration: BoxDecoration(...))` at every call site.
class AppIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;

  const AppIconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
    this.iconSize = 18,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
