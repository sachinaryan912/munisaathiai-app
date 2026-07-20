import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

const _actionColors = {
  'CREATE_USER': AppColors.success,
  'UPDATE_USER': Color(0xFF6366F1),
  'BLOCK_USER': AppColors.danger,
  'UNBLOCK_USER': AppColors.success,
  'RESET_PASSWORD': AppColors.warning,
  'CREATE_SCHOOL': AppColors.success,
  'UPDATE_SCHOOL': Color(0xFF6366F1),
  'DELETE_SCHOOL': AppColors.danger,
  'ASSIGN_TRAINER': Color(0xFF6366F1),
  'ADD_SCHOOL_CLASS': AppColors.success,
  'DELETE_SCHOOL_CLASS': AppColors.danger,
  'UPDATE_THRESHOLDS': Color(0xFF6366F1),
};

const _actionLabels = {
  'CREATE_USER': 'Created user',
  'UPDATE_USER': 'Updated user',
  'BLOCK_USER': 'Blocked user',
  'UNBLOCK_USER': 'Unblocked user',
  'RESET_PASSWORD': 'Reset password',
  'CREATE_SCHOOL': 'Added school',
  'UPDATE_SCHOOL': 'Updated school',
  'DELETE_SCHOOL': 'Removed school',
  'ASSIGN_TRAINER': 'Assigned trainer',
  'ADD_SCHOOL_CLASS': 'Added class/section',
  'DELETE_SCHOOL_CLASS': 'Removed class/section',
  'UPDATE_THRESHOLDS': 'Updated thresholds',
};

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'Audit Log',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getAuditLog,
        builder: (context, entries, refresh) {
          final s = context.surface;
          if (entries.isEmpty) {
            return const EmptyView(title: 'No activity recorded yet', subtitle: 'User and school management actions will show up here.', icon: LucideIcons.history);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final action = e['action'] as String? ?? '';
              final color = _actionColors[action] ?? s.textMuted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_actionLabels[action] ?? action}: ${e['targetName']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                            const SizedBox(height: 3),
                            Text('by ${e['actorName']} · ${timeAgo(DateTime.tryParse(e['createdAt'] as String? ?? ''))}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                            if ((e['details'] as String?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 3),
                              Text(e['details'] as String, style: TextStyle(fontSize: 10.5, color: s.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
