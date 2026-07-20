import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';
import 'widgets/ai_daily_report_view.dart';

class PrincipalDashboardScreen extends StatelessWidget {
  const PrincipalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: '',
      isDashboard: true,
      dashboardSubtitle: "Here's how your school is doing today.",
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getDashboard, builder: (context, data, refresh) => _Body(data: data, repo: repo)),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> data;
  final PrincipalRepository repo;
  const _Body({required this.data, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Map<String, dynamic>? _report;
  bool _reportLoading = false;
  String? _reportError;

  Future<void> _generate() async {
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
    final schoolMii = data['schoolMii'] as int? ?? 0;
    final teacherCount = data['teacherCount'] as int? ?? 0;
    final classCount = data['classCount'] as num? ?? 0;
    final studentCount = data['studentCount'] as int? ?? 0;
    final pendingAlerts = data['pendingAlerts'] as num? ?? 0;
    final methodologyScores = (data['methodologyScores'] as List? ?? []).cast<Map<String, dynamic>>();
    final weakMethodologies = (data['weakMethodologies'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ProgressRing(value: schoolMii, color: AppColors.roleColor('PRINCIPAL'), subLabel: 'MII', radius: 42),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Health', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$teacherCount teachers · $classCount classes · $studentCount students', style: TextStyle(fontSize: 12, color: s.textSecondary)),
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
            StatTile(label: 'Teachers', value: '$teacherCount', icon: LucideIcons.users, color: AppColors.roleColor('PRINCIPAL'), animateIndex: 0),
            StatTile(label: 'Pending Alerts', value: '$pendingAlerts', icon: LucideIcons.triangleAlert, color: AppColors.warning, animateIndex: 1),
          ],
        ),
        if (weakMethodologies.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text('Methodologies Needing Attention', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: s.textPrimary)),
                ]),
                const SizedBox(height: 10),
                ...weakMethodologies.map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(m['name'] as String, style: TextStyle(fontSize: 12.5, color: s.textSecondary, fontWeight: FontWeight.w600))),
                        Text('${m['score']}/100', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.warning)),
                      ]),
                    )),
              ],
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
                Text('AI Principal Assistant', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
              ]),
              const SizedBox(height: 4),
              Text('Daily school health report · Teacher gap analysis · Meeting suggestions', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 14),
              if (_reportLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoadingView(message: 'Generating school health report...'))
              else if (_reportError != null)
                Text(_reportError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
              else if (_report != null)
                AiDailyReportView(report: _report!)
              else
                GradientButton(label: 'Generate Daily Report', icon: Icons.auto_awesome, onPressed: _generate, height: 46),
            ],
          ),
        ),
        if (methodologyScores.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Methodology Implementation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: methodologyScores.map((m) {
                final score = m['score'] as int? ?? 0;
                final bc = score >= 80 ? AppColors.success : score >= 60 ? AppColors.info : AppColors.warning;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(m['name'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: AlwaysStoppedAnimation(bc)))),
                      const SizedBox(width: 8),
                      SizedBox(width: 28, child: Text('$score', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: s.textPrimary))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
