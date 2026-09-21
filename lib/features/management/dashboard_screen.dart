import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../action_plans/action_plan_sheet.dart';
import '../shared/community_hub_screen.dart';
import '../shell/app_shell.dart';
import 'audit_log_screen.dart';
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
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getOverview,
        builder: (context, data, refresh) => _Body(data: data, repo: repo),
      ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final summary = widget.data['summary'] as Map<String, dynamic>? ?? {};
    final alerts = (widget.data['alerts'] as List? ?? []).cast<Map<String, dynamic>>();
    final schools = (widget.data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
    final averageMii = summary['averageMii'];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // 4-Column Stat Strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatColumn(
                  icon: HugeIcons.strokeRoundedSchool,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF8B5CF6),
                  value: '${summary['totalSchools'] ?? 0}',
                  label: 'Total Schools',
                ),
              ),
              _verticalDivider(s),
              Expanded(
                child: _StatColumn(
                  icon: HugeIcons.strokeRoundedAnalyticsUp,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF10B981),
                  value: averageMii is num ? averageMii.toStringAsFixed(1) : '—',
                  label: 'Average MII',
                ),
              ),
              _verticalDivider(s),
              Expanded(
                child: _StatColumn(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  value: '${summary['activeTrainers'] ?? 0}',
                  label: 'Active Trainers',
                ),
              ),
              _verticalDivider(s),
              Expanded(
                child: _StatColumn(
                  icon: HugeIcons.strokeRoundedMortarboard01,
                  iconBg: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFEA580C),
                  value: '${summary['totalStudents'] ?? 0}',
                  label: 'Total Students',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Schools by MII Performance
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: s.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Schools by MII Performance',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _SegmentedProgressBar(
                excellent: summary['excellentCount'] as int? ?? 0,
                needsSupport: summary['needsSupportCount'] as int? ?? 0,
                weak: summary['weakCount'] as int? ?? 0,
                urgent: summary['urgentCount'] as int? ?? 0,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusLegend(
                    color: const Color(0xFF10B981),
                    label: 'Excellent',
                    count: summary['excellentCount'] as int? ?? 0,
                  ),
                  _StatusLegend(
                    color: const Color(0xFF3B82F6),
                    label: 'Needs Support',
                    count: summary['needsSupportCount'] as int? ?? 0,
                  ),
                  _StatusLegend(
                    color: const Color(0xFFF59E0B),
                    label: 'Weak',
                    count: summary['weakCount'] as int? ?? 0,
                  ),
                  _StatusLegend(
                    color: const Color(0xFFEF4444),
                    label: 'Urgent',
                    count: summary['urgentCount'] as int? ?? 0,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // AI Monitoring Assistant
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedAiMagic, size: 17, color: AppColors.saffron500),
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
        const SizedBox(height: 20),

        // Quick Access
        Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
        const SizedBox(height: 10),
        _QuickAccessTile(
          icon: HugeIcons.strokeRoundedTask01,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0284C7),
          title: 'Action Plan',
          subtitle: 'Corrective tasks and follow-ups',
          onTap: () => showMyActionPlansSheet(context),
        ),
        const SizedBox(height: 8),
        _QuickAccessTile(
          icon: HugeIcons.strokeRoundedClock01,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF7C3AED),
          title: 'Audit Log',
          subtitle: 'Every user/school/knowledge activity',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditLogScreen())),
        ),
        const SizedBox(height: 8),
        _QuickAccessTile(
          icon: HugeIcons.strokeRoundedUserGroup,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF059669),
          title: 'Community Hub',
          subtitle: 'Wakeup Call Board, events, updates',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubScreen())),
        ),
        const SizedBox(height: 8),
        _QuickAccessTile(
          icon: HugeIcons.strokeRoundedVideo01,
          iconBg: const Color(0xFFFFE4E6),
          iconColor: const Color(0xFFE11D48),
          title: 'Video Gallery',
          subtitle: 'Upload and browse unlisted YouTube videos',
          onTap: () => context.push('/management/videos'),
        ),

        // Alerts
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text('Alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/management/alerts'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
          ]),
          const SizedBox(height: 8),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < alerts.take(4).length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 48, endIndent: 16, color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 18,
                      color: alerts[i]['type'] == 'URGENT' ? AppColors.danger : AppColors.warning,
                    ),
                    title: Text(alerts[i]['name'] as String? ?? alerts[i]['schoolName'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                    subtitle: Text(alerts[i]['message'] as String? ?? '', style: TextStyle(fontSize: 11, color: s.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Schools List
        const SizedBox(height: 20),
        Row(children: [
          Text('Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const Spacer(),
          TextButton(onPressed: () => context.go('/management/schools'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
        ]),
        const SizedBox(height: 8),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < schools.take(5).length; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 52, endIndent: 16, color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB)),
                InkWell(
                  onTap: () => context.push('/management/schools/${schools[i]['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: AppColors.roleManagement.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedSchool, size: 17, color: AppColors.roleManagement),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(schools[i]['name'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary)),
                              Text(schools[i]['location'] as String? ?? '${schools[i]['district'] ?? ''} · ${schools[i]['trainer'] ?? ''}', style: TextStyle(fontSize: 11, color: s.textSecondary)),
                            ],
                          ),
                        ),
                        if (schools[i]['averageMii'] != null)
                          Text('${(schools[i]['averageMii'] as num).toStringAsFixed(1)} MII', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.roleManagement))
                        else
                          SchoolStatusBadge(mii: schools[i]['miiScore'] as int? ?? 0, status: schools[i]['status'] as String?),
                        const SizedBox(width: 6),
                        HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 14, color: s.textMuted.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                  HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 13, color: urgent ? AppColors.danger : AppColors.warning),
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

Widget _verticalDivider(MuniSurface s) {
  return Container(
    width: 1,
    height: 44,
    color: s.border.withValues(alpha: 0.6),
  );
}

class _StatColumn extends StatelessWidget {
  final dynamic icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(icon, size: 18, color: iconColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: s.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: s.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final dynamic icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: s.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: AppIcon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: s.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: s.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              color: s.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final int excellent;
  final int needsSupport;
  final int weak;
  final int urgent;

  const _SegmentedProgressBar({
    required this.excellent,
    required this.needsSupport,
    required this.weak,
    required this.urgent,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final total = excellent + needsSupport + weak + urgent;
    if (total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 10,
          color: s.border.withValues(alpha: 0.3),
        ),
      );
    }

    final double excRatio = excellent / total;
    final double supRatio = needsSupport / total;
    final double weakRatio = weak / total;
    final double urgRatio = urgent / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (excRatio > 0)
              Expanded(
                flex: (excRatio * 1000).toInt().clamp(1, 1000),
                child: Container(color: const Color(0xFF10B981)),
              ),
            if (supRatio > 0)
              Expanded(
                flex: (supRatio * 1000).toInt().clamp(1, 1000),
                child: Container(color: const Color(0xFF3B82F6)),
              ),
            if (weakRatio > 0)
              Expanded(
                flex: (weakRatio * 1000).toInt().clamp(1, 1000),
                child: Container(color: const Color(0xFFF59E0B)),
              ),
            if (urgRatio > 0)
              Expanded(
                flex: (urgRatio * 1000).toInt().clamp(1, 1000),
                child: Container(color: const Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusLegend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.textSecondary)),
          ],
        ),
        const SizedBox(height: 5),
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: s.textPrimary)),
      ],
    );
  }
}
