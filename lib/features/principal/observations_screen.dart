import 'package:flutter/material.dart';
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
import 'principal_repository.dart';

const _checklistLabels = {
  'buddySystem': 'Buddy System implementation',
  'studentCollaboration': 'Student collaboration',
  'teacherFacilitator': 'Teacher acting as facilitator, not lecturing',
  'activeGroupLearning': 'Active group learning',
  'studentQuestioning': 'Student questioning encouraged',
  'selfStudyActivities': 'Self-study activities visible',
  'uplcImplementation': 'UPLC implementation',
  'supportWeakStudents': 'Support for weak students',
  'democraticPractices': 'Democratic classroom practices',
};

class PrincipalObservationsScreen extends StatelessWidget {
  const PrincipalObservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Observations',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(loader: repo.getObservations, builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh)),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final PrincipalRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  List<Map<String, dynamic>> _teachers = [];

  Future<void> _openCreate() async {
    if (_teachers.isEmpty) {
      try {
        _teachers = await widget.repo.getTeachers();
      } catch (_) {}
    }
    if (!mounted) return;
    if (_teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No teachers found to observe.')));
      return;
    }

    int? teacherId = _teachers.first['id'] as int?;
    final classCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var date = DateTime.now();
    final checklist = {for (final k in _checklistLabels.keys) k: false};
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.88),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('New Classroom Observation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    Text('Teacher', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: teacherId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: _teachers.map((t) => DropdownMenuItem(value: t['id'] as int, child: Text(t['name'] as String))).toList(),
                          onChanged: (v) => setSheetState(() => teacherId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: AppTextField(label: 'Class', controller: classCtrl)),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'Section', controller: sectionCtrl)),
                    ]),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: sheetContext, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime.now());
                        if (picked != null) setSheetState(() => date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [const Icon(LucideIcons.calendar, size: 16, color: AppColors.saffron600), const SizedBox(width: 8), Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontWeight: FontWeight.w700, color: s.textPrimary))]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Notes', controller: notesCtrl, maxLines: 2),
                    const SizedBox(height: 14),
                    Text('Observation Checklist', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    ..._checklistLabels.entries.map((e) => CheckboxListTile(
                          value: checklist[e.key],
                          onChanged: (v) => setSheetState(() => checklist[e.key] = v ?? false),
                          activeColor: AppColors.saffron500,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(e.value, style: const TextStyle(fontSize: 12.5)),
                        )),
                    if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Submit Observation',
                      loading: submitting,
                      onPressed: () async {
                        if (teacherId == null) return;
                        setSheetState(() => submitting = true);
                        try {
                          await widget.repo.createObservation(
                            teacherId: teacherId!,
                            className: classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim(),
                            section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                            date: DateFormat('yyyy-MM-dd').format(date),
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            checklist: checklist,
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No observations recorded yet', subtitle: 'Tap + to record a classroom observation.', icon: LucideIcons.fileCheck)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final o = widget.list[i];
                  final aiScore = o['aiScore'] as int?;
                  final strengths = (o['aiStrengths'] as List? ?? []).cast<String>();
                  final improvements = (o['aiImprovementAreas'] as List? ?? []).cast<String>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o['teacherName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                    Text('${o['className'] ?? ''} ${o['section'] ?? ''} · ${o['date']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                  ],
                                ),
                              ),
                              if (aiScore != null)
                                Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: Text('$aiScore/${o['aiMaxScore']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)))),
                            ],
                          ),
                          if ((o['notes'] as String?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(o['notes'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))),
                          if (strengths.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...strengths.map((line) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.circleCheck, size: 12, color: AppColors.success), const SizedBox(width: 6), Expanded(child: Text(line, style: TextStyle(fontSize: 11, color: s.textSecondary)))])),
                          ],
                          if (improvements.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...improvements.map((line) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.arrowUpRight, size: 12, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(line, style: TextStyle(fontSize: 11, color: s.textSecondary)))])),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'create_observation', backgroundColor: AppColors.saffron500, onPressed: _openCreate, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
