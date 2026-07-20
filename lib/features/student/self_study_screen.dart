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

const List<Map<String, String>> _kUplcSteps = [
  {'key': 'understand', 'letter': 'U', 'label': 'Understand', 'hint': 'What did you understand after reading the chapter?'},
  {'key': 'problem', 'letter': 'P', 'label': 'Problem', 'hint': 'What problem or question came to mind?'},
  {'key': 'learning', 'letter': 'L', 'label': 'Learning', 'hint': 'What did you learn for life and for your studies?'},
  {'key': 'communicate', 'letter': 'C', 'label': 'Communicate', 'hint': 'Summarize it in your own words — the complete picture.'},
];

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

Future<void> _showAddChapterSheet(BuildContext context, StudentRepository repo, Future<void> Function() refresh) async {
  final subjectController = TextEditingController();
  final topicController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final s = sheetContext.surface;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a chapter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: s.textPrimary)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Mathematics'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: topicController,
                  decoration: const InputDecoration(labelText: 'Chapter title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            setSheetState(() => saving = true);
                            try {
                              await repo.addStudyChapter(subject: subjectController.text.trim(), topic: topicController.text.trim());
                              await refresh();
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            } catch (e) {
                              setSheetState(() => saving = false);
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add chapter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> modules;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.modules, required this.repo, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final activeCount = modules.where((m) => m['status'] == 'active').length;
    final doneCount = modules.where((m) => m['status'] == 'done').length;

    final header = <Widget>[
      Row(
        children: [
          Expanded(
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$activeCount', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.saffron600)),
                  Text('In Progress', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: s.textMuted, letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$doneCount', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                  Text('Chapters Done', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: s.textMuted, letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.bookOpen, size: 16, color: AppColors.saffron600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'UPLC self-study: read the chapter, then write what you took from it — Understand, Problem, Learning and Communicate. '
                'A chapter is done once all four are filled in.',
                style: TextStyle(fontSize: 11.5, height: 1.4, fontWeight: FontWeight.w600, color: s.textSecondary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showAddChapterSheet(context, repo, refresh),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add a chapter'),
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (modules.isEmpty) {
      return ListView(
        children: [
          ...header,
          const SizedBox(height: 40),
          EmptyView(
            title: 'No chapters yet',
            subtitle: 'Add a chapter to start your first UPLC self-study.',
            icon: LucideIcons.bookOpen,
          ),
        ],
      );
    }

    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: 1 + modules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final widget = i == 0
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: header)
              : _ChapterCard(module: modules[i - 1], repo: repo, refresh: refresh);
          return AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 380),
            child: SlideAnimation(verticalOffset: 22, curve: Curves.easeOutCubic, child: FadeInAnimation(child: widget)),
          );
        },
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  final Map<String, dynamic> module;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _ChapterCard({required this.module, required this.repo, required this.refresh});

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  late bool _expanded = widget.module['status'] == 'active';
  late final Map<String, TextEditingController> _controllers = {
    for (final step in _kUplcSteps) step['key']!: TextEditingController(text: widget.module[step['key']] as String? ?? ''),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateStudyReflection(
        moduleId: widget.module['id'] as int,
        understand: _controllers['understand']!.text,
        problem: _controllers['problem']!.text,
        learning: _controllers['learning']!.text,
        communicate: _controllers['communicate']!.text,
      );
      await widget.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final m = widget.module;
    final isDone = m['status'] == 'done';
    final filledCount = _controllers.values.where((c) => c.text.trim().isNotEmpty).length;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF059669).withValues(alpha: 0.1) : s.surfaceVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isDone ? 'Done' : '$filledCount/4',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDone ? const Color(0xFF059669) : s.textMuted),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(LucideIcons.chevronDown, size: 16, color: s.textMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: s.border, height: 1),
                  const SizedBox(height: 14),
                  ..._kUplcSteps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(step['letter']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))),
                              ),
                              const SizedBox(width: 8),
                              Text(step['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _controllers[step['key']],
                            maxLines: 2,
                            style: TextStyle(fontSize: 13, color: s.textPrimary),
                            decoration: InputDecoration(hintText: step['hint'], isDense: true),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(LucideIcons.check, size: 15),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
