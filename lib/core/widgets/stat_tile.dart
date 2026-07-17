import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: s.textPrimary, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: s.textSecondary)),
          if (sublabel != null) ...[
            const SizedBox(height: 1),
            Text(sublabel!, style: TextStyle(fontSize: 11, color: s.textMuted)),
          ],
        ],
      ),
    ).animate(delay: (animateIndex * 60).ms).fadeIn(duration: 320.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
