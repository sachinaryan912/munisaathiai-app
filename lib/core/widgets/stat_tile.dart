import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'icon_container.dart';
import 'section_card.dart';

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sublabel;
  final int animateIndex;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sublabel,
    this.animateIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconContainer(icon: icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: AppTypography.display(s.textPrimary).copyWith(fontSize: 24, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: AppTypography.body(s.textSecondary).copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
          if (sublabel != null) ...[
            const SizedBox(height: 1),
            Text(sublabel!, style: AppTypography.caption(s.textMuted).copyWith(fontWeight: FontWeight.w400)),
          ],
        ],
      ),
    ).animate(delay: (animateIndex * 60).ms).fadeIn(duration: 320.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
