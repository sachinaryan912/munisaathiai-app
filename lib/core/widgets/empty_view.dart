import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = LucideIcons.inbox,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: s.surfaceVariant, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: s.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.headline(s.textPrimary), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: AppTypography.body(s.textMuted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).scaleXY(begin: 0.96, end: 1, curve: Curves.easeOutCubic);
  }
}
