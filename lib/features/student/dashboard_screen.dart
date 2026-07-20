import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/badge_detail_sheet.dart';
import '../../core/widgets/section_card.dart';
import '../action_plans/action_plan_sheet.dart';
import '../auth/data/auth_provider.dart';
import '../shared/community_hub_screen.dart';
import '../shared/ptm_file_screen.dart';
import '../shared/timetable_screen.dart';
import '../shell/app_shell.dart';
import 'progress_chart_screen.dart';
import 'self_growth_hub_screen.dart';
import 'student_repository.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/quick_access_card.dart';
import 'widgets/student_speed_dial.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: '',
      showAiFab: false,
      isDashboard: true,
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getDashboard,
        loadingBuilder: (context) => const DashboardSkeleton(),
        builder: (context, data, refresh) => _DashboardBody(data: data, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _DashboardBody({required this.data, required this.repo, required this.refresh});

  static const _statColors = [AppColors.saffron500, Color(0xFF6366F1), Color(0xFF10B981), Color(0xFF8B5CF6)];

  @override
  Widget build(BuildContext context) {
    final stats = (data['stats'] as List).cast<Map<String, dynamic>>();
    final overallScore = data['overallScore'] as int? ?? 0;
    final buddySessionsCount = data['buddySessionsCount'] as num? ?? 0;
    final subjects = (data['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();
    final badges = (data['badges'] as List? ?? []).cast<Map<String, dynamic>>();
    final activity = (data['recentActivity'] as List? ?? []).cast<Map<String, dynamic>>();
    final selfStudy = data['selfStudySummary'] as Map<String, dynamic>? ?? {};
    final assignments = data['assignmentsSummary'] as Map<String, dynamic>? ?? {};
    final peerTeaching = data['peerTeachingSummary'] as Map<String, dynamic>? ?? {};
    final feedback = data['feedbackSummary'] as Map<String, dynamic>? ?? {};

    final sections = <Widget>[
      _HeroCard(overallScore: overallScore),
      _StatsRow(stats: stats, colors: _statColors),
      _QuickAccessGrid(selfStudy: selfStudy, assignments: assignments, peerTeaching: peerTeaching, feedback: feedback),
      _BuddyCard(sessionsCount: buddySessionsCount.toInt()),
      if (subjects.isNotEmpty) _SubjectsCard(subjects: subjects),
      if (badges.isNotEmpty) _BadgesRow(badges: badges),
      if (activity.isNotEmpty) _ActivityCard(activity: activity),
      const _AiPromoCard(),
    ];

    return Stack(
      children: [
        AnimationLimiter(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, i) {
              return AnimationConfiguration.staggeredList(
                position: i,
                duration: const Duration(milliseconds: 420),
                child: SlideAnimation(
                  verticalOffset: 28,
                  curve: Curves.easeOutCubic,
                  child: FadeInAnimation(child: sections[i]),
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: StudentSpeedDial(repo: repo, onDone: refresh),
        ),
      ],
    );
  }
}

// ── Hero progress card ──────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final int overallScore;
  const _HeroCard({required this.overallScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.saffron500, AppColors.saffron400, AppColors.saffron300], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.saffron500.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('My Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "You've finished $overallScore% of your learning goals this month. Well done! 🎉",
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (overallScore / 100).clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 10, backgroundColor: Colors.white.withValues(alpha: 0.28), valueColor: const AlwaysStoppedAnimation(Colors.white)),
            ),
          ),
          const SizedBox(height: 6),
          Text('$overallScore / 100 points', style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/student/progress'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See My Progress', style: TextStyle(color: AppColors.saffron600, fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: AppColors.saffron600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> stats;
  final List<Color> colors;
  const _StatsRow({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
      itemBuilder: (context, i) {
        final st = stats[i];
        final color = colors[i % colors.length];
        return SectionCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(st['label'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: s.textSecondary)),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                    child: Icon(lucideByName(st['icon'] as String?), size: 13, color: color),
                  ),
                ],
              ),
              Text(st['value'] as String, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: s.textPrimary)),
            ],
          ),
        );
      },
    );
  }
}

// ── Quick access grid ───────────────────────────────────────────────────────
class _QuickAccessGrid extends StatelessWidget {
  final Map<String, dynamic> selfStudy;
  final Map<String, dynamic> assignments;
  final Map<String, dynamic> peerTeaching;
  final Map<String, dynamic> feedback;
  const _QuickAccessGrid({required this.selfStudy, required this.assignments, required this.peerTeaching, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final myId = context.watch<AuthProvider>().user?.id;
    final totalCount = selfStudy['totalCount'] as int? ?? 0;
    final selfStudySubtitle = totalCount > 0
        ? '${selfStudy['doneCount']}/$totalCount chapters (UPLC) · ${selfStudy['activeCount']} in progress'
        : 'Start your first UPLC self-study chapter!';

    final assignCount = assignments['count'] as int? ?? 0;
    final assignSubtitle = assignCount > 0 ? 'Last: ${assignments['latestSubject']} — ${assignments['latestMarks']}/100 (${assignments['latestGrade']})' : 'No assignments checked yet — try one!';

    final peerCount = peerTeaching['count'] as int? ?? 0;
    final peerSubtitle = peerCount > 0 ? '$peerCount sessions · taught ${peerTeaching['studentsTaught']} friends' : 'Teach a friend something new today!';

    final fbCount = feedback['count'] as int? ?? 0;
    final fbSubtitle = fbCount > 0 ? '$fbCount messages sent to your teacher' : 'Tell your teacher what you think!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            QuickAccessCard(route: '/student/study', icon: LucideIcons.bookOpen, color: const Color(0xFF6366F1), title: 'Self Study', subtitle: selfStudySubtitle, cta: 'Continue Learning'),
            QuickAccessCard(route: '/student/assignments', icon: LucideIcons.fileCheck, color: const Color(0xFF10B981), title: 'Assignments', subtitle: assignSubtitle, cta: 'Check My Work'),
            QuickAccessCard(route: '/student/peer-teaching', icon: LucideIcons.graduationCap, color: const Color(0xFFF43F5E), title: 'Peer Teaching', subtitle: peerSubtitle, cta: 'Teach a Friend'),
            QuickAccessCard(route: '/student/feedback', icon: LucideIcons.heart, color: const Color(0xFFEC4899), title: 'Feedback', subtitle: fbSubtitle, cta: 'Share Feedback'),
            QuickAccessCard(
              onTap: () => showMyActionPlansSheet(context),
              icon: LucideIcons.clipboardList,
              color: const Color(0xFF0EA5E9),
              title: 'Action Plan',
              subtitle: 'Tasks and follow-ups assigned to you',
              cta: 'View Tasks',
            ),
            QuickAccessCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubScreen())),
              icon: LucideIcons.globe,
              color: const Color(0xFF14B8A6),
              title: 'Community Hub',
              subtitle: 'Wakeup Call Board, events, workshops & clubs',
              cta: 'Explore',
            ),
            QuickAccessCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimetableScreen(title: 'My Timetable'))),
              icon: LucideIcons.calendarClock,
              color: const Color(0xFFF59E0B),
              title: 'Timetable',
              subtitle: 'Your weekly class timetable',
              cta: 'View Timetable',
            ),
            QuickAccessCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressChartScreen())),
              icon: LucideIcons.trendingUp,
              color: const Color(0xFF8B5CF6),
              title: 'Progress Chart',
              subtitle: 'Track your self-competition over time',
              cta: 'View Chart',
            ),
            if (myId != null)
              QuickAccessCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PtmFileScreen(studentId: myId))),
                icon: LucideIcons.fileText,
                color: const Color(0xFFEF4444),
                title: 'PTM File',
                subtitle: 'Your consolidated parent-teacher meeting report',
                cta: 'Open File',
              ),
            SectionCard(
              padding: const EdgeInsets.all(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelfGrowthHubScreen())),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFF8B5CF6))),
                  const SizedBox(height: 10),
                  Text('Self-Growth Journal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                  const SizedBox(height: 3),
                  Text('Reflection tools from the Muni Model', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: s.textSecondary, height: 1.3, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('Explore', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF8B5CF6))),
                    const SizedBox(width: 3),
                    const Icon(LucideIcons.chevronRight, size: 12, color: Color(0xFF8B5CF6)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Buddy card ───────────────────────────────────────────────────────────────
class _BuddyCard extends StatelessWidget {
  final int sessionsCount;
  const _BuddyCard({required this.sessionsCount});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFBBF24), AppColors.saffron500]), shape: BoxShape.circle),
            child: const Icon(LucideIcons.users, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('My Group', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(99)),
                      child: Text('$sessionsCount sessions', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.saffron700)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  sessionsCount > 0 ? 'Keep studying together!' : 'Study with a classmate and log it!',
                  style: TextStyle(fontSize: 11, color: s.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () => context.go('/student/buddy'), icon: Icon(LucideIcons.chevronRight, color: s.textMuted)),
        ],
      ),
    );
  }
}

// ── Subjects card ────────────────────────────────────────────────────────────
class _SubjectsCard extends StatelessWidget {
  final List<Map<String, dynamic>> subjects;
  const _SubjectsCard({required this.subjects});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        SectionCard(
          child: Column(
            children: subjects.map((subj) {
              final score = subj['score'] as int? ?? 0;
              final target = subj['target'] as int? ?? 100;
              final pct = target == 0 ? 0.0 : (score / target).clamp(0, 1).toDouble();
              final barColor = score >= 80 ? AppColors.success : score >= 65 ? const Color(0xFF6366F1) : AppColors.warning;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(subj['name'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary))),
                        Text('$score%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: s.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: s.border, valueColor: AlwaysStoppedAnimation(barColor)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Badges row ───────────────────────────────────────────────────────────────
class _BadgesRow extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  const _BadgesRow({required this.badges});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Badges', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const SizedBox(width: 8),
            Text('${badges.where((b) => b['earned'] == true).length}/${badges.length} earned', style: TextStyle(fontSize: 11, color: s.textMuted, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final b = badges[i];
              final earned = b['earned'] as bool? ?? false;
              return GestureDetector(
                onTap: () => showBadgeDetail(context, b),
                child: Container(
                width: 88,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: earned ? const LinearGradient(colors: [AppColors.saffron50, Color(0xFFFFEFD4)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                  color: earned ? null : s.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: earned ? AppColors.saffron200 : s.border),
                  boxShadow: earned ? [BoxShadow(color: AppColors.saffron300.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(opacity: earned ? 1 : 0.32, child: Text(b['icon'] as String? ?? '🏅', style: const TextStyle(fontSize: 26))),
                    const SizedBox(height: 6),
                    Text(
                      b['name'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: earned ? AppColors.saffron700 : s.textMuted),
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Recent activity ──────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(LucideIcons.clock, size: 15, color: AppColors.saffron500), const SizedBox(width: 6), Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary))]),
        const SizedBox(height: 10),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: activity.map((a) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(lucideByName(a['icon'] as String?), size: 16, color: AppColors.saffron600),
                ),
                title: Text(a['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: s.textPrimary)),
                subtitle: Text(a['subtitle'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                trailing: Text(a['date'] as String, style: TextStyle(fontSize: 10, color: s.textMuted)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── AI promo card ─────────────────────────────────────────────────────────────
class _AiPromoCard extends StatelessWidget {
  const _AiPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Image.asset(
              'assets/images/divya.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 96,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.08, duration: 1200.ms, curve: Curves.easeInOut),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vidya — Your AI Companion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 3),
                Text('Ask for a quiz, clarify a topic, or get study help.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, height: 1.4, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/student/ai'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Text('Chat', style: TextStyle(color: Color(0xFF6D28D9), fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
