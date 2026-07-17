import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'My Progress',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getProgress,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [90, 160, 140, 100, 120]),
        builder: (context, data, refresh) => _Body(data: data),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final overallScore = data['overallScore'] as int? ?? 0;
    final classRank = data['classRank'] as Map<String, dynamic>?;
    final attendance = data['attendancePercent'] as int?;
    final milestones = data['milestonesCount'] as num? ?? 0;
    final subjects = (data['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();
    final trend = (data['weeklyScoreTrend'] as List? ?? []).cast<Map<String, dynamic>>();
    final notes = (data['teacherNotes'] as List? ?? []).cast<Map<String, dynamic>>();
    final badges = (data['badges'] as List? ?? []).cast<Map<String, dynamic>>();

    final sections = <Widget>[
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          StatTile(label: 'Overall Score', value: '$overallScore%', icon: LucideIcons.trendingUp, color: AppColors.saffron500, animateIndex: 0),
          StatTile(label: 'Class Rank', value: classRank != null ? '#${classRank['rank']}' : '—', sublabel: classRank != null ? 'of ${classRank['total']}' : null, icon: LucideIcons.award, color: const Color(0xFF6366F1), animateIndex: 1),
          StatTile(label: 'Attendance', value: attendance != null ? '$attendance%' : '—', icon: LucideIcons.calendarCheck, color: const Color(0xFF10B981), animateIndex: 2),
          StatTile(label: 'Milestones', value: '$milestones', icon: LucideIcons.medal, color: const Color(0xFF8B5CF6), animateIndex: 3),
        ],
      ),
      if (trend.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Score Trend', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const SizedBox(height: 10),
            SectionCard(
              child: SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(trend[i]['label'] as String, style: TextStyle(fontSize: 9, color: s.textMuted)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), (trend[i]['score'] as num).toDouble())),
                        isCurved: true,
                        color: AppColors.saffron500,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppColors.saffron400.withValues(alpha: 0.15)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      if (subjects.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const SizedBox(height: 10),
            SectionCard(
              child: Column(
                children: subjects.map((subj) {
                  final score = subj['score'] as int? ?? 0;
                  final classAvg = subj['classAvg'] as int? ?? 0;
                  final aboveAvg = subj['aboveAvg'] as bool? ?? false;
                  final recent = subj['recentAssignment'] as Map<String, dynamic>?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(subj['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary))),
                            Icon(aboveAvg ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 13, color: aboveAvg ? AppColors.success : AppColors.warning),
                            const SizedBox(width: 4),
                            Text('$score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400))),
                            Positioned(
                              left: (classAvg / 100).clamp(0, 1) * (MediaQuery.of(context).size.width - 68),
                              child: Container(width: 2, height: 7, color: s.textPrimary.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Class avg: $classAvg', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                        if (recent != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Latest: ${recent['title']} — ${recent['marks']}/100 (${recent['grade']})', style: TextStyle(fontSize: 10.5, color: AppColors.saffron600, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      if (badges.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(LucideIcons.award, size: 15, color: AppColors.saffron500),
              const SizedBox(width: 6),
              Text('My Badges', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            ]),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: badges.map((b) {
                final earned = b['earned'] as bool? ?? false;
                return GestureDetector(
                  onTap: () => _showBadgeDetail(context, b),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: earned ? AppColors.saffron50 : s.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: earned ? AppColors.saffron200 : s.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(opacity: earned ? 1 : 0.35, child: Text(b['icon'] as String? ?? '🏅', style: const TextStyle(fontSize: 24))),
                        const SizedBox(height: 6),
                        Text(b['name'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: earned ? AppColors.saffron700 : s.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teacher Notes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            const SectionCard(child: EmptyView(title: 'No notes yet', subtitle: 'Your teacher hasn\'t left any notes.', icon: LucideIcons.notebookPen))
          else
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: notes.map((n) {
                  final teacher = n['teacher'] as Map<String, dynamic>?;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: const CircleAvatar(radius: 16, backgroundColor: AppColors.saffron100, child: Icon(LucideIcons.notebookPen, size: 14, color: AppColors.saffron700)),
                    title: Text(n['content'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary, height: 1.4)),
                    subtitle: Text('${teacher?['fullName'] ?? 'Teacher'} · ${timeAgo(DateTime.tryParse(n['createdAt'] as String? ?? ''))}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ];

    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 22),
        itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(verticalOffset: 26, curve: Curves.easeOutCubic, child: FadeInAnimation(child: sections[i])),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Map<String, dynamic> badge) {
    final earned = badge['earned'] as bool? ?? false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: Text(badge['icon'] as String? ?? '🏅', style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 14),
              Text(badge['name'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
              const SizedBox(height: 4),
              Text(earned ? '★ You earned this badge!' : '☆ Not earned yet — keep going!', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron600, letterSpacing: 0.3)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(16)),
                child: Text(badge['desc'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}
