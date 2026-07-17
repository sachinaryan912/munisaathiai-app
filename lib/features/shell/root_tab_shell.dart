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
    return Scaffold(
      backgroundColor: s.bg,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
