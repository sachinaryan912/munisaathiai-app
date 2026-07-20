import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_provider.dart';
import '../notifications/notifications_provider.dart';
import '../parent/selected_child_provider.dart';
import 'custom_app_bar.dart';
import 'dashboard_app_bar.dart';

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
  final bool isDashboard;
  final String? dashboardSubtitle;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showAiFab = true,
    this.isDashboard = false,
    this.dashboardSubtitle,
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
    return Scaffold(
      appBar: widget.title == 'Vidya AI'
          ? null
          : (widget.isDashboard
              ? DashboardAppBar(subtitle: widget.dashboardSubtitle)
              : CustomAppBar(title: widget.title, actions: widget.actions)),
      body: widget.body,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: widget.floatingActionButton ??
          (widget.showAiFab
              ? FloatingActionButton(
                  heroTag: 'ai_fab',
                  backgroundColor: AppColors.saffron500,
                  elevation: 6,
                  onPressed: () => context.push('/ai-chat'),
                  child: const Icon(LucideIcons.bot, color: Colors.white),
                )
              : null),
    );
  }
}
