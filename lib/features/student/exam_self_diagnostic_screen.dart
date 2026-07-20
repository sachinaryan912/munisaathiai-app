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

const _reasons = ['Not Understood', 'Forget', 'Time Over', 'Any other reason'];

class ExamSelfDiagnosticScreen extends StatelessWidget {
  const ExamSelfDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Exam Evaluation',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getExamSelfDiagnostics,
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
    final examCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final selected = <String>{};
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
                    Text('Why did I get it wrong?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Exam name', controller: examCtrl),
                    const SizedBox(height: 12),
                    Text('Select all reasons that applied', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasons.map((r) {
                        final active = selected.contains(r);
                        return ChoiceChip(
                          label: Text(r, style: const TextStyle(fontSize: 11.5)),
                          selected: active,
                          onSelected: (_) => setSheetState(() => active ? selected.remove(r) : selected.add(r)),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Details (optional)', controller: noteCtrl, maxLines: 3),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        if (examCtrl.text.trim().isEmpty || selected.isEmpty) {
                          setSheetState(() => error = 'Please enter the exam name and select at least one reason.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.submitExamSelfDiagnostic(examName: examCtrl.text.trim(), diagnosis: {'reasons': selected.toList(), 'notes': noteCtrl.text.trim()});
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No diagnostics yet', subtitle: 'After an exam, log why any answers went wrong.', icon: LucideIcons.searchCheck)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  final diag = jsonDecode(e['diagnosisJson'] as String) as Map<String, dynamic>;
                  final reasons = (diag['reasons'] as List? ?? []).cast<String>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['examName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                          Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: reasons.map((r) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: Text(r, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.warning)))).toList()),
                          if ((diag['notes'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 6), Text(diag['notes'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_exam_diagnostic', backgroundColor: AppColors.saffron500, onPressed: _openForm, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
