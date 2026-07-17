import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/data/auth_provider.dart';
import '../notifications/notification_panel.dart';
import '../notifications/notifications_provider.dart';
import '../parent/selected_child_provider.dart';

/// The per-page chrome (app bar + FAB) every role-scoped page composes
/// itself into — analogous to the web app's `<DashboardLayout title="...">`
/// wrapper. The persistent bottom-nav bar itself lives one level up, in
/// [RootTabShell], so it survives tab switches instead of rebuilding.
class AppShell extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAiFab;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showAiFab = true,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
      final role = context.read<AuthProvider>().user?.role;
      if (role == 'PARENT') context.read<SelectedChildProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? 'STUDENT';
    final notifs = context.watch<NotificationsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ...(widget.actions ?? []),
          IconButton(
            icon: Icon(themeProvider.isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
            onPressed: themeProvider.toggle,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 20),
                onPressed: () => showNotificationPanel(context),
              ),
              if (notifs.unreadCount > 0)
                Positioned(
                  top: 11,
                  right: 11,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.saffron500, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5))),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.roleColor(role),
                child: Text(auth.user?.initials ?? 'U', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      body: widget.body,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: widget.floatingActionButton ??
          (widget.showAiFab
              ? FloatingActionButton(
                  heroTag: 'ai_fab',
                  backgroundColor: AppColors.saffron500,
                  elevation: 6,
                  onPressed: () => context.push('/ai-chat'),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white),
                )
              : null),
    );
  }
}
