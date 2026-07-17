import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

const _methodologies = [
  'GRS', 'Buddy System', 'UPLC', 'HADS', 'Child Parliament', 'Growth Habits',
  'Ghar Ek Pathshala', 'Am I Able', 'Situation Creation', 'Bharat Bodh',
  'Vedic Math', 'English Language (LLT)',
];

const _statusColors = {
  'Draft': Color(0xFF6B7280),
  'Submitted': Color(0xFF3B82F6),
  'Done': Color(0xFF10B981),
};

class TeacherLessonPlansScreen extends StatelessWidget {
  const TeacherLessonPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: 'Lesson Plans',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(loader: repo.getLessonPlans, builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh)),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Future<void> _openCreate() async {
    final subjectCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final objectivesCtrl = TextEditingController();
    var date = DateTime.now();
    var duration = 40;
    final linked = <String>{};
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
                    Text('New Lesson Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Subject', controller: subjectCtrl),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Topic', controller: topicCtrl),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Objectives (optional)', controller: objectivesCtrl, maxLines: 2),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: sheetContext, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime(2030));
                        if (picked != null) setSheetState(() => date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [const Icon(LucideIcons.calendar, size: 16, color: AppColors.saffron600), const SizedBox(width: 8), Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontWeight: FontWeight.w700, color: s.textPrimary))]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Duration: $duration min', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    Slider(value: duration.toDouble(), min: 10, max: 90, divisions: 16, activeColor: AppColors.saffron500, onChanged: (v) => setSheetState(() => duration = v.round())),
                    const SizedBox(height: 8),
                    Text('Linked methodologies', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _methodologies.map((m) {
                        final active = linked.contains(m);
                        return FilterChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          selected: active,
                          onSelected: (v) => setSheetState(() => v ? linked.add(m) : linked.remove(m)),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                          backgroundColor: s.border.withValues(alpha: 0.4),
                          side: BorderSide.none,
                          checkmarkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save Lesson Plan',
                      loading: submitting,
                      onPressed: () async {
                        if (subjectCtrl.text.trim().isEmpty || topicCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Subject and topic are required.');
                          return;
                        }
                        setSheetState(() => submitting = true);
                        try {
                          await widget.repo.createLessonPlan(
                            subject: subjectCtrl.text.trim(),
                            topic: topicCtrl.text.trim(),
                            objectives: objectivesCtrl.text.trim().isEmpty ? null : objectivesCtrl.text.trim(),
                            date: DateFormat('yyyy-MM-dd').format(date),
                            durationMinutes: duration,
                            linkedMethodologies: linked.toList(),
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

  Future<void> _cycleStatus(Map<String, dynamic> plan) async {
    const order = ['Draft', 'Submitted', 'Done'];
    final current = order.indexOf(plan['status'] as String);
    final next = order[(current + 1) % order.length];
    await widget.repo.setLessonPlanStatus(plan['id'] as int, next);
    await widget.refresh();
  }

  Future<void> _delete(int id) async {
    await widget.repo.deleteLessonPlan(id);
    await widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Stack(
      children: [
        widget.list.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No lesson plans yet', subtitle: 'Tap + to create your first lesson plan.', icon: LucideIcons.notebookPen)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final p = widget.list[i];
                  final status = p['status'] as String;
                  final color = _statusColors[status] ?? s.textMuted;
                  final linkedList = (p['linkedMethodologies'] as List? ?? []).cast<String>();
                  return Dismissible(
                    key: ValueKey(p['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)), child: const Icon(LucideIcons.trash2, color: Colors.white)),
                    onDismissed: (_) => _delete(p['id'] as int),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SectionCard(
                        onTap: () => _cycleStatus(p),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['subject'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron600, letterSpacing: 0.3)),
                                      Text(p['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: s.textPrimary)),
                                    ],
                                  ),
                                ),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${p['date']} · ${p['durationMinutes']} min', style: TextStyle(fontSize: 11, color: s.textMuted)),
                            if ((p['objectives'] as String?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 6), child: Text(p['objectives'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))),
                            if (linkedList.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(spacing: 6, runSpacing: 6, children: linkedList.map((m) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: s.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)), child: Text(m, style: TextStyle(fontSize: 9.5, color: s.textSecondary, fontWeight: FontWeight.w700)))).toList()),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(heroTag: 'create_lesson_plan', backgroundColor: AppColors.saffron500, onPressed: _openCreate, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }
}
