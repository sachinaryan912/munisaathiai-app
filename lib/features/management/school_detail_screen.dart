import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
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
  // Bumped after a successful recompute so the MII-trend/timeline sub-cards below (which fetch
  // their own history via initState, not the outer AsyncScreen's refresh) get a new key and
  // remount instead of silently keeping the pre-recompute history on screen.
  int _refreshToken = 0;

  Future<void> _recompute(Future<void> Function() refresh) async {
    setState(() => _recomputing = true);
    try {
      await _repo.recomputeMii(widget.schoolId);
      await refresh();
      if (mounted) setState(() => _refreshToken++);
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
      try {
        await _repo.deleteSchool(widget.schoolId);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
      }
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
                          if (school['implementationStart'] != null)
                            Padding(padding: const EdgeInsets.only(top: 4), child: Text('Muni Model since ${school['implementationStart']}', style: TextStyle(fontSize: 11, color: s.textMuted, fontStyle: FontStyle.italic))),
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
              _MiiTrendCard(key: ValueKey('mii_trend_$_refreshToken'), repo: _repo, schoolId: widget.schoolId),
              const SizedBox(height: 22),
              Text('Implementation Timeline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              _TimelineCard(key: ValueKey('timeline_$_refreshToken'), repo: _repo, schoolId: widget.schoolId, implementationStart: school['implementationStart'] as String?),
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
              const SizedBox(height: 22),
              Text('Class & Section Setup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 4),
              Text('Controls what students and teachers can pick during registration.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 10),
              _ClassCatalogCard(repo: _repo, schoolId: widget.schoolId),
              const SizedBox(height: 22),
              Text('Classes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              _ClassesCard(repo: _repo, schoolId: widget.schoolId),
              const SizedBox(height: 22),
              Text('Teachers', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              _TeachersCard(repo: _repo, schoolId: widget.schoolId),
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

class _MiiTrendCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _MiiTrendCard({super.key, required this.repo, required this.schoolId});

  @override
  State<_MiiTrendCard> createState() => _MiiTrendCardState();
}

class _MiiTrendCardState extends State<_MiiTrendCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getMiiHistory(widget.schoolId);
  }

  void _retry() => setState(() => _future = widget.repo.getMiiHistory(widget.schoolId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _retry);
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

class _TimelineCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  final String? implementationStart;
  const _TimelineCard({super.key, required this.repo, required this.schoolId, this.implementationStart});

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getMiiHistory(widget.schoolId);
  }

  void _retry() => setState(() => _future = widget.repo.getMiiHistory(widget.schoolId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _retry);
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final history = snap.data!;
        final entries = <Map<String, dynamic>>[
          if (widget.implementationStart != null) {'date': widget.implementationStart, 'label': 'Muni Model implementation started'},
          ...history.map((h) => {'date': h['date'], 'score': h['score'], 'status': h['status']}),
        ];
        if (entries.isEmpty) {
          return SectionCard(child: Text('No timeline data yet.', style: TextStyle(fontSize: 12, color: s.textMuted)));
        }
        return SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: entries.map((e) {
              final status = e['status'] as String?;
              final color = status != null ? statusColor(status) : AppColors.saffron500;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                leading: Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                title: Text(e['label'] as String? ?? 'MII recomputed: ${e['score']}/100', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                subtitle: Text('${e['date']}${status != null ? ' · ${statusLabel(status)}' : ''}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _SessionsCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _SessionsCard({required this.repo, required this.schoolId});

  @override
  State<_SessionsCard> createState() => _SessionsCardState();
}

class _SessionsCardState extends State<_SessionsCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getSchoolTrainingSessions(widget.schoolId);
  }

  void _retry() => setState(() => _future = widget.repo.getSchoolTrainingSessions(widget.schoolId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _retry);
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

class _ClassesCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _ClassesCard({required this.repo, required this.schoolId});

  @override
  State<_ClassesCard> createState() => _ClassesCardState();
}

class _ClassesCardState extends State<_ClassesCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getSchoolClasses(widget.schoolId);
  }

  void _retry() => setState(() => _future = widget.repo.getSchoolClasses(widget.schoolId));

  void _openClass(Map<String, dynamic> cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        final students = (cls['students'] as List? ?? []).cast<Map<String, dynamic>>();
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Text(cls['displayName'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
              Text('Teacher: ${cls['teacherName']}', style: TextStyle(fontSize: 12, color: s.textMuted)),
              const SizedBox(height: 14),
              Flexible(
                child: students.isEmpty
                    ? Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('No students enrolled yet.', style: TextStyle(fontSize: 12, color: s.textMuted)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, i) {
                          final st = students[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(st['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                            subtitle: st['attendancePercent'] != null ? Text('Attendance ${st['attendancePercent']}%', style: TextStyle(fontSize: 11, color: s.textMuted)) : null,
                            trailing: Text('Score ${st['score']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _retry);
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final classes = snap.data!;
        if (classes.isEmpty) return SectionCard(child: Text('No classes recorded yet.', style: TextStyle(fontSize: 12, color: s.textMuted)));
        return SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: classes.map((cls) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  onTap: () => _openClass(cls),
                  title: Text(cls['displayName'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                  subtitle: Text('${cls['teacherName']} · ${cls['studentCount']} students', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                  trailing: Text('Avg ${cls['avgScore']}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                )).toList(),
          ),
        );
      },
    );
  }
}

class _ClassCatalogCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _ClassCatalogCard({required this.repo, required this.schoolId});

  @override
  State<_ClassCatalogCard> createState() => _ClassCatalogCardState();
}

class _ClassCatalogCardState extends State<_ClassCatalogCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getClassCatalog(widget.schoolId);
  }

  void _reload() => setState(() => _future = widget.repo.getClassCatalog(widget.schoolId));

  Future<void> _addEntry() async {
    final classCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    var submitting = false;
    String? error;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Class / Section', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Class: 1-12 or Nursery/LKG/UKG. Section: a single letter, optional.', style: TextStyle(fontSize: 11, color: s.textMuted)),
                  const SizedBox(height: 16),
                  TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'Class', hintText: 'e.g. 5 or LKG')),
                  const SizedBox(height: 12),
                  TextField(controller: sectionCtrl, maxLength: 1, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Section (optional)', hintText: 'e.g. A')),
                  if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 12),
                  GradientButton(
                    label: 'Add',
                    loading: submitting,
                    onPressed: () async {
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await widget.repo.addClassCatalogEntry(
                          widget.schoolId,
                          className: classCtrl.text.trim(),
                          section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                      } catch (e) {
                        setSheetState(() {
                          submitting = false;
                          error = e.toString().replaceFirst('ApiException: ', '');
                        });
                      }
                    },
                    height: 46,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (added == true) _reload();
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final label = entry['section'] != null ? '${entry['className']} ${entry['section']}' : entry['className'] as String;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove class entry?'),
        content: Text('Remove "$label" from this school\'s registration options?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repo.deleteClassCatalogEntry(widget.schoolId, entry['id'] as int);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _reload);
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final entries = snap.data!;
        return SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entries.isEmpty)
                Padding(padding: const EdgeInsets.all(14), child: Text('No classes set up yet — add one so registration can offer it.', style: TextStyle(fontSize: 12, color: s.textMuted)))
              else
                ...entries.map((e) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      title: Text(e['section'] != null ? '${e['className']} · Section ${e['section']}' : e['className'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                      trailing: IconButton(icon: const Icon(LucideIcons.trash2, size: 17, color: AppColors.danger), onPressed: () => _deleteEntry(e)),
                    )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: TextButton.icon(onPressed: _addEntry, icon: const Icon(LucideIcons.plus, size: 15), label: const Text('Add Class / Section')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeachersCard extends StatefulWidget {
  final ManagementRepository repo;
  final int schoolId;
  const _TeachersCard({required this.repo, required this.schoolId});

  @override
  State<_TeachersCard> createState() => _TeachersCardState();
}

class _TeachersCardState extends State<_TeachersCard> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.getSchoolTeachersDrillDown(widget.schoolId);
  }

  void _retry() => setState(() => _future = widget.repo.getSchoolTeachersDrillDown(widget.schoolId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        final s = context.surface;
        if (snap.hasError) return _InlineErrorCard(message: snap.error.toString().replaceFirst('ApiException: ', ''), onRetry: _retry);
        if (!snap.hasData) return const SectionCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2))));
        final teachers = snap.data!;
        if (teachers.isEmpty) return SectionCard(child: Text('No teachers assigned yet.', style: TextStyle(fontSize: 12, color: s.textMuted)));
        return SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: teachers.map((t) {
              final className = t['className'] as String?;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                title: Text(t['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                subtitle: Text(className != null ? '$className ${t['section'] ?? ''} · ${t['status']}' : (t['status'] as String? ?? ''), style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                trailing: Text('${t['score']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SectionCard(
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12, color: s.textMuted))),
          TextButton(onPressed: onRetry, child: const Text('Try again', style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
