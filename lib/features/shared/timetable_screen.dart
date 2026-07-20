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
import 'timetable_repository.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Weekly period-by-period timetable. If [className] is null, loads the viewer's own
/// timetable (Student/Teacher/Parent-of-child); otherwise loads the given class (Principal
/// picking any class in their school). [editable] shows add/edit controls.
class TimetableScreen extends StatelessWidget {
  final String? className;
  final String? section;
  final bool editable;
  final String title;
  const TimetableScreen({super.key, this.className, this.section, this.editable = false, this.title = 'Timetable'});

  @override
  Widget build(BuildContext context) {
    final repo = TimetableRepository();
    return AppShell(
      title: title,
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: () => className == null ? repo.getMyTimetable() : repo.getTimetable(className: className!, section: section),
        builder: (context, entries, refresh) => _Body(
          entries: entries,
          repo: repo,
          refresh: refresh,
          className: className,
          section: section,
          editable: editable,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final TimetableRepository repo;
  final Future<void> Function() refresh;
  final String? className;
  final String? section;
  final bool editable;

  const _Body({
    required this.entries,
    required this.repo,
    required this.refresh,
    required this.className,
    required this.section,
    required this.editable,
  });

  Future<void> _openEdit(BuildContext context, {String? day, int? period, Map<String, dynamic>? existing}) async {
    if (className == null) return;
    var selectedDay = existing?['dayOfWeek'] as String? ?? day ?? _days.first;
    final periodCtrl = TextEditingController(text: (existing?['periodNumber'] ?? period)?.toString() ?? '');
    final subjectCtrl = TextEditingController(text: existing?['subject'] as String? ?? '');
    final startCtrl = TextEditingController(text: existing?['startTime'] as String? ?? '');
    final endCtrl = TextEditingController(text: existing?['endTime'] as String? ?? '');
    final teacherCtrl = TextEditingController(text: existing?['teacherName'] as String? ?? '');
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
                    Text('Edit Period', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, children: _days.map((d) {
                      final active = selectedDay == d;
                      return ChoiceChip(label: Text(d), selected: active, onSelected: (_) => setSheetState(() => selectedDay = d), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700));
                    }).toList()),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Period number', controller: periodCtrl, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Subject', controller: subjectCtrl),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AppTextField(label: 'Start (HH:mm)', controller: startCtrl, hint: '09:00')),
                      const SizedBox(width: 10),
                      Expanded(child: AppTextField(label: 'End (HH:mm)', controller: endCtrl, hint: '09:40')),
                    ]),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Teacher (optional)', controller: teacherCtrl),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        final periodNum = int.tryParse(periodCtrl.text.trim());
                        if (periodNum == null || subjectCtrl.text.trim().isEmpty || startCtrl.text.trim().isEmpty || endCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please fill period, subject, start and end time.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await repo.setPeriod(
                            className: className!,
                            section: section,
                            dayOfWeek: selectedDay,
                            periodNumber: periodNum,
                            subject: subjectCtrl.text.trim(),
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            teacherName: teacherCtrl.text.trim().isEmpty ? null : teacherCtrl.text.trim(),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await refresh();
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
        entries.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No timetable set yet', icon: LucideIcons.calendarClock)])
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, editable ? 100 : 24),
                children: _days.map((day) {
                  final dayEntries = entries.where((e) => e['dayOfWeek'] == day).toList()
                    ..sort((a, b) => (a['periodNumber'] as int).compareTo(b['periodNumber'] as int));
                  if (dayEntries.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.saffron600)),
                        const SizedBox(height: 8),
                        ...dayEntries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SectionCard(
                                onTap: editable ? () => _openEdit(context, existing: e) : null,
                                child: Row(
                                  children: [
                                    Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(10)), child: Text('${e['periodNumber']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.saffron700))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e['subject'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                          Text('${e['startTime']} – ${e['endTime']}${e['teacherName'] != null ? ' · ${e['teacherName']}' : ''}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                                        ],
                                      ),
                                    ),
                                    if (editable) Icon(LucideIcons.pencil, size: 14, color: s.textMuted),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
        if (editable)
          Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_period', backgroundColor: AppColors.saffron500, onPressed: () => _openEdit(context), child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
