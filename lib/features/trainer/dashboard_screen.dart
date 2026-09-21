import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_access_card.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../action_plans/action_plan_sheet.dart';
import '../shared/community_hub_screen.dart';
import '../shell/app_shell.dart';
import 'school_detail_screen.dart';
import 'trainer_repository.dart';
import 'widgets/school_status.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return AppShell(
      title: '',
      isDashboard: true,
      dashboardSubtitle: "Here's how your schools are doing today.",
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getDashboard,
        builder: (context, data, refresh) => _Body(data: data, repo: repo),
      ),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final data = widget.data;
    final schoolsCount = data['schoolsCount'] as int? ?? 0;
    final teacherCount = data['teacherCount'] as int? ?? 0;
    final pendingEvidence = data['pendingEvidence'] as num? ?? 0;
    final avgMii = data['avgMii'] as int? ?? 0;
    final schools = (data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
    final alerts = (data['alerts'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.42,
          children: [
            StatTile(label: 'My Schools', value: '$schoolsCount', icon: HugeIcons.strokeRoundedSchool, color: AppColors.roleColor('TRAINER'), animateIndex: 0),
            StatTile(label: 'Avg MII', value: '$avgMii', icon: HugeIcons.strokeRoundedAnalyticsUp, color: const Color(0xFF10B981), animateIndex: 1),
            StatTile(label: 'Teachers', value: '$teacherCount', icon: HugeIcons.strokeRoundedUserGroup, color: const Color(0xFF6366F1), animateIndex: 2),
            StatTile(label: 'Pending Evidence', value: '$pendingEvidence', icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.warning, animateIndex: 3),
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
              route: '/trainer/videos',
              icon: HugeIcons.strokeRoundedVideo01,
              color: const Color(0xFFDC2626),
              title: 'Video Gallery',
              subtitle: 'Browse unlisted YouTube videos from Management',
              cta: 'Watch Videos',
            ),
          ],
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text('Alerts', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/trainer/alerts'), child: const Text('View all', style: TextStyle(fontSize: 11.5))),
          ]),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < alerts.take(3).length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 48, endIndent: 16, color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB)),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 18,
                      color: alerts[i]['type'] == 'URGENT' ? AppColors.danger : AppColors.warning,
                    ),
                    title: Text(alerts[i]['schoolName'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                    subtitle: Text(alerts[i]['message'] as String, style: TextStyle(fontSize: 11, color: s.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
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
        const SizedBox(height: 20),
        Text('My Schools', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 8),
        if (schools.isEmpty)
          const EmptyView(title: 'No schools assigned yet', icon: Icons.school)
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < schools.take(5).length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 52, endIndent: 16, color: dark ? const Color(0xFF262E3D) : const Color(0xFFE5E7EB)),
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchoolDetailScreen(school: schools[i]))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: AppColors.roleColor('TRAINER').withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: HugeIcon(icon: HugeIcons.strokeRoundedSchool, size: 17, color: AppColors.roleColor('TRAINER')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(schools[i]['name'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: s.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${schools[i]['district']} · ${schools[i]['teacherCount']} teachers · ${schools[i]['studentCount']} students', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              ],
                            ),
                          ),
                          SchoolStatusBadge(mii: schools[i]['miiScore'] as int? ?? 0),
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
