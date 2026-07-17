import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/section_card.dart';
import '../trainer_repository.dart';

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

class ObservationsTab extends StatefulWidget {
  const ObservationsTab({super.key});

  @override
  State<ObservationsTab> createState() => _ObservationsTabState();
}

class _ObservationsTabState extends State<ObservationsTab> {
  final _repo = TrainerRepository();
  List<Map<String, dynamic>> _observations = [];
  List<Map<String, dynamic>> _schools = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_repo.getObservations(), _repo.getSchools()]);
      _observations = results[0];
      _schools = results[1];
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    if (_schools.isEmpty) return;
    int schoolId = _schools.first['id'] as int;
    List<Map<String, dynamic>> teachers = await _repo.getTeachers(schoolId: schoolId);
    if (teachers.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No teachers found at this school.')));
      return;
    }
    int? teacherId = teachers.first['id'] as int?;
    final classCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var date = DateTime.now();
    final checklist = {for (final k in _checklistLabels.keys) k: false};
    var submitting = false;
    String? error;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;

          Future<void> onSchoolChanged(int newSchoolId) async {
            setSheetState(() => schoolId = newSchoolId);
            final newTeachers = await _repo.getTeachers(schoolId: newSchoolId);
            setSheetState(() {
              teachers = newTeachers;
              teacherId = newTeachers.isNotEmpty ? newTeachers.first['id'] as int : null;
            });
          }

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
                    Text('School', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: schoolId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: _schools.map((sc) => DropdownMenuItem(value: sc['id'] as int, child: Text(sc['name'] as String))).toList(),
                          onChanged: (v) => onSchoolChanged(v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                          items: teachers.map((t) => DropdownMenuItem(value: t['id'] as int, child: Text(t['name'] as String))).toList(),
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
                          await _repo.createObservation(
                            teacherId: teacherId!,
                            schoolId: schoolId,
                            className: classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim(),
                            section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                            date: DateFormat('yyyy-MM-dd').format(date),
                            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                            checklist: checklist,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _load();
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
    if (_loading) return const LoadingView();
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)));

    return Stack(
      children: [
        _observations.isEmpty
            ? ListView(children: const [SizedBox(height: 80), EmptyView(title: 'No observations recorded yet', icon: LucideIcons.fileCheck)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _observations.length,
                itemBuilder: (context, i) {
                  final o = _observations[i];
                  final aiScore = o['aiScore'] as int?;
                  final strengths = (o['aiStrengths'] as List? ?? []).cast<String>();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o['teacherName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                  Text('${o['className'] ?? ''} ${o['section'] ?? ''} · ${o['date']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                ],
                              ),
                            ),
                            if (aiScore != null)
                              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: Text('$aiScore/${o['aiMaxScore']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)))),
                          ]),
                          if (strengths.isNotEmpty)
                            Padding(padding: const EdgeInsets.only(top: 8), child: Text(strengths.join(' · '), style: TextStyle(fontSize: 11, color: s.textSecondary))),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'create_trainer_observation', backgroundColor: AppColors.saffron500, onPressed: _openCreate, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
