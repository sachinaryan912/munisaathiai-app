import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../action_plans/action_plan_sheet.dart';
import '../shell/app_shell.dart';
import 'trainer_repository.dart';

class TrainerAlertsScreen extends StatefulWidget {
  const TrainerAlertsScreen({super.key});

  @override
  State<TrainerAlertsScreen> createState() => _TrainerAlertsScreenState();
}

class _TrainerAlertsScreenState extends State<TrainerAlertsScreen> {
  final _repo = TrainerRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _createActionPlan(BuildContext context, String schoolName) async {
    List<Map<String, dynamic>> assignees = [];
    try {
      final schools = await _repo.getSchools();
      final school = schools.firstWhere((s) => s['name'] == schoolName, orElse: () => const {});
      if (school['id'] != null) {
        final teachers = await _repo.getTeachers(schoolId: school['id'] as int);
        assignees = teachers.map((t) => {'id': t['id'], 'name': t['name']}).toList();
      }
    } catch (_) {}
    if (!context.mounted) return;
    await showCreateActionPlanSheet(context, schoolName: schoolName, assignees: assignees);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Alerts',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: _repo.getAlerts,
        builder: (context, allAlerts, refresh) {
          final s = context.surface;
          if (allAlerts.isEmpty) {
            return ListView(children: const [SizedBox(height: 140), EmptyView(title: 'All Clear!', subtitle: 'No active alerts across your schools.', icon: LucideIcons.bellOff)]);
          }
          final q = _query.trim().toLowerCase();
          final alerts = q.isEmpty
              ? allAlerts
              : allAlerts.where((a) {
                  return (a['schoolName'] as String? ?? '').toLowerCase().contains(q) ||
                      (a['message'] as String? ?? '').toLowerCase().contains(q);
                }).toList();
          final urgent = alerts.where((a) => a['type'] == 'URGENT').toList();
          final warning = alerts.where((a) => a['type'] != 'URGENT').toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('${allAlerts.length} active alert${allAlerts.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12.5, color: s.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ListSearchField(controller: _searchCtrl, hint: 'Search by school or message', onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: 14),
              if (alerts.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No alerts match your search.', style: TextStyle(fontSize: 12, color: s.textMuted)))
              else ...[
                if (urgent.isNotEmpty) ..._section('Urgent', urgent, AppColors.danger, s),
                if (warning.isNotEmpty) ..._section('Warning', warning, AppColors.warning, s),
              ],
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _createActionPlan(context, a['schoolName'] as String),
                            icon: const Icon(LucideIcons.clipboardList, size: 13),
                            label: const Text('Create Action Plan', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                          ),
                        ),
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
