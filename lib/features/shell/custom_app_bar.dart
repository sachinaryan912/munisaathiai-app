import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../action_plans/action_plan_sheet.dart';
import '../auth/data/auth_provider.dart';
import '../notifications/notification_panel.dart';
import '../notifications/notifications_provider.dart';

/// A fully custom replacement for Material's [AppBar] — a frosted-glass bar
/// with pill-shaped chrome buttons (theme toggle, notifications, avatar) and
/// a rounded back button on pushed pages, instead of a flat toolbar with
/// plain [IconButton]s.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? 'STUDENT';
    final notifs = context.watch<NotificationsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final canPop = Navigator.of(context).canPop();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: s.bg.withValues(alpha: dark ? 0.7 : 0.75),
            border: Border(bottom: BorderSide(color: s.border.withValues(alpha: 0.7))),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: _height,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  if (canPop)
                    _ChromeButton(icon: LucideIcons.chevronLeft, onTap: () => Navigator.of(context).maybePop())
                  else
                    const SizedBox(width: 2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: title.isEmpty
                        ? const SizedBox.shrink()
                        : Text(title, style: AppTypography.title(s.textPrimary), overflow: TextOverflow.ellipsis),
                  ),
                  ...(actions ?? []),
                  _ChromeButton(
                    icon: themeProvider.isDark ? LucideIcons.sun : LucideIcons.moon,
                    onTap: themeProvider.toggle,
                  ),
                  const SizedBox(width: 8),
                  _ChromeButton(
                    icon: LucideIcons.clipboardList,
                    onTap: () => showMyActionPlansSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _ChromeButton(
                    icon: LucideIcons.bell,
                    onTap: () => showNotificationPanel(context),
                    badge: notifs.unreadCount > 0,
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: UserAvatar(
                      size: 36,
                      fontSize: 12,
                      border: Border.all(color: s.bg, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.roleColor(role).withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _ChromeButton({required this.icon, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: s.surfaceVariant, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: s.textSecondary),
              ),
              if (badge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: AppColors.saffron500, shape: BoxShape.circle, border: Border.all(color: s.bg, width: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
