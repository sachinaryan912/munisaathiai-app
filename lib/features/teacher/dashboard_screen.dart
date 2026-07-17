import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/greeting_header.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: '',
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getDashboard, builder: (context, data, refresh) => _Body(data: data, repo: repo)),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> data;
  final TeacherRepository repo;
  const _Body({required this.data, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Map<String, dynamic>? _report;
  bool _reportLoading = false;
  String? _reportError;

  Future<void> _generateReport() async {
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      _report = await widget.repo.generateDailyReport();
    } catch (e) {
      _reportError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final data = widget.data;
    final studentsCount = data['studentsCount'] as int? ?? 0;
    final evidenceToday = data['evidenceToday'] as num? ?? 0;
    final methodsActiveToday = data['methodsActiveToday'] as num? ?? 0;
    final implementationPercent = data['implementationPercent'] as int? ?? 0;
    final pending = (data['pendingMethodologies'] as List? ?? []).cast<String>();
    final recentEvidence = (data['recentEvidence'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const GreetingHeader(subtitle: 'Here\'s your class today.'),
        const SizedBox(height: 18),
        SectionCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ProgressRing(value: implementationPercent, color: AppColors.roleColor('TEACHER'), subLabel: 'Today', radius: 42),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Implementation", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$methodsActiveToday/12 methodologies logged, $evidenceToday evidence uploaded today.', style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatTile(label: 'My Students', value: '$studentsCount', icon: LucideIcons.users, color: AppColors.roleColor('TEACHER'), animateIndex: 0),
            StatTile(label: 'Evidence Today', value: '$evidenceToday', icon: LucideIcons.bookOpen, color: const Color(0xFF6366F1), animateIndex: 1),
          ],
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Not Yet Logged Today', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pending.map((m) => Chip(label: Text(m), backgroundColor: AppColors.warning.withValues(alpha: 0.12), labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning), side: BorderSide.none)).toList(),
            ),
          ),
        ],
        const SizedBox(height: 22),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(LucideIcons.sparkles, size: 17, color: AppColors.saffron500),
                const SizedBox(width: 8),
                Text('AI Daily Report', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
              ]),
              const SizedBox(height: 4),
              Text('Auto-generated summary of implementation gaps and suggestions.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 14),
              if (_reportLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoadingView(message: 'Vidya is analyzing your day...'))
              else if (_reportError != null)
                Text(_reportError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
              else if (_report != null)
                _ReportView(report: _report!)
              else
                GradientButton(label: 'Generate Report', icon: Icons.auto_awesome, onPressed: _generateReport, height: 46),
            ],
          ),
        ),
        if (recentEvidence.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Recent Evidence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: recentEvidence.map((e) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(11)), child: const Icon(LucideIcons.fileCheck, size: 15, color: AppColors.saffron600)),
                    title: Text(e['methodology'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                    subtitle: Text(e['fileName'] as String, maxLines: 1, style: TextStyle(fontSize: 10.5, color: s.textMuted), overflow: TextOverflow.ellipsis),
                    trailing: (e['trainerVerified'] as bool? ?? false) ? const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.success) : Icon(LucideIcons.clock, size: 15, color: s.textMuted),
                  )).toList(),
            ),
          ),
        ] else
          const EmptyView(title: 'No evidence uploaded yet', icon: LucideIcons.bookOpen),
      ],
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final implemented = (report['implemented'] as List? ?? []).cast<Map<String, dynamic>>();
    final gaps = (report['gaps'] as List? ?? []).cast<Map<String, dynamic>>();
    final suggestions = (report['suggestions'] as List? ?? []).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (implemented.isNotEmpty) ...[
          Text('✓ Implemented', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 6),
          ...implemented.map((i) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('${i['methodology']}: ${i['note']}', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
          const SizedBox(height: 10),
        ],
        if (gaps.isNotEmpty) ...[
          Text('✗ Gaps', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
          const SizedBox(height: 6),
          ...gaps.map((g) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('${g['methodology']}: ${g['note']}', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
          const SizedBox(height: 10),
        ],
        if (suggestions.isNotEmpty) ...[
          Text('Suggestions', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 6),
          ...suggestions.map((sug) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $sug', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
      ],
    );
  }
}
