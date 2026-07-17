import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'trainer_repository.dart';

class TrainerReportsScreen extends StatelessWidget {
  const TrainerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return AppShell(
      title: 'Reports',
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getReportsSummary, builder: (context, summary, refresh) => _Body(summary: summary, repo: repo)),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> summary;
  final TrainerRepository repo;
  const _Body({required this.summary, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _tab = 'week';
  Map<String, dynamic>? _monthly;
  bool _monthlyLoading = false;
  String? _monthlyError;

  Future<void> _generateMonthly() async {
    setState(() {
      _monthlyLoading = true;
      _monthlyError = null;
    });
    try {
      _monthly = await widget.repo.generateMonthlyReport();
    } catch (e) {
      _monthlyError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _monthlyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final sessionsThisWeek = (widget.summary['sessionsThisWeek'] as List? ?? []).cast<Map<String, dynamic>>();
    final teacherPerformance = (widget.summary['teacherPerformance'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Wrap(spacing: 8, children: [
          _TabChip(label: 'This Week', value: 'week', active: _tab, onTap: (v) => setState(() => _tab = v)),
          _TabChip(label: 'Teacher Performance', value: 'teachers', active: _tab, onTap: (v) => setState(() => _tab = v)),
          _TabChip(label: 'AI Monthly Report', value: 'monthly', active: _tab, onTap: (v) => setState(() => _tab = v)),
        ]),
        const SizedBox(height: 16),
        if (_tab == 'week')
          sessionsThisWeek.isEmpty
              ? Text('No sessions this week.', style: TextStyle(fontSize: 12.5, color: s.textMuted))
              : SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: sessionsThisWeek.map((sess) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          title: Text(sess['topic'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                          subtitle: Text('${sess['schoolName']} · ${sess['date']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          trailing: Text('${sess['attendedCount']}/${sess['attendeeCount']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)),
                        )).toList(),
                  ),
                )
        else if (_tab == 'teachers')
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: teacherPerformance.map((t) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    title: Text(t['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                    subtitle: Text(t['status'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                    trailing: Text('${t['score']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: s.textPrimary)),
                  )).toList(),
            ),
          )
        else
          SectionCard(
            child: _monthlyLoading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LoadingView(message: 'Generating monthly report...'))
                : _monthlyError != null
                    ? Text(_monthlyError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
                    : _monthly != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MonthlyReportView(report: _monthly!),
                              const SizedBox(height: 14),
                              PdfDownloadButton(
                                fileName: 'monthly_impact_report.pdf',
                                download: widget.repo.downloadMonthlyReportPdf,
                              ),
                            ],
                          )
                        : GradientButton(label: 'Generate Monthly Report', icon: Icons.auto_awesome, onPressed: _generateMonthly, height: 46),
          ),
      ],
    );
  }
}

class _MonthlyReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  const _MonthlyReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final wins = (report['wins'] as List? ?? []).cast<String>();
    final needAttention = (report['schoolsNeedingAttention'] as List? ?? []).cast<Map<String, dynamic>>();
    final recommendations = (report['recommendations'] as List? ?? []).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report['healthSummary'] as String? ?? '', style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.5)),
        if (wins.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Wins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 6),
          ...wins.map((w) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $w', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
        if (needAttention.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Schools Needing Attention', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning)),
          const SizedBox(height: 6),
          ...needAttention.map((n) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('${n['schoolName']}: ${n['reason']}', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Recommendations', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 6),
          ...recommendations.map((r) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $r', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
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
