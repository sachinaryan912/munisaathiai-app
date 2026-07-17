import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_card.dart';

class QuickAccessCard extends StatelessWidget {
  final String route;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String cta;

  const QuickAccessCard({
    super.key,
    required this.route,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SectionCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: s.textSecondary, height: 1.3, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(cta, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 3),
              Icon(LucideIcons.chevronRight, size: 12, color: color),
            ],
          ),
        ],
      ),
    );
  }
}
