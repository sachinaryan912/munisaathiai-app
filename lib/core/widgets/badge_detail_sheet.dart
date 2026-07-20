import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared badge-detail bottom sheet — used by both the Student dashboard's
/// badge row and the full Progress screen so both present badges identically.
void showBadgeDetail(BuildContext context, Map<String, dynamic> badge) {
  final earned = badge['earned'] as bool? ?? false;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final s = sheetContext.surface;
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: Text(badge['icon'] as String? ?? '🏅', style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 14),
            Text(badge['name'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
            const SizedBox(height: 4),
            Text(earned ? '★ You earned this badge!' : '☆ Not earned yet — keep going!', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron600, letterSpacing: 0.3)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(16)),
              child: Text(badge['desc'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    },
  );
}
