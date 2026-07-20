import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';
import 'widgets/school_status_widgets.dart';

class ManagementDashboardScreen extends StatelessWidget {
  const ManagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: '',
      isDashboard: true,
      dashboardSubtitle: "Here's how your network is doing today.",
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
  Map<String, dynamic>? _insights;
  bool _insightsLoading = false;
  String? _insightsError;

  Future<void> _generateInsights() async {
    setState(() {
      _insightsLoading = true;
      _insightsError = null;
    });
    try {
      _insights = await widget.repo.generateMonitoringInsights();
    } catch (e) {
      _insightsError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _insightsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final summary = widget.data['summary'] as Map<String, dynamic>? ?? {};
    final alerts = (widget.data['alerts'] as List? ?? []).cast<Map<String, dynamic>>();
    final schools = (widget.data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
    final averageMii = summary['averageMii'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatTile(label: 'Total Schools', value: '${summary['totalSchools'] ?? 0}', icon: LucideIcons.school, color: AppColors.roleColor('MANAGEMENT'), animateIndex: 0),
            StatTile(label: 'Average MII', value: averageMii != null ? (averageMii as num).toStringAsFixed(1) : '—', icon: LucideIcons.trendingUp, color: const Color(0xFF10B981), animateIndex: 1),
            StatTile(label: 'Active Trainers', value: '${summary['activeTrainers'] ?? 0}', icon: LucideIcons.users, color: const Color(0xFF6366F1), animateIndex: 2),
            StatTile(label: 'Total Students', value: '${summary['totalStudents'] ?? 0}', icon: LucideIcons.graduationCap, color: AppColors.saffron500, animateIndex: 3),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Row(
            children: [
              _StatusChip(label: 'Excellent', count: summary['excellentCount'] as int? ?? 0, color: AppColors.success),
              _StatusChip(label: 'Needs Support', count: summary['needsSupportCount'] as int? ?? 0, color: AppColors.info),
              _StatusChip(label: 'Weak', count: summary['weakCount'] as int? ?? 0, color: AppColors.warning),
              _StatusChip(label: 'Urgent', count: summary['urgentCount'] as int? ?? 0, color: AppColors.danger),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(LucideIcons.sparkles, size: 17, color: AppColors.saffron500),
                const SizedBox(width: 8),
                Text('AI Monitoring Assistant', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
              ]),
              const SizedBox(height: 4),
              Text('Priority actions and weekly focus across the network.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 14),
              if (_insightsLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoadingView(message: 'Scanning network activity...'))
              else if (_insightsError != null)
                Text(_insightsError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
              else if (_insights != null) ...[
                _InsightsView(insights: _insights!),
                const SizedBox(height: 12),
                PdfDownloadButton(
                  fileName: 'ai_monitoring_insights.pdf',
                  download: widget.repo.downloadMonitoringInsightsPdf,
                ),
              ]
              else
                GradientButton(label: 'Generate Monitoring Insights', icon: Icons.auto_awesome, onPressed: _generateInsights, height: 46),
            ],
          ),
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 22),
          Row(children: [
            Text('Alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/management/alerts'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
          ]),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: alerts.take(4).map((a) {
                final urgent = a['type'] == 'URGENT';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Icon(LucideIcons.triangleAlert, size: 18, color: urgent ? AppColors.danger : AppColors.warning),
                  title: Text(a['schoolName'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                  subtitle: Text(a['message'] as String, style: TextStyle(fontSize: 11, color: s.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(children: [
          Text('Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const Spacer(),
          TextButton(onPressed: () => context.go('/management/schools'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
        ]),
        const SizedBox(height: 10),
        ...schools.take(5).map((sc) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SectionCard(
                onTap: () => context.push('/management/schools/${sc['id']}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sc['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                          Text('${sc['district']} · ${sc['trainer']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                        ],
                      ),
                    ),
                    SchoolStatusBadge(mii: sc['miiScore'] as int? ?? 0, status: sc['status'] as String?),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  final Map<String, dynamic> insights;
  const _InsightsView({required this.insights});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final priorityActions = (insights['priorityActions'] as List? ?? []).cast<Map<String, dynamic>>();
    final weeklyFocus = (insights['weeklyFocus'] as List? ?? []).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (priorityActions.isNotEmpty) ...[
          Text('Priority Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 6),
          ...priorityActions.map((a) {
            final urgent = a['urgency'] == 'high';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.circleAlert, size: 13, color: urgent ? AppColors.danger : AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${a['schoolName']}: ${a['action']}', style: TextStyle(fontSize: 12, color: s.textSecondary))),
                ],
              ),
            );
          }),
        ],
        if (weeklyFocus.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Weekly Focus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 6),
          ...weeklyFocus.map((w) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $w', style: TextStyle(fontSize: 12, color: s.textSecondary)))),
        ],
      ],
    );
  }
}
