import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/greeting_header.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stat_tile.dart';
import '../shell/app_shell.dart';
import 'parent_repository.dart';
import 'selected_child_provider.dart';
import 'widgets/child_switcher.dart';
import 'widgets/link_child_panel.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _repo = ParentRepository();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int? _lastChildId;
  bool _childrenLoaded = false;

  Future<void> _load(int? childId) async {
    setState(() => _loading = true);
    try {
      _data = await _repo.getDashboard(childId);
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
      title: '',
      body: childProvider.loading || _loading
          ? const LoadingView(message: 'Loading dashboard...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load(childProvider.selectedChildId))
              : (_data?['linked'] == false)
                  ? const NotLinkedState(message: "Link your child to see their dashboard")
                  : RefreshIndicator(
                      color: AppColors.saffron500,
                      onRefresh: () => _load(childProvider.selectedChildId),
                      child: _Body(data: _data!),
                    ),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Body({required this.data});

  static const _statColors = [AppColors.saffron500, Color(0xFF6366F1), Color(0xFF10B981), Color(0xFF8B5CF6)];

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final stats = (data['stats'] as List? ?? []).cast<Map<String, dynamic>>();
    final overallScore = data['overallScore'] as int? ?? 0;
    final childName = data['childName'] as String? ?? '';
    final childClass = data['childClass'] as String?;
    final subjects = (data['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();
    final homeLearning = (data['homeLearningThisWeek'] as List? ?? []);
    final doneThisWeek = data['doneThisWeek'] as num? ?? 0;
    final totalThisWeek = data['totalThisWeek'] as num? ?? 0;
    final participationScore = data['participationScore'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const GreetingHeader(subtitle: 'Here\'s how your child is doing today.'),
        const SizedBox(height: 18),
        const ChildSwitcher(),
        const SizedBox(height: 16),
        SectionCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ProgressRing(value: overallScore, color: AppColors.saffron500, subLabel: 'Score', radius: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(childName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    if (childClass != null) Text(childClass, style: TextStyle(fontSize: 12, color: s.textMuted)),
                    const SizedBox(height: 6),
                    Text('Ghar Ek Pathshala: $doneThisWeek/$totalThisWeek this week · Participation $participationScore/10', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
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
          childAspectRatio: 1.35,
          children: List.generate(stats.length, (i) {
            final st = stats[i];
            return StatTile(label: st['label'] as String, value: st['value'] as String, icon: lucideByName(st['icon'] as String?), color: _statColors[i % _statColors.length], animateIndex: i);
          }),
        ),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: subjects.map((subj) {
                final score = subj['score'] as int? ?? 0;
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
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (homeLearning.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text("This Week's Ghar Ek Pathshala", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: homeLearning.cast<Map<String, dynamic>>().map((a) {
                final done = a['done'] as bool? ?? false;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? AppColors.success : s.textMuted, size: 20),
                  title: Text(a['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, decoration: done ? TextDecoration.lineThrough : null, color: done ? s.textMuted : s.textPrimary)),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
