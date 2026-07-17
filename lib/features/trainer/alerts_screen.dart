import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'trainer_repository.dart';

class TrainerAlertsScreen extends StatelessWidget {
  const TrainerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return AppShell(
      title: 'Alerts',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getAlerts,
        builder: (context, alerts, refresh) {
          final s = context.surface;
          if (alerts.isEmpty) {
            return ListView(children: const [SizedBox(height: 140), EmptyView(title: 'All Clear!', subtitle: 'No active alerts across your schools.', icon: LucideIcons.bellOff)]);
          }
          final urgent = alerts.where((a) => a['type'] == 'URGENT').toList();
          final warning = alerts.where((a) => a['type'] != 'URGENT').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('${alerts.length} active alert${alerts.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12.5, color: s.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              if (urgent.isNotEmpty) ..._section('Urgent', urgent, AppColors.danger, s),
              if (warning.isNotEmpty) ..._section('Warning', warning, AppColors.warning, s),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _section(String label, List<Map<String, dynamic>> items, Color color, MuniSurface s) {
    return [
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
                  Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['schoolName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                        const SizedBox(height: 3),
                        Text(a['message'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
      const SizedBox(height: 12),
    ];
  }
}
