import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';
import 'widgets/school_status_widgets.dart';

class ManagementMiiScreen extends StatelessWidget {
  const ManagementMiiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'MII Scores',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getOverview,
        builder: (context, data, refresh) {
          final s = context.surface;
          final breakdown = (data['miiBreakdown'] as List? ?? []).cast<Map<String, dynamic>>();
          final schools = (data['schools'] as List? ?? []).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('Network MII Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  children: breakdown.map((b) {
                    final pct = (b['percentage'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(b['area'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary))),
                            Text('${b['avgScore']}/${b['maxScore']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textSecondary)),
                          ]),
                          const SizedBox(height: 5),
                          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: (pct / 100).clamp(0, 1), minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              Text('Comparative — All Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  headingRowHeight: 36,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  columns: const [
                    DataColumn(label: Text('School', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('MII', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Training', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Classroom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Evidence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Particip.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Buddy/GRS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Parent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Academic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                    DataColumn(label: Text('Reporting', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                  ],
                  rows: schools.map((sc) {
                    return DataRow(cells: [
                      DataCell(Text(sc['name'] as String, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: s.textPrimary))),
                      DataCell(Text('${sc['miiScore']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: statusColor(sc['status'] as String?)))),
                      DataCell(Text('${sc['trainingScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['classroomScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['evidenceScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['participationScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['buddyGrsScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['parentScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['academicScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                      DataCell(Text('${sc['reportingScore']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
