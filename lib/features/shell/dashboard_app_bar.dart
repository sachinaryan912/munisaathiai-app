import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../auth/data/auth_provider.dart';
import '../management/knowledge_notes_screen.dart';
import '../notifications/notification_panel.dart';
import '../notifications/notifications_provider.dart';

/// A custom, highly polished iOS-style App Bar specifically for Dashboards.
/// Displays an uppercase date, role-specific action icons, a notification bell,
/// role-gradient avatar, and a large, warm greeting header with an optional subtitle.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;

  const DashboardAppBar({super.key, this.subtitle});

  static const double _height = 125;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role ?? 'STUDENT';
    final notifs = context.watch<NotificationsProvider>();

    final fullName = auth.user?.fullName.trim() ?? '';
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'there';
    
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase();

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Top row: Date on the left, action buttons on the right
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: s.textMuted,
                            letterSpacing: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Theme toggle lives on the Profile/Settings screen now, and Action Plan,
                      // Audit Log and Community Hub all moved to clickable Quick Access cards on
                      // each dashboard — keeps this bar from accumulating one icon per feature.
                      if (role == 'MANAGEMENT') ...[
                        const SizedBox(width: 8),
                        _ChromeButton(
                          icon: LucideIcons.brainCircuit,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KnowledgeNotesScreen())),
                        ),
                      ],
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
                          size: 32,
                          fontSize: 11,
                          border: Border.all(color: s.bg, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.roleColor(role).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom row: Warm greeting with iOS-style bold typography
                  Text(
                    '$_greeting, $firstName 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: s.textPrimary,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: s.textMuted,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: s.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: s.textSecondary),
              ),
              if (badge)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.saffron500,
                      shape: BoxShape.circle,
                      border: Border.all(color: s.bg, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
