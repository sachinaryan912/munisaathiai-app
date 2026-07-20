import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/csv_export.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';
import 'widgets/school_status_widgets.dart';

class ManagementMiiScreen extends StatefulWidget {
  const ManagementMiiScreen({super.key});

  @override
  State<ManagementMiiScreen> createState() => _ManagementMiiScreenState();
}

class _ManagementMiiScreenState extends State<ManagementMiiScreen> {
  final _repo = ManagementRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _export(List<Map<String, dynamic>> schools) => exportCsv(
        context,
        'mii-comparison.csv',
        ['School', 'MII', 'Training', 'Classroom', 'Evidence', 'Participation', 'Buddy/GRS', 'Parent', 'Academic', 'Reporting'],
        schools.map((sc) => [
              sc['name'], sc['miiScore'], sc['trainingScore'], sc['classroomScore'], sc['evidenceScore'],
              sc['participationScore'], sc['buddyGrsScore'], sc['parentScore'], sc['academicScore'], sc['reportingScore'],
            ]).toList(),
      );

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'MII Scores',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: _repo.getOverview,
        builder: (context, data, refresh) {
          final s = context.surface;
          final breakdown = (data['miiBreakdown'] as List? ?? []).cast<Map<String, dynamic>>();
          final allSchools = (data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
          final q = _query.trim().toLowerCase();
          final schools = q.isEmpty ? allSchools : allSchools.where((sc) => (sc['name'] as String? ?? '').toLowerCase().contains(q)).toList();

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
              Row(
                children: [
                  Expanded(child: Text('Comparative — All Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary))),
                  IconButton(icon: const Icon(LucideIcons.download, size: 19), tooltip: 'Export CSV', onPressed: schools.isEmpty ? null : () => _export(schools)),
                ],
              ),
              const SizedBox(height: 10),
              if (allSchools.isNotEmpty) ...[
                ListSearchField(controller: _searchCtrl, hint: 'Search by school name', onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 10),
              ],
              if (schools.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No schools match your search.', style: TextStyle(fontSize: 12, color: s.textMuted)))
              else
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
