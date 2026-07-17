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
import 'teacher_repository.dart';

class TeacherParliamentScreen extends StatelessWidget {
  const TeacherParliamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: 'Child Parliament',
      body: AsyncScreen<List<dynamic>>(
        loader: () => Future.wait([repo.getParliamentMeetings(), repo.getParliamentActivities(), repo.getClass()]),
        builder: (context, results, refresh) => _Body(
          meetings: (results[0] as List).cast<Map<String, dynamic>>(),
          activities: (results[1] as List).cast<Map<String, dynamic>>(),
          roster: (results[2] as List).cast<Map<String, dynamic>>(),
          repo: repo,
          refresh: refresh,
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> meetings;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> roster;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.meetings, required this.activities, required this.roster, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String _tab = 'meetings';

  Future<void> _logMeeting() async {
    final agendaCtrl = TextEditingController();
    final minutesCtrl = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Log a Parliament Meeting', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                const SizedBox(height: 14),
                AppTextField(label: 'Agenda', controller: agendaCtrl, maxLines: 2),
                const SizedBox(height: 12),
                AppTextField(label: 'Minutes (optional)', controller: minutesCtrl, maxLines: 3),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Save Meeting',
                  onPressed: () async {
                    if (agendaCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Please enter an agenda.')));
                      return;
                    }
                    await widget.repo.logParliamentMeeting(agenda: agendaCtrl.text.trim(), minutes: minutesCtrl.text.trim().isEmpty ? null : minutesCtrl.text.trim());
                    if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                  },
                  height: 46,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (saved == true) await widget.refresh();
  }

  Future<void> _logActivity() async {
    Map<String, dynamic>? selectedStudent;
    final descCtrl = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Log a Parliament Activity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Map<String, dynamic>?>(
                    initialValue: selectedStudent,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Student (optional — leave blank for the whole class)', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Whole class')),
                      ...widget.roster.map((st) => DropdownMenuItem(value: st, child: Text(st['name'] as String, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setSheetState(() => selectedStudent = v),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Description', controller: descCtrl, maxLines: 2),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Save Activity',
                    onPressed: () async {
                      if (descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Please enter a description.')));
                        return;
                      }
                      await widget.repo.logParliamentActivity(studentId: selectedStudent?['id'] as int?, description: descCtrl.text.trim());
                      if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                    },
                    height: 46,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (saved == true) await widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Wrap(spacing: 8, children: [
          _TabChip(label: 'Meetings', value: 'meetings', active: _tab, onTap: (v) => setState(() => _tab = v)),
          _TabChip(label: 'Activities', value: 'activities', active: _tab, onTap: (v) => setState(() => _tab = v)),
        ]),
        const SizedBox(height: 16),
        if (_tab == 'meetings') ...[
          if (widget.meetings.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 20), child: EmptyView(title: 'No meetings logged yet', icon: LucideIcons.landmark))
          else
            ...widget.meetings.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(m['agenda'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary))),
                          Text(m['date'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                        ]),
                        if ((m['minutes'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(m['minutes'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 12),
          GradientButton(label: 'Log Meeting', icon: Icons.add, onPressed: _logMeeting, height: 46),
        ] else ...[
          if (widget.activities.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 20), child: EmptyView(title: 'No activities logged yet', icon: LucideIcons.clipboardList))
          else
            ...widget.activities.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['description'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary)),
                              Text(a['studentName'] != null ? a['studentName'] as String : 'Whole class', style: TextStyle(fontSize: 11, color: s.textMuted)),
                            ],
                          ),
                        ),
                        Text(a['date'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 12),
          GradientButton(label: 'Log Activity', icon: Icons.add, onPressed: _logActivity, height: 46),
        ],
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final String value;
  final String active;
  final ValueChanged<String> onTap;
  const _TabChip({required this.label, required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isActive = active == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(value),
      selectedColor: AppColors.saffron500,
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isActive ? Colors.white : s.textSecondary),
      backgroundColor: s.card,
      side: BorderSide(color: isActive ? AppColors.saffron500 : s.border),
    );
  }
}
