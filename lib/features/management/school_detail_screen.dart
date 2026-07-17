import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/section_card.dart';
import 'management_repository.dart';
import 'widgets/school_form_sheet.dart';
import 'widgets/school_status_widgets.dart';

class SchoolDetailScreen extends StatefulWidget {
  final int schoolId;
  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  final _repo = ManagementRepository();
  bool _recomputing = false;

  Future<void> _recompute(Future<void> Function() refresh) async {
    setState(() => _recomputing = true);
    try {
      await _repo.recomputeMii(widget.schoolId);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _recomputing = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> school, Future<void> Function() refresh) async {
    final payload = await showSchoolFormSheet(context, existing: school);
    if (payload == null) return;
    try {
      await _repo.updateSchool(widget.schoolId, payload);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove school?'),
        content: const Text('This will deactivate the school. This action can be reversed by an administrator.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteSchool(widget.schoolId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncScreen<Map<String, dynamic>>(
      loader: () => _repo.getSchool(widget.schoolId),
      builder: (context, school, refresh) {
        final s = context.surface;
        return Scaffold(
          appBar: AppBar(
            title: Text(school['name'] as String),
            actions: [
              IconButton(icon: const Icon(LucideIcons.pencil, size: 19), onPressed: () => _edit(school, refresh)),
              IconButton(icon: const Icon(LucideIcons.trash2, size: 19, color: AppColors.danger), onPressed: _delete),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${school['district']} · ${school['phase']}', style: TextStyle(fontSize: 12, color: s.textMuted)),
                          const SizedBox(height: 6),
                          Text('Trainer: ${school['trainer']}', style: TextStyle(fontSize: 12, color: s.textSecondary)),
                          Text('${school['teacherCount']} teachers · ${school['studentCount']} students · ${school['classCount']} classes', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                        ],
                      ),
                    ),
                    SchoolStatusBadge(mii: school['miiScore'] as int? ?? 0, status: school['status'] as String?),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _recomputing ? null : () => _recompute(refresh),
                  icon: _recomputing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.refreshCw, size: 15),
                  label: Text(_recomputing ? 'Recomputing...' : 'Recompute MII from real activity'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(height: 22),
              Text('MII Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SectionCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ('Training', school['trainingScore'], 15), ('Classroom', school['classroomScore'], 25),
                    ('Evidence', school['evidenceScore'], 10), ('Participation', school['participationScore'], 15),
                    ('Buddy/GRS', school['buddyGrsScore'], 10), ('Parent', school['parentScore'], 10),
                    ('Academic', school['academicScore'], 10), ('Reporting', school['reportingScore'], 5),
                  ].map((f) => _ScorePill(label: f.$1, value: f.$2 as int? ?? 0, max: f.$3)).toList(),
                ),
              ),
              const SizedBox(height: 22),
              Text('MII Score Trend', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              _MiiTrendCard(repo: _repo, schoolId: widget.schoolId),
              const SizedBox(height: 22),
              Text('Methodology Scores', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  children: ((school['methodologyScores'] as List? ?? []).cast<Map<String, dynamic>>()).map((m) {
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
              ),
              const SizedBox(height: 22),
              Text('Training Sessions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              _SessionsCard(repo: _repo, schoolId: widget.schoolId),
            ],
          ),
        );
      },
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _ScorePill({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text('$value/$max', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
          Text(label, style: TextStyle(fontSize: 9.5, color: s.textMuted)),
        ],
      ),
    );
  }
}

class _MiiTrendCard extends StatelessWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _MiiTrendCard({required this.repo, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getMiiHistory(schoolId),
      builder: (context, snap) {
        final s = context.surface;
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final history = snap.data!;
        if (history.length < 2) {
          return SectionCard(child: Text('Not enough history yet — recompute MII on different days to build a trend.', style: TextStyle(fontSize: 12, color: s.textMuted)));
        }
        return SectionCard(
          child: SizedBox(
            height: 150,
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
                      interval: (history.length / 4).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= history.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6), child: Text((history[i]['date'] as String).substring(5), style: TextStyle(fontSize: 8.5, color: s.textMuted)));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(history.length, (i) => FlSpot(i.toDouble(), (history[i]['score'] as num).toDouble())),
                    isCurved: true,
                    color: AppColors.saffron500,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppColors.saffron400.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionsCard extends StatelessWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _SessionsCard({required this.repo, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getSchoolTrainingSessions(schoolId),
      builder: (context, snap) {
        final s = context.surface;
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final sessions = snap.data!;
        if (sessions.isEmpty) return SectionCard(child: Text('No training sessions recorded yet.', style: TextStyle(fontSize: 12, color: s.textMuted)));
        return SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: sessions.map((sess) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  title: Text(sess['topic'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                  subtitle: Text('${sess['trainerName']} · ${sess['date']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                  trailing: Text('${sess['attendedCount']}/${sess['attendeeCount']}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                )).toList(),
          ),
        );
      },
    );
  }
}
