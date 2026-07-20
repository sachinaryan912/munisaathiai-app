import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'attendance_trends_screen.dart';
import 'principal_repository.dart';

class PrincipalAttendanceReportScreen extends StatelessWidget {
  const PrincipalAttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Attendance Report',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.trendingUp),
          tooltip: 'Attendance Trends',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrincipalAttendanceTrendsScreen())),
        ),
      ],
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getClasses,
        builder: (context, classes, refresh) {
          if (classes.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No classes found', icon: LucideIcons.school)]);
          }
          return _Body(classes: classes, repo: repo);
        },
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final PrincipalRepository repo;
  const _Body({required this.classes, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late Map<String, dynamic> _selectedClass = widget.classes.first;
  late DateTimeRange _range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());

  Map<String, dynamic>? _report;
  bool _loading = false;
  String? _error;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() { _range = picked; _report = null; });
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _report = await widget.repo.getAttendanceReport(
        className: _selectedClass['className'] as String,
        section: _selectedClass['section'] as String?,
        start: _range.start,
        end: _range.end,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dateFmt = DateFormat('d MMM yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textMuted)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _selectedClass,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: widget.classes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c['displayName'] as String, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() { _selectedClass = v; _report = null; });
                },
              ),
              const SizedBox(height: 14),
              Text('Date Range', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textMuted)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickRange,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: s.border), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendarRange, size: 16, color: s.textMuted),
                      const SizedBox(width: 8),
                      Text('${dateFmt.format(_range.start)} — ${dateFmt.format(_range.end)}', style: TextStyle(fontSize: 12.5, color: s.textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(label: 'Generate Report', icon: Icons.auto_awesome, onPressed: _generate, loading: _loading, height: 46),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LoadingView(message: 'Compiling attendance records...'))
        else if (_report != null)
          _ReportView(report: _report!, repo: widget.repo, selectedClass: _selectedClass, range: _range),
      ],
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  final PrincipalRepository repo;
  final Map<String, dynamic> selectedClass;
  final DateTimeRange range;
  const _ReportView({required this.report, required this.repo, required this.selectedClass, required this.range});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final rows = (report['studentRows'] as List? ?? []).cast<Map<String, dynamic>>();
    final classAverage = report['classAverage'] as int? ?? 0;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Class Average', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textSecondary)),
              const Spacer(),
              Text('$classAverage%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: s.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: s.border),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No attendance records in this range.', style: TextStyle(fontSize: 12, color: s.textMuted)))
          else
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(r['name'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary, fontWeight: FontWeight.w600))),
                      Text('${r['presentCount']}/${r['totalDays']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                      const SizedBox(width: 10),
                      Text('${r['percent']}%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                    ],
                  ),
                )),
          const SizedBox(height: 14),
          PdfDownloadButton(
            fileName: 'attendance_report.pdf',
            download: () => repo.downloadAttendanceReportPdf(
              className: selectedClass['className'] as String,
              section: selectedClass['section'] as String?,
              start: range.start,
              end: range.end,
            ),
          ),
        ],
      ),
    );
  }
}
