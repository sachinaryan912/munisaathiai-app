import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/nav/nav_items.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/system_ui.dart';
import 'bottom_nav_bar.dart';

/// One persistent shell per role — owns the floating bottom-nav bar and the
/// [StatefulNavigationShell]'s IndexedStack of branch navigators, so
/// switching tabs never rebuilds a page from scratch (each branch keeps its
/// own Navigator + scroll position + in-flight state alive underneath).
class RootTabShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<NavItem> items;

  const RootTabShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  @override
  State<RootTabShell> createState() => _RootTabShellState();
}

class _RootTabShellState extends State<RootTabShell> {
  bool _wasOnAiTab = false;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    // The AI chat tab (e.g. Student's "Vidya AI") runs full-screen with its
    // own history/new-chat header — the persistent bottom nav would otherwise
    // still show underneath it since it lives one level up, in this shell.
    final onAiTab =
        widget.items[widget.navigationShell.currentIndex].aiHighlight;

    // IndexedStack keeps every branch's widget tree alive underneath, by
    // design (see class doc) — so leaving this tab never disposes the AI
    // chat screen, and any in-progress speech would otherwise keep playing
    // invisibly in the background. This is the one place that actually sees
    // the tab-index transition, so it's the one place that can catch it.
    if (_wasOnAiTab && !onAiTab) {
      TtsService.instance.stop();
    }
    _wasOnAiTab = onAiTab;

    // AppBottomNavBar paints `s.card` all the way into the bottom safe-area
    // inset (no margin, SafeArea(top: false)), so the system nav bar must
    // match `s.card` there too — matching `s.bg` instead leaves a visible
    // seam between the tab bar and the device's own gesture bar. On the AI
    // tab there's no bottom nav, so the scaffold's `s.bg` reaches the edge.
    SystemUi.apply(
      dark: Theme.of(context).brightness == Brightness.dark,
      navigationBarColor: onAiTab ? s.bg : s.card,
    );
    // Each branch's own Navigator starts empty at its root, so system back has nothing to
    // pop on any tab but the first — without this, back on e.g. the AI chat tab exits the
    // app instead of returning to the dashboard tab, since nothing here intercepts it.
    return PopScope(
      canPop: widget.navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.navigationShell.goBranch(0);
      },
      child: Scaffold(
        backgroundColor: s.bg,
        body: widget.navigationShell,
        bottomNavigationBar: onAiTab
            ? null
            : AppBottomNavBar(
                items: widget.items,
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) => widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                ),
              ),
      ),
    );
  }
}
