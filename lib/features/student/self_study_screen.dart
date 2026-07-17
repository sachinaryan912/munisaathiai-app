import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

class StudentSelfStudyScreen extends StatelessWidget {
  const StudentSelfStudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Self Study',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getStudyModules,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [130, 130, 130]),
        builder: (context, modules, refresh) => _Body(modules: modules, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> modules;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.modules, required this.repo, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (modules.isEmpty) {
      return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No self-study modules yet', subtitle: 'Your teacher will assign modules here.', icon: LucideIcons.bookOpen)]);
    }
    final active = modules.where((m) => m['status'] == 'active').toList();
    final done = modules.where((m) => m['status'] == 'done').toList();

    final items = <Widget>[
      if (active.isNotEmpty) ...[
        Text('In Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        ...active.map((m) => _ModuleCard(module: m, repo: repo, refresh: refresh)),
      ],
      if (done.isNotEmpty) ...[
        Text('Completed', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        ...done.map((m) => _ModuleCard(module: m, repo: repo, refresh: refresh)),
      ],
    ];

    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 380),
          child: SlideAnimation(verticalOffset: 22, curve: Curves.easeOutCubic, child: FadeInAnimation(child: items[i])),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final Map<String, dynamic> module;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _ModuleCard({required this.module, required this.repo, required this.refresh});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _saving = false;

  Future<void> _setDone(int done) async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateStudyProgress(moduleId: widget.module['id'] as int, done: done);
      await widget.refresh();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final m = widget.module;
    final lessons = m['lessons'] as int? ?? 1;
    final done = m['done'] as int? ?? 0;
    final isDone = m['status'] == 'done';
    final pct = lessons == 0 ? 0.0 : (done / lessons).clamp(0, 1).toDouble();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: isDone ? const Color(0xFFD1FAE5) : AppColors.saffron50, borderRadius: BorderRadius.circular(12)),
                child: Icon(isDone ? LucideIcons.circleCheck : LucideIcons.bookOpen, size: 17, color: isDone ? const Color(0xFF059669) : AppColors.saffron600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['subject'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: s.textMuted, letterSpacing: 0.4)),
                    Text(m['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                  ],
                ),
              ),
              Text('$done/$lessons', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: s.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: s.border, valueColor: AlwaysStoppedAnimation(isDone ? const Color(0xFF10B981) : AppColors.saffron400))),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _saving || done <= 0 ? null : () => _setDone(done - 1),
                icon: const Icon(Icons.remove, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _saving || done >= lessons ? null : () => _setDone(done + 1),
                icon: const Icon(Icons.add, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              if (!isDone)
                TextButton(
                  onPressed: _saving ? null : () => _setDone(lessons),
                  child: const Text('Mark complete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
