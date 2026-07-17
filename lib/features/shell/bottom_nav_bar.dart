import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';

/// The floating tab bar every role shell renders — a flat rounded card where
/// only the active tab's icon+label change color (no background chip).
/// Driven by a branch index (not a route path), so switching tabs never
/// rebuilds a page from scratch — [onTap] is expected to call
/// `navigationShell.goBranch()`.
class AppBottomNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = items.length > 4 ? items.take(4).toList() : items;
    final overflow = items.length > 4 ? items.skip(4).toList() : const <NavItem>[];
    final hasMore = overflow.isNotEmpty;
    final overflowActive = currentIndex >= 4;

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: AppRadius.xlTop,
          boxShadow: AppShadows.floating(dark),
        ),
        child: Row(
          children: [
            ...primary.asMap().entries.map((e) => Expanded(
                  child: _NavTab(item: e.value, active: currentIndex == e.key, onTap: () => onTap(e.key)),
                )),
            if (hasMore)
              Expanded(
                child: _NavTab(
                  item: const NavItem(label: 'More', path: '', icon: LucideIcons.grid2x2),
                  active: overflowActive,
                  onTap: () => _showMoreSheet(context, overflow, primary.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, List<NavItem> overflow, int offset) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(color: s.card, borderRadius: AppRadius.xlTop),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: s.border, borderRadius: AppRadius.pillAll)),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: overflow.asMap().entries.map((e) {
                  final globalIndex = offset + e.key;
                  final active = currentIndex == globalIndex;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onTap(globalIndex);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: active ? AppColors.saffron500 : AppColors.saffron50, borderRadius: BorderRadius.circular(16)),
                          child: Icon(e.value.icon, color: active ? Colors.white : AppColors.saffron600, size: 21),
                        ),
                        const SizedBox(height: 8),
                        Text(e.value.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavTab extends StatelessWidget {
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavTab({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final color = active ? AppColors.saffron500 : s.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (!active) HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(item.icon, size: 21, color: color),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: color),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
