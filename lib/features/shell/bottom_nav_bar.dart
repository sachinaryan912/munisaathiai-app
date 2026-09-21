import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/system_ui.dart';
import '../../core/widgets/app_icon.dart';

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.overlayStyle(dark: dark, navigationBarColor: s.card),
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: AppRadius.xlTop,
          boxShadow: AppShadows.floating(dark),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ...primary.asMap().entries.map((e) => Expanded(
                      child: _NavTab(item: e.value, active: currentIndex == e.key, onTap: () => onTap(e.key)),
                    )),
                if (hasMore)
                  Expanded(
                    child: _NavTab(
                      item: const NavItem(label: 'More', path: '', icon: HugeIcons.strokeRoundedMenuSquare),
                      active: overflowActive,
                      onTap: () => _showMoreSheet(context, overflow, primary.length),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, List<NavItem> overflow, int offset) {
    final s = context.surface;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: AppRadius.xlTop,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Text('More Features', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 10,
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
                          child: Center(child: AppIcon(e.value.icon, color: active ? Colors.white : AppColors.saffron600, size: 21)),
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
              child: AppIcon(item.icon, size: 21, color: color),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: color),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 26 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: active ? AppColors.saffron500 : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
