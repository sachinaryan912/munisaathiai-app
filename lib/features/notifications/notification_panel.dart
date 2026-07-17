import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/icon_container.dart';
import '../../models/app_notification.dart';
import 'notification_icon_map.dart';
import 'notifications_provider.dart';

Future<void> showNotificationPanel(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NotificationSheet(),
  );
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final provider = context.watch<NotificationsProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: AppRadius.xlTop,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: s.border, borderRadius: AppRadius.pillAll)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  children: [
                    Text('Notifications', style: AppTypography.title(s.textPrimary).copyWith(fontSize: 17)),
                    const Spacer(),
                    if (provider.unreadCount > 0)
                      TextButton(
                        onPressed: provider.markAllRead,
                        child: const Text('Mark all read', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: provider.items.isEmpty
                    ? Center(
                        child: Text("You're all caught up", style: TextStyle(color: s.textMuted, fontWeight: FontWeight.w600)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: provider.items.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: s.border),
                        itemBuilder: (context, i) {
                          final n = provider.items[i];
                          return _NotificationTile(n: n, onTap: () => provider.markRead(n))
                              .animate(delay: (i * 40).ms)
                              .fadeIn(duration: 260.ms)
                              .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.read ? Colors.transparent : primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconContainer(
              icon: notificationIcon(n.icon),
              color: n.read ? s.textMuted : primary,
              size: 34,
              iconSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: AppTypography.body(s.textPrimary).copyWith(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.body(s.textSecondary).copyWith(fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(timeAgo(n.createdAt), style: AppTypography.caption(s.textMuted).copyWith(fontSize: 10.5)),
                ],
              ),
            ),
            if (!n.read) ...[
              const SizedBox(width: 6),
              Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
            ] else
              Icon(LucideIcons.check, size: 14, color: s.textMuted),
          ],
        ),
      ),
    );
  }
}
