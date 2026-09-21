import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/quick_access_card.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../action_plans/action_plan_sheet.dart';
import '../shared/community_hub_screen.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: '',
      isDashboard: true,
      dashboardSubtitle: "Here's your class today.",
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getDashboard,
        builder: (context, data, refresh) => _Body(data: data, repo: repo),
      ),
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
  int? _openingEvidenceId;

  @override
  void initState() {
    super.initState();
    _loadExistingReport();
  }

  Future<void> _loadExistingReport() async {
    try {
      final existing = await widget.repo.getDailyReport();
      if (existing['exists'] == true && mounted) setState(() => _report = existing);
    } catch (_) {
      // No stored report yet
    }
  }

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

  Future<void> _viewEvidence(int id, String fileName) async {
    setState(() => _openingEvidenceId = id);
    try {
      final bytes = await widget.repo.getEvidenceFile(id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _openingEvidenceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;
    final studentsCount = data['studentsCount'] as int? ?? 0;
    final evidenceToday = data['evidenceToday'] as num? ?? 0;
    final methodsActiveToday = data['methodsActiveToday'] as num? ?? 0;
    final implementationPercent = data['implementationPercent'] as int? ?? 0;
    final pending = (data['pendingMethodologies'] as List? ?? []).cast<String>();
    final recentEvidence = (data['recentEvidence'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ProgressRing(value: implementationPercent, color: AppColors.roleColor('TEACHER'), subLabel: 'Today', radius: 40),
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
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            StatTile(label: 'My Students', value: '$studentsCount', icon: HugeIcons.strokeRoundedUserGroup, color: AppColors.roleColor('TEACHER'), animateIndex: 0),
            StatTile(label: 'Evidence Today', value: '$evidenceToday', icon: HugeIcons.strokeRoundedBookOpen01, color: const Color(0xFF6366F1), animateIndex: 1),
          ],
        ),
        const SizedBox(height: 20),
        Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: [
            QuickAccessCard(
              onTap: () => showMyActionPlansSheet(context),
              icon: HugeIcons.strokeRoundedTask01,
              color: const Color(0xFF0EA5E9),
              title: 'Action Plan',
              subtitle: 'Corrective tasks and follow-ups assigned to you',
              cta: 'View Tasks',
            ),
            QuickAccessCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubScreen())),
              icon: HugeIcons.strokeRoundedGlobe02,
              color: const Color(0xFF14B8A6),
              title: 'Community Hub',
              subtitle: 'Wakeup Call Board, events, workshops & clubs',
              cta: 'Explore',
            ),
            QuickAccessCard(
              route: '/teacher/videos',
              icon: HugeIcons.strokeRoundedVideo01,
              color: const Color(0xFFDC2626),
              title: 'Video Gallery',
              subtitle: 'Browse unlisted YouTube videos from Management',
              cta: 'Watch Videos',
            ),
          ],
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Not Yet Logged Today', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pending.map((m) => Chip(label: Text(m), backgroundColor: AppColors.warning.withValues(alpha: 0.12), labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.warning), side: BorderSide.none)).toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedAiMagic, size: 17, color: AppColors.saffron500),
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
              else if (_report != null) ...[
                _ReportView(report: _report!),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _generateReport,
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 14, color: AppColors.saffron500),
                    label: const Text('Regenerate', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ] else
                GradientButton(label: 'Generate Report', icon: Icons.auto_awesome, onPressed: _generateReport, height: 46),
            ],
          ),
        ),
        if (recentEvidence.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Recent Evidence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < recentEvidence.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 52, endIndent: 16, color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    onTap: _openingEvidenceId == recentEvidence[i]['id'] ? null : () => _viewEvidence(recentEvidence[i]['id'] as int, recentEvidence[i]['fileName'] as String),
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(10)),
                      child: _openingEvidenceId == recentEvidence[i]['id']
                          ? const Padding(padding: EdgeInsets.all(9), child: CircularProgressIndicator(strokeWidth: 2))
                          : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedDocumentValidation, size: 16, color: AppColors.saffron600)),
                    ),
                    title: Text(recentEvidence[i]['methodology'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                    subtitle: Text(recentEvidence[i]['fileName'] as String, maxLines: 1, style: TextStyle(fontSize: 10.5, color: s.textMuted), overflow: TextOverflow.ellipsis),
                    trailing: (recentEvidence[i]['trainerVerified'] as bool? ?? false)
                        ? const HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 16, color: AppColors.success)
                        : HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 15, color: s.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ] else
          const EmptyView(title: 'No evidence uploaded yet', icon: Icons.book_outlined),
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
          const Text('✓ Implemented', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.success)),
          const SizedBox(height: 6),
          ...implemented.map((i) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('${i['methodology']}: ${i['note']}', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
          const SizedBox(height: 10),
        ],
        if (gaps.isNotEmpty) ...[
          const Text('✗ Gaps', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
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
