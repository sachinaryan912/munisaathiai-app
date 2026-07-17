import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dot;

  const StatusPill({super.key, required this.label, required this.color, this.icon, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: AppTypography.caption(color)),
        ],
      ),
    );
  }
}
