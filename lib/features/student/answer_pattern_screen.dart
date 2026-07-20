import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

class AnswerPatternScreen extends StatelessWidget {
  const AnswerPatternScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Answer Pattern',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getAnswerPatterns,
        builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

const _fields = [
  ('points', 'Point-to-point working'),
  ('accurateAnswer', 'Complete, accurate answer'),
];

class _BodyState extends State<_Body> {
  Future<void> _openForm() async {
    final chapterCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final controllers = {for (final f in _fields) f.$1: TextEditingController()};
    var submitting = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Answer Pattern', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Chapter', controller: chapterCtrl),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Question', controller: questionCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    for (final f in _fields) ...[
                      AppTextField(label: f.$2, controller: controllers[f.$1]!, maxLines: 3),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)), const SizedBox(height: 10)],
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        if (chapterCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter the chapter.');
                          return;
                        }
                        if (questionCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter the question.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.submitAnswerPattern(
                            chapter: chapterCtrl.text.trim(),
                            question: questionCtrl.text.trim(),
                            points: controllers['points']!.text.trim(),
                            accurateAnswer: controllers['accurateAnswer']!.text.trim(),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await widget.refresh();
                        } catch (e) {
                          setSheetState(() {
                            submitting = false;
                            error = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Stack(
      children: [
        widget.list.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No answer patterns yet', subtitle: 'Write a structured answer after each chapter.', icon: LucideIcons.fileText)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['chapter'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                          Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                          const SizedBox(height: 6),
                          if ((e['question'] as String?)?.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text('Q: ${e['question']}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                            ),
                          for (final f in _fields)
                            if ((e[f.$1] as String?)?.isNotEmpty ?? false)
                              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('${f.$2}: ${e[f.$1]}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_answer_pattern', backgroundColor: AppColors.saffron500, onPressed: _openForm, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
