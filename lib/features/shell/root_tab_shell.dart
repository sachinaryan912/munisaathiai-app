import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_theme.dart';
import 'bottom_nav_bar.dart';

/// One persistent shell per role — owns the floating bottom-nav bar and the
/// [StatefulNavigationShell]'s IndexedStack of branch navigators, so
/// switching tabs never rebuilds a page from scratch (each branch keeps its
/// own Navigator + scroll position + in-flight state alive underneath).
class RootTabShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<NavItem> items;

  const RootTabShell({super.key, required this.navigationShell, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    // The AI chat tab (e.g. Student's "Vidya AI") runs full-screen with its
    // own history/new-chat header — the persistent bottom nav would otherwise
    // still show underneath it since it lives one level up, in this shell.
    final onAiTab = items[navigationShell.currentIndex].aiHighlight;
    // Each branch's own Navigator starts empty at its root, so system back has nothing to
    // pop on any tab but the first — without this, back on e.g. the AI chat tab exits the
    // app instead of returning to the dashboard tab, since nothing here intercepts it.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: s.bg,
        body: navigationShell,
        bottomNavigationBar: onAiTab
            ? null
            : AppBottomNavBar(
                items: items,
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
              ),
      ),
    );
  }
}
