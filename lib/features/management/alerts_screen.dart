import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

const _categoryLabels = {
  'MII': 'MII Score', 'EVIDENCE': 'Evidence', 'METHODOLOGY': 'Methodology', 'REPORT': 'Report',
};

class ManagementAlertsScreen extends StatelessWidget {
  const ManagementAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'Alerts',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getOverview,
        builder: (context, data, refresh) {
          final s = context.surface;
          final alerts = (data['alerts'] as List? ?? []).cast<Map<String, dynamic>>();
          if (alerts.isEmpty) {
            return ListView(children: const [SizedBox(height: 140), EmptyView(title: 'All Clear!', subtitle: 'No active alerts across all schools.', icon: LucideIcons.bellOff)]);
          }
          final urgent = alerts.where((a) => a['type'] == 'URGENT').toList();
          final warning = alerts.where((a) => a['type'] != 'URGENT').toList();

          Widget section(String label, List<Map<String, dynamic>> items, Color color) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(LucideIcons.triangleAlert, size: 13, color: color),
                  const SizedBox(width: 6),
                  Text('$label (${items.length})', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
                ]),
                const SizedBox(height: 8),
                ...items.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SectionCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 4, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(child: Text(a['schoolName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary))),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: s.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)), child: Text(_categoryLabels[a['category']] ?? a['category'] as String? ?? '', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: s.textSecondary))),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(a['message'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('${alerts.length} active alert${alerts.length == 1 ? '' : 's'} across all schools', style: TextStyle(fontSize: 12.5, color: s.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              if (urgent.isNotEmpty) section('Urgent', urgent, AppColors.danger),
              if (warning.isNotEmpty) section('Warning', warning, AppColors.warning),
            ],
          );
        },
      ),
    );
  }
}
