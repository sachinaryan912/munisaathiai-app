import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_icon.dart';
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

  static const double _height = 142;

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
            color: s.bg.withValues(alpha: dark ? 0.85 : 0.9),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (role == 'MANAGEMENT') ...[
                        _ChromeButton(
                          icon: HugeIcons.strokeRoundedAiBrain01,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KnowledgeNotesScreen())),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _ChromeButton(
                        icon: HugeIcons.strokeRoundedSearch01,
                        onTap: () {
                          if (role == 'MANAGEMENT') {
                            context.push('/management/schools');
                          } else if (role == 'TRAINER') {
                            context.push('/trainer/schools');
                          } else if (role == 'PRINCIPAL') {
                            context.push('/principal/teachers');
                          } else if (role == 'TEACHER') {
                            context.push('/teacher/evidence');
                          } else if (role == 'STUDENT') {
                            context.push('/student/assignments');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _ChromeButton(
                        icon: HugeIcons.strokeRoundedNotification03,
                        onTap: () => showNotificationPanel(context),
                        badge: notifs.unreadCount > 0,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: UserAvatar(
                          size: 34,
                          fontSize: 12,
                          border: Border.all(color: s.bg, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Bottom row: Greeting with schoolhouse illustration on the right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_greeting,',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: s.textPrimary,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              '$firstName 👋',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: s.textPrimary,
                                letterSpacing: -0.5,
                                height: 1.15,
                              ),
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/school_illustration.png',
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
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
  final dynamic icon;
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
                child: Center(child: AppIcon(icon, size: 16, color: s.textSecondary)),
              ),
              if (badge)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: s.bg, width: 1.5),
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
