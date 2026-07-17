import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

class ManagementReportsScreen extends StatelessWidget {
  const ManagementReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'Reports',
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getOverview, builder: (context, data, refresh) => _Body(data: data, repo: repo)),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> data;
  final ManagementRepository repo;
  const _Body({required this.data, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _tab = 'methodology';
  Map<String, dynamic>? _networkReport;
  bool _reportLoading = false;
  String? _reportError;

  Future<void> _generate() async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      _networkReport = await widget.repo.generateNetworkReport();
    } catch (e) {
      _reportError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final methodologies = (widget.data['methodologies'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Wrap(spacing: 8, children: [
          _TabChip(label: 'Methodology', value: 'methodology', active: _tab, onTap: (v) => setState(() => _tab = v)),
          _TabChip(label: 'AI Impact Report', value: 'ai', active: _tab, onTap: (v) => setState(() => _tab = v)),
        ]),
        const SizedBox(height: 16),
        if (_tab == 'methodology')
          SectionCard(
            child: Column(
              children: methodologies.map((m) {
                final score = m['avgScore'] as int? ?? 0;
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
        else
          SectionCard(
            child: _reportLoading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: LoadingView(message: 'Vidya is analyzing the network...'))
                : _reportError != null
                    ? Text(_reportError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
                    : _networkReport != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NetworkReportView(report: _networkReport!),
                              const SizedBox(height: 14),
                              PdfDownloadButton(
                                fileName: 'network_impact_report.pdf',
                                download: widget.repo.downloadNetworkReportPdf,
                              ),
                            ],
                          )
                        : GradientButton(label: 'Generate Network Impact Report', icon: Icons.auto_awesome, onPressed: _generate, height: 46),
          ),
      ],
    );
  }
}

class _NetworkReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  const _NetworkReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final topSchools = (report['topPerformingSchools'] as List? ?? []).cast<String>();
    final needIntervention = (report['schoolsNeedingIntervention'] as List? ?? []).cast<Map<String, dynamic>>();
    final recommendations = (report['recommendations'] as List? ?? []).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(report['healthSummary'] as String? ?? '', style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.5)),
        if (topSchools.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Top Performing Schools', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 6),
          ...topSchools.map((sc) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $sc', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
        if (needIntervention.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Schools Needing Intervention', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning)),
          const SizedBox(height: 6),
          ...needIntervention.map((n) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('${n['schoolName']}: ${n['reason']}', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
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
