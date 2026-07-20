import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';
import 'widgets/ai_daily_report_view.dart';

const _statusColors = {
  'Active': Color(0xFF10B981), 'Needs Support': Color(0xFFF59E0B), 'Inactive': Color(0xFFEF4444),
};

class PrincipalReportsScreen extends StatelessWidget {
  const PrincipalReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Reports',
      body: AsyncScreen<List<dynamic>>(
        loader: () => Future.wait([repo.getTeachers(), repo.getMethodology(), repo.getParentInvolvement()]),
        builder: (context, results, refresh) => _Body(
          teachers: (results[0] as List).cast<Map<String, dynamic>>(),
          methodology: (results[1] as List).cast<Map<String, dynamic>>(),
          parentInvolvement: results[2] as Map<String, dynamic>,
          repo: repo,
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> methodology;
  final Map<String, dynamic> parentInvolvement;
  final PrincipalRepository repo;
  const _Body({required this.teachers, required this.methodology, required this.parentInvolvement, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _tab = 'teachers';
  Map<String, dynamic>? _healthReport;
  bool _healthLoading = false;
  String? _healthError;
  final _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _generateHealth() async {
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    try {
      _healthReport = await widget.repo.generateDailyReport();
    } catch (e) {
      _healthError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _healthLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Wrap(
          spacing: 8,
          children: [
            _TabChip(label: 'Teachers', value: 'teachers', active: _tab, onTap: (v) => setState(() => _tab = v)),
            _TabChip(label: 'Methodology', value: 'methodology', active: _tab, onTap: (v) => setState(() => _tab = v)),
            _TabChip(label: 'Parent Involvement', value: 'parents', active: _tab, onTap: (v) => setState(() => _tab = v)),
            _TabChip(label: 'AI Health Report', value: 'health', active: _tab, onTap: (v) => setState(() => _tab = v)),
          ],
        ),
        const SizedBox(height: 16),
        if (_tab == 'teachers')
          Builder(builder: (context) {
            final q = _query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? widget.teachers
                : widget.teachers.where((t) {
                    return (t['name'] as String? ?? '').toLowerCase().contains(q) || (t['status'] as String? ?? '').toLowerCase().contains(q);
                  }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.teachers.isNotEmpty) ...[
                  ListSearchField(controller: _searchCtrl, hint: 'Search by name or status', onChanged: (v) => setState(() => _query = v)),
                  const SizedBox(height: 12),
                ],
                if (filtered.isEmpty)
                  Text('No teachers match your search.', style: TextStyle(fontSize: 12.5, color: s.textMuted))
                else
                  SectionCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: filtered.map((t) {
                        final status = t['status'] as String? ?? 'Active';
                        final color = _statusColors[status] ?? s.textMuted;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          title: Text(t['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                          subtitle: Text('Score ${t['score']} · Evidence ${t['evidenceCount']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color))),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          })
        else if (_tab == 'methodology')
          SectionCard(
            child: Column(
              children: widget.methodology.map((m) {
                final score = m['score'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(m['name'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400)))),
                      const SizedBox(width: 8),
                      Text('$score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: s.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else if (_tab == 'parents')
          Builder(builder: (context) {
            final avg = widget.parentInvolvement['schoolAvgCompletion'] as int?;
            final students = (widget.parentInvolvement['students'] as List? ?? []).cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('School Avg. Home-Learning Completion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textSecondary)),
                          const SizedBox(height: 4),
                          Text(avg != null ? '$avg%' : '—', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: s.textPrimary)),
                          Text('Ghar Ek Pathshala · last 4 weeks', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                        ],
                      ),
                    ),
                    PdfDownloadButton(fileName: 'parent_involvement_report.pdf', download: widget.repo.downloadParentInvolvementPdf),
                  ]),
                ),
                const SizedBox(height: 14),
                if (students.isEmpty)
                  Text('No students found.', style: TextStyle(fontSize: 12.5, color: s.textMuted))
                else
                  SectionCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: students.map((st) {
                        final completion = st['completionPercent'] as int?;
                        final color = completion == null ? s.textMuted : completion >= 70 ? AppColors.success : completion >= 40 ? AppColors.warning : AppColors.danger;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          title: Text(st['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                          subtitle: Text('${st['className'] ?? ''} ${st['section'] ?? ''}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          trailing: Text(completion != null ? '$completion%' : 'No data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            );
          })
        else
          SectionCard(
            child: _healthLoading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LoadingView(message: 'Generating report...'))
                : _healthError != null
                    ? Text(_healthError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
                    : _healthReport != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AiDailyReportView(report: _healthReport!),
                              const SizedBox(height: 14),
                              PdfDownloadButton(
                                fileName: 'daily_school_health_report.pdf',
                                download: widget.repo.downloadDailyReportPdf,
                              ),
                            ],
                          )
                        : GradientButton(label: 'Generate School Health Report', icon: Icons.auto_awesome, onPressed: _generateHealth, height: 46),
          ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final ValueChanged<String> onTap;
  const _TabChip({required this.label, required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isActive = active == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(value),
      selectedColor: AppColors.saffron500,
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.white : s.textSecondary),
      backgroundColor: s.card,
      side: BorderSide(color: isActive ? AppColors.saffron500 : s.border),
    );
  }
}
