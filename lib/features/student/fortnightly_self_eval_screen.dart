import 'dart:convert';
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

const _questions = [
  'How am I different from others in my current situation?',
  'Do my family members think the same about me as I think about myself?',
  'Do my friends\' opinion of me match my own opinion of myself?',
  'How is my presence in society and family necessary and beneficial?',
  'Do I believe my future is secure?',
  'Will my companions or friends become a support or a hurdle for my future?',
  'Where do I stand compared to the best in any work, and why?',
  'Did I do anything last month that I, my family, or society could be proud of?',
  'Do ideological differences shape your behaviour?',
  'Do I say thanks even for reaching where I am, for any achievement in my life?',
];

class FortnightlySelfEvalScreen extends StatelessWidget {
  const FortnightlySelfEvalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Jeevan Kaushal',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getFortnightlySelfEvals,
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

class _BodyState extends State<_Body> {
  Future<void> _openForm() async {
    final controllers = List.generate(_questions.length, (_) => TextEditingController());
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
                    Text('Jeevan ko Samjhne ka Kaushal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < _questions.length; i++) ...[
                      Text('${i + 1}. ${_questions[i]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textSecondary)),
                      const SizedBox(height: 6),
                      AppTextField(label: 'Your answer', controller: controllers[i], maxLines: 2),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)), const SizedBox(height: 10)],
                    GradientButton(
                      label: 'Submit',
                      loading: submitting,
                      onPressed: () async {
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.submitFortnightlySelfEval(controllers.map((c) => c.text.trim()).toList());
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No self-evaluations yet', subtitle: 'Complete this fortnightly to reflect on your growth.', icon: LucideIcons.compass)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  final answers = (jsonDecode(e['answersJson'] as String) as List).cast<String>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['date'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary)),
                          const SizedBox(height: 8),
                          for (int q = 0; q < answers.length && q < _questions.length; q++)
                            if (answers[q].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text('${q + 1}. ${answers[q]}', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_fortnightly_eval', backgroundColor: AppColors.saffron500, onPressed: _openForm, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
