import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'parent_repository.dart';
import 'selected_child_provider.dart';
import 'widgets/child_switcher.dart';
import 'widgets/link_child_panel.dart';

class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({super.key});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  final _repo = ParentRepository();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int? _lastChildId;
  bool _childrenLoaded = false;

  Future<void> _load(int? childId) async {
    setState(() => _loading = true);
    try {
      _data = await _repo.getProgress(childId);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<SelectedChildProvider>();
    if (!childProvider.loading && !_childrenLoaded) {
      _childrenLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(childProvider.selectedChildId));
    }
    if (_childrenLoaded && childProvider.selectedChildId != _lastChildId) {
      _lastChildId = childProvider.selectedChildId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(childProvider.selectedChildId));
    }

    return AppShell(
      title: "Child's Progress",
      body: childProvider.loading || _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load(childProvider.selectedChildId))
              : (_data?['linked'] == false)
                  ? const NotLinkedState(message: "Link your child to see their progress")
                  : _Body(data: _data!),
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
    final notes = (data['teacherNotes'] as List? ?? []).cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const ChildSwitcher(),
        const SizedBox(height: 16),
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
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: subjects.map((subj) {
                final score = subj['score'] as int? ?? 0;
                final classAvg = subj['classAvg'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(subj['name'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary))),
                        Text('$score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: s.textPrimary)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400))),
                      const SizedBox(height: 4),
                      Text('Class avg: $classAvg', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Text('Teacher Notes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          const SectionCard(child: EmptyView(title: 'No notes yet', icon: LucideIcons.notebookPen))
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
    );
  }
}
