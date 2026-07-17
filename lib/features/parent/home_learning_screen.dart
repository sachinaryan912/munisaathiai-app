import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'parent_repository.dart';
import 'selected_child_provider.dart';
import 'widgets/child_switcher.dart';
import 'widgets/link_child_panel.dart';

class ParentHomeLearningScreen extends StatefulWidget {
  const ParentHomeLearningScreen({super.key});

  @override
  State<ParentHomeLearningScreen> createState() => _ParentHomeLearningScreenState();
}

class _ParentHomeLearningScreenState extends State<ParentHomeLearningScreen> {
  final _repo = ParentRepository();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int? _lastChildId;
  bool _childrenLoaded = false;

  Future<void> _load(int? childId) async {
    setState(() => _loading = true);
    try {
      _data = await _repo.getHomeLearning(childId);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int id) async {
    final thisWeek = (_data!['thisWeek'] as List).cast<Map<String, dynamic>>();
    setState(() {
      final idx = thisWeek.indexWhere((a) => a['id'] == id);
      if (idx != -1) thisWeek[idx] = {...thisWeek[idx], 'done': !(thisWeek[idx]['done'] as bool)};
      _data!['doneThisWeek'] = thisWeek.where((a) => a['done'] == true).length;
    });
    try {
      await _repo.toggleHomeLearning(id);
    } catch (_) {
      if (!mounted) return;
      _load(context.read<SelectedChildProvider>().selectedChildId);
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
      title: 'Ghar Ek Pathshala',
      body: childProvider.loading || _loading
          ? const LoadingView(message: 'Loading Ghar Ek Pathshala...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load(childProvider.selectedChildId))
              : (_data?['linked'] == false)
                  ? const NotLinkedState(message: 'Link your child to start Ghar Ek Pathshala')
                  : _Body(data: _data!, onToggle: _toggle),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<int> onToggle;
  const _Body({required this.data, required this.onToggle});

  String _formatWeek(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final end = d.add(const Duration(days: 6));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} – ${end.day} ${months[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final thisWeek = (data['thisWeek'] as List? ?? []).cast<Map<String, dynamic>>();
    final doneThisWeek = data['doneThisWeek'] as num? ?? 0;
    final totalThisWeek = data['totalThisWeek'] as num? ?? 0;
    final history = (data['history'] as List? ?? []).cast<Map<String, dynamic>>();
    final participationScore = data['participationScore'] as int? ?? 0;
    final pct = totalThisWeek == 0 ? 0.0 : (doneThisWeek / totalThisWeek).clamp(0, 1).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const ChildSwitcher(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.saffron500, AppColors.saffron400, AppColors.saffron300], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [Icon(LucideIcons.heart, color: Colors.white, size: 20), SizedBox(width: 8), Text('Ghar Ek Pathshala', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))]),
              const SizedBox(height: 8),
              const Text("Your home is your child's second school. Complete home learning activities every week to earn participation points.", style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)))),
                  const SizedBox(width: 10),
                  Text('$doneThisWeek/$totalThisWeek', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text("This Week's Activities", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (thisWeek.isEmpty)
          Text('No activities yet.', style: TextStyle(fontSize: 12.5, color: s.textMuted))
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: thisWeek.map((a) {
                final done = a['done'] as bool? ?? false;
                return ListTile(
                  onTap: () => onToggle(a['id'] as int),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: done ? AppColors.success : s.textMuted, size: 22),
                  title: Text(a['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, decoration: done ? TextDecoration.lineThrough : null, color: done ? s.textMuted : s.textPrimary)),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 22),
        Text('Weekly Participation History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Text('No history yet — complete this week\'s activities to start your record.', style: TextStyle(fontSize: 12.5, color: s.textMuted))
        else
          SectionCard(
            child: Column(
              children: history.map((w) {
                final done = w['done'] as num? ?? 0;
                final total = w['total'] as num? ?? 0;
                final completed = w['completed'] as bool? ?? false;
                final ratio = total == 0 ? 0.0 : (done / total).clamp(0, 1).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Week of ${_formatWeek(w['weekStart'] as String)}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                            const SizedBox(height: 4),
                            ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$done/$total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: s.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: completed ? const Color(0xFFD1FAE5) : AppColors.saffron100, borderRadius: BorderRadius.circular(99)),
                        child: Text(completed ? 'Completed' : 'In Progress', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: completed ? const Color(0xFF059669) : AppColors.saffron700)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        Text('Your Parent Participation Score: $participationScore/10', style: TextStyle(fontSize: 12, color: s.textMuted)),
      ],
    );
  }
}
