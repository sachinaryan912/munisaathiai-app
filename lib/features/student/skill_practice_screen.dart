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

const _skillTypes = {
  'REASONING': 'Reasoning',
  'BRAIN_MAPPING': 'Brain Mapping',
  'ABOUT': 'About',
};

class SkillPracticeScreen extends StatelessWidget {
  const SkillPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Reasoning & Brain Mapping',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getSkillPracticeLogs,
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
    final topicCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final correctCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    var type = 'REASONING';
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
                    Text('Log Practice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _skillTypes.entries.map((entry) {
                        final active = type == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                          selected: active,
                          onSelected: (_) => setSheetState(() => type = entry.key),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Topic', controller: topicCtrl),
                    const SizedBox(height: 12),
                    if (type == 'REASONING') ...[
                      Row(children: [
                        Expanded(child: AppTextField(label: 'Correct', controller: correctCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: AppTextField(label: 'Total', controller: totalCtrl, keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 12),
                    ],
                    AppTextField(label: 'Notes (optional)', controller: notesCtrl, maxLines: 3),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        if (topicCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter the topic.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.logSkillPractice(
                            skillType: type,
                            topic: topicCtrl.text.trim(),
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            correctCount: int.tryParse(correctCtrl.text.trim()),
                            totalCount: int.tryParse(totalCtrl.text.trim()),
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No practice logged yet', subtitle: 'Log reasoning drills, brain mapping or "About" exercises.', icon: LucideIcons.brain)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  final correct = e['correctCount'] as int?;
                  final total = e['totalCount'] as int?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_skillTypes[e['skillType']] ?? e['skillType']} · ${e['topic']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                                if ((e['notes'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 4), Text(e['notes'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                              ],
                            ),
                          ),
                          if (correct != null && total != null) Text('$correct/$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.textPrimary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_skill_practice', backgroundColor: AppColors.saffron500, onPressed: _openForm, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
