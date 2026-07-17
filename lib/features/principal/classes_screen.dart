import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';

class PrincipalClassesScreen extends StatelessWidget {
  const PrincipalClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Classes',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getClasses,
        builder: (context, classes, refresh) {
          if (classes.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No classes found', icon: LucideIcons.school)]);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: classes.length,
            itemBuilder: (context, i) => _ClassCard(cls: classes[i]),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatefulWidget {
  final Map<String, dynamic> cls;
  const _ClassCard({required this.cls});

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final c = widget.cls;
    final students = (c['students'] as List? ?? []).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(13)), child: const Icon(LucideIcons.school, size: 18, color: AppColors.saffron600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['displayName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                      Text('${c['teacherName']} · ${c['studentCount']} students', style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
                Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: s.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MetricPill(label: 'Avg score', value: '${c['avgScore']}'),
                const SizedBox(width: 8),
                _MetricPill(label: 'Methodology', value: '${c['methodologyScore']}'),
                const SizedBox(width: 8),
                _MetricPill(label: 'Attendance', value: c['avgAttendance'] != null ? '${c['avgAttendance']}%' : '—'),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Divider(color: s.border),
              const SizedBox(height: 6),
              ...students.map((st) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(st['name'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary, fontWeight: FontWeight.w600))),
                        Text('Score ${st['score']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                        const SizedBox(width: 10),
                        Text(st['attendancePercent'] != null ? '${st['attendancePercent']}%' : '—', style: TextStyle(fontSize: 11, color: s.textMuted)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: s.textPrimary)),
            Text(label, style: TextStyle(fontSize: 9, color: s.textMuted)),
          ],
        ),
      ),
    );
  }
}
