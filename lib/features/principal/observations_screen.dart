import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../action_plans/action_plan_sheet.dart';
import '../auth/data/auth_provider.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';

class PrincipalObservationsScreen extends StatelessWidget {
  const PrincipalObservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Observations',
      showAiFab: false,
      body: AsyncScreen<List<Object>>(
        loader: () => Future.wait([repo.getObservations(), repo.getObservationChecklist()]),
        builder: (context, results, refresh) => _Body(
          list: (results[0] as List).cast<Map<String, dynamic>>(),
          checklistDef: (results[1] as List).cast<Map<String, dynamic>>(),
          repo: repo,
          refresh: refresh,
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final List<Map<String, dynamic>> checklistDef;
  final PrincipalRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.checklistDef, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  List<Map<String, dynamic>> _teachers = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _createActionPlanFromObservation(Map<String, dynamic> o) async {
    final schoolName = context.read<AuthProvider>().user?.schoolName;
    final teacherId = o['teacherId'] as int?;
    final teacherName = o['teacherName'] as String?;
    if (schoolName == null || teacherId == null || teacherName == null) return;
    await showCreateActionPlanSheet(context, schoolName: schoolName, assignees: [
      {'id': teacherId, 'name': teacherName},
    ]);
  }

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
    final classCtrl = TextEditingController(text: _teachers.first['className'] as String? ?? '');
    final sectionCtrl = TextEditingController(text: _teachers.first['section'] as String? ?? '');
    final notesCtrl = TextEditingController();
    var date = DateTime.now();
    final checklist = {for (final item in widget.checklistDef) item['key'] as String: false};
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
                          onChanged: (v) => setSheetState(() {
                            teacherId = v;
                            final selected = _teachers.firstWhere((t) => t['id'] == v, orElse: () => const {});
                            classCtrl.text = selected['className'] as String? ?? '';
                            sectionCtrl.text = selected['section'] as String? ?? '';
                          }),
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
                    ...widget.checklistDef.map((item) => CheckboxListTile(
                          value: checklist[item['key']],
                          onChanged: (v) => setSheetState(() => checklist[item['key'] as String] = v ?? false),
                          activeColor: AppColors.saffron500,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(item['label'] as String, style: const TextStyle(fontSize: 12.5)),
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
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.list
        : widget.list.where((o) {
            return (o['teacherName'] as String? ?? '').toLowerCase().contains(q) ||
                (o['className'] as String? ?? '').toLowerCase().contains(q) ||
                (o['section'] as String? ?? '').toLowerCase().contains(q);
          }).toList();
    return Stack(
      children: [
        Column(
          children: [
            if (widget.list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListSearchField(controller: _searchCtrl, hint: 'Search by teacher, class or section', onChanged: (v) => setState(() => _query = v)),
              ),
            Expanded(
              child: list.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      EmptyView(
                        title: widget.list.isEmpty ? 'No observations recorded yet' : 'No observations match your search',
                        subtitle: widget.list.isEmpty ? 'Tap + to record a classroom observation.' : null,
                        icon: LucideIcons.fileCheck,
                      ),
                    ])
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final o = list[i];
                  final aiScore = o['aiScore'] as int?;
                  final strengths = (o['aiStrengths'] as List? ?? []).cast<String>();
                  final improvements = (o['aiImprovementAreas'] as List? ?? []).cast<String>();
                  final actionPoints = (o['aiActionPoints'] as List? ?? []).cast<String>();
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
                                    Text('${o['className'] ?? ''} ${o['section'] ?? ''} · ${o['date']} · ${o['observedBy'] ?? ''}', style: TextStyle(fontSize: 11, color: s.textMuted)),
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
                          if (actionPoints.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Action Points', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                            const SizedBox(height: 4),
                            ...actionPoints.map((line) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.target, size: 12, color: Color(0xFF6366F1)), const SizedBox(width: 6), Expanded(child: Text(line, style: TextStyle(fontSize: 11, color: s.textSecondary)))])),
                          ],
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _createActionPlanFromObservation(o),
                              icon: const Icon(LucideIcons.clipboardList, size: 13),
                              label: const Text('Create Action Plan', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
          ],
        ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'create_observation', backgroundColor: AppColors.saffron500, onPressed: _openCreate, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
