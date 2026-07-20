import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'trainer_repository.dart';

const _statusColors = {
  'Active': Color(0xFF10B981), 'Needs Support': Color(0xFFF59E0B), 'Inactive': Color(0xFFEF4444),
};

class TrainerTeachersScreen extends StatefulWidget {
  const TrainerTeachersScreen({super.key});

  @override
  State<TrainerTeachersScreen> createState() => _TrainerTeachersScreenState();
}

class _TrainerTeachersScreenState extends State<TrainerTeachersScreen> {
  final _repo = TrainerRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Teachers',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: () => _repo.getTeachers(),
        builder: (context, allTeachers, refresh) {
          if (allTeachers.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No teachers found', icon: LucideIcons.users)]);
          }
          final q = _query.trim().toLowerCase();
          final teachers = q.isEmpty
              ? allTeachers
              : allTeachers.where((t) {
                  return (t['name'] as String? ?? '').toLowerCase().contains(q) ||
                      (t['schoolName'] as String? ?? '').toLowerCase().contains(q) ||
                      (t['status'] as String? ?? '').toLowerCase().contains(q);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListSearchField(controller: _searchCtrl, hint: 'Search by name, school or status', onChanged: (v) => setState(() => _query = v)),
              ),
              Expanded(
                child: teachers.isEmpty
                    ? const EmptyView(title: 'No teachers match your search', icon: LucideIcons.users)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        itemCount: teachers.length,
                        itemBuilder: (context, i) => _TeacherCard(teacher: teachers[i], repo: _repo)
                            .animate(delay: (i * 40).ms)
                            .fadeIn(duration: 280.ms)
                            .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherCard extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final TrainerRepository repo;
  const _TeacherCard({required this.teacher, required this.repo});

  @override
  State<_TeacherCard> createState() => _TeacherCardState();
}

class _TeacherCardState extends State<_TeacherCard> {
  bool _loadingFeedback = false;
  Map<String, dynamic>? _feedback;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Show the trainer's own most recent feedback for this teacher, if any — feedback is now
    // persisted server-side, so it should still be here after navigating away and back.
    widget.repo.getTeacherFeedbackHistory(widget.teacher['id'] as int).then((history) {
      if (mounted && history.isNotEmpty) setState(() => _feedback = history.first);
    }).catchError((_) {});
  }

  Future<void> _generateFeedback() async {
    setState(() {
      _loadingFeedback = true;
      _error = null;
    });
    try {
      _feedback = await widget.repo.generateTeacherFeedback(widget.teacher['id'] as int);
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loadingFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final t = widget.teacher;
    final status = t['status'] as String? ?? 'Active';
    final color = _statusColors[status] ?? s.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: AppColors.roleColor('TRAINER'), child: Text((t['name'] as String).isNotEmpty ? (t['name'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                      Text('${t['schoolName'] ?? ''} · Score ${t['score']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingFeedback)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LoadingView(message: 'Generating feedback...'))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 11.5))
            else if (_feedback != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_feedback!['tag'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron600)),
                    const SizedBox(height: 4),
                    Text('✓ ${_feedback!['strength']}', style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                    Text('✗ ${_feedback!['gap']}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                    const SizedBox(height: 4),
                    Text(_feedback!['message'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(onPressed: _generateFeedback, icon: const Icon(LucideIcons.sparkles, size: 14), label: const Text('AI Feedback', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 9))),
              ),
          ],
        ),
      ),
    );
  }
}
