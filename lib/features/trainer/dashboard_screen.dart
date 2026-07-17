import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/greeting_header.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'trainer_repository.dart';
import 'widgets/school_status.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return AppShell(
      title: '',
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getDashboard, builder: (context, data, refresh) => _Body(data: data, repo: repo)),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> data;
  final TrainerRepository repo;
  const _Body({required this.data, required this.repo});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Map<String, dynamic>? _plan;
  bool _planLoading = false;
  String? _planError;

  Future<void> _generatePlan() async {
    setState(() {
      _planLoading = true;
      _planError = null;
    });
    try {
      _plan = await widget.repo.generateTrainingPlan();
    } catch (e) {
      _planError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _planLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final data = widget.data;
    final schoolsCount = data['schoolsCount'] as int? ?? 0;
    final teacherCount = data['teacherCount'] as int? ?? 0;
    final pendingEvidence = data['pendingEvidence'] as num? ?? 0;
    final avgMii = data['avgMii'] as int? ?? 0;
    final schools = (data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
    final alerts = (data['alerts'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const GreetingHeader(subtitle: 'Here\'s how your schools are doing today.'),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            StatTile(label: 'My Schools', value: '$schoolsCount', icon: LucideIcons.school, color: AppColors.roleColor('TRAINER'), animateIndex: 0),
            StatTile(label: 'Avg MII', value: '$avgMii', icon: LucideIcons.trendingUp, color: const Color(0xFF10B981), animateIndex: 1),
            StatTile(label: 'Teachers', value: '$teacherCount', icon: LucideIcons.users, color: const Color(0xFF6366F1), animateIndex: 2),
            StatTile(label: 'Pending Evidence', value: '$pendingEvidence', icon: LucideIcons.bookOpen, color: AppColors.warning, animateIndex: 3),
          ],
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 22),
          Row(children: [
            Text('Alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/trainer/alerts'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
          ]),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: alerts.take(3).map((a) {
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
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(LucideIcons.sparkles, size: 17, color: AppColors.saffron500),
                const SizedBox(width: 8),
                Text('AI Training Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
              ]),
              const SizedBox(height: 4),
              Text('Weekly plan and per-school priorities.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 14),
              if (_planLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LoadingView(message: 'Building your training plan...'))
              else if (_planError != null)
                Text(_planError!, style: const TextStyle(color: AppColors.danger, fontSize: 12))
              else if (_plan != null)
                _TrainingPlanView(plan: _plan!)
              else
                GradientButton(label: 'Generate Training Plan', icon: Icons.auto_awesome, onPressed: _generatePlan, height: 46),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('My Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (schools.isEmpty)
          const EmptyView(title: 'No schools assigned yet', icon: LucideIcons.school)
        else
          ...schools.map((sc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => context.push('/trainer/schools'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sc['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                            Text('${sc['district']} · ${sc['teacherCount']} teachers · ${sc['studentCount']} students', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          ],
                        ),
                      ),
                      SchoolStatusBadge(mii: sc['miiScore'] as int? ?? 0),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _TrainingPlanView extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _TrainingPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final schoolPerf = (plan['schoolPerformance'] as List? ?? []).cast<Map<String, dynamic>>();
    final weeklyPlan = (plan['weeklyPlan'] as List? ?? []).cast<Map<String, dynamic>>();
    final nextTopic = plan['recommendedNextTopic'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextTopic != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(14)),
            child: Text('Next topic: $nextTopic', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.saffron700)),
          ),
        ...schoolPerf.map((sp) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${sp['schoolName']} (${sp['status']}): ${sp['action']}', style: TextStyle(fontSize: 12, color: s.textSecondary)),
            )),
        if (weeklyPlan.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Weekly Plan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 6),
          ...weeklyPlan.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${w['day']}: ${w['task']} (${w['priority']})', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
              )),
        ],
      ],
    );
  }
}
