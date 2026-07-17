import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

class TeacherClassScreen extends StatelessWidget {
  const TeacherClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: 'My Class',
      body: AsyncScreen<List<Map<String, dynamic>>>(loader: repo.getClass, builder: (context, roster, refresh) => _Body(roster: roster, repo: repo, refresh: refresh)),
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> roster;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.roster, required this.repo, required this.refresh});

  Future<void> _toggleAttendance(BuildContext context, Map<String, dynamic> student) async {
    final present = !(student['presentToday'] as bool? ?? false);
    await repo.markAttendance(studentId: student['id'] as int, present: present);
    await refresh();
  }

  void _openDetail(BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _StudentDetailSheet(student: student, roster: roster, repo: repo, refresh: refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (roster.isEmpty) {
      return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No students assigned to your class yet', icon: LucideIcons.school)]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: roster.length,
      itemBuilder: (context, i) {
        final st = roster[i];
        final present = st['presentToday'] as bool?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SectionCard(
            onTap: () => _openDetail(context, st),
            child: Row(
              children: [
                CircleAvatar(radius: 20, backgroundColor: AppColors.roleColor('TEACHER'), child: Text((st['name'] as String).isNotEmpty ? (st['name'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text('Score ${st['score']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          if (st['attendancePercent'] != null) Text(' · Attendance ${st['attendancePercent']}%', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          if (st['buddyName'] != null) Text(' · Buddy: ${st['buddyName']}', style: const TextStyle(fontSize: 11, color: AppColors.saffron600, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleAttendance(context, st),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: present == true ? const Color(0xFFD1FAE5) : present == false ? const Color(0xFFFEE2E2) : s.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      present == true ? 'Present' : present == false ? 'Absent' : 'Mark',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: present == true ? const Color(0xFF059669) : present == false ? const Color(0xFFDC2626) : s.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _StudentDetailSheet extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> roster;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _StudentDetailSheet({required this.student, required this.roster, required this.repo, required this.refresh});

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  List<Map<String, dynamic>> _notes = [];
  bool _loadingNotes = true;
  final _noteCtrl = TextEditingController();
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loadingNotes = true);
    try {
      _notes = await widget.repo.getNotes(widget.student['id'] as int);
    } catch (_) {
      _notes = [];
    } finally {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  Future<void> _addNote() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() => _savingNote = true);
    try {
      await widget.repo.addNote(studentId: widget.student['id'] as int, content: _noteCtrl.text.trim());
      _noteCtrl.clear();
      await _loadNotes();
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _pickBuddy() async {
    final others = widget.roster.where((s) => s['id'] != widget.student['id']).toList();
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          constraints: const BoxConstraints(maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose a buddy', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: others.map((o) => ListTile(title: Text(o['name'] as String), onTap: () => Navigator.pop(sheetContext, o['id'] as int))).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await widget.repo.assignBuddy(studentAId: widget.student['id'] as int, studentBId: selected);
      if (mounted) Navigator.pop(context);
      await widget.refresh();
    }
  }

  Future<void> _unassignBuddy() async {
    await widget.repo.unassignBuddy(widget.student['id'] as int);
    if (mounted) Navigator.pop(context);
    await widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hasBuddy = widget.student['buddyName'] != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Text(widget.student['name'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: s.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: hasBuddy
                        ? OutlinedButton.icon(onPressed: _unassignBuddy, icon: const Icon(LucideIcons.userX, size: 15), label: Text('Unassign ${widget.student['buddyName']}'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))
                        : GradientButton(label: 'Assign Buddy', icon: Icons.people_alt_outlined, onPressed: _pickBuddy, height: 44),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Notes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
              const SizedBox(height: 10),
              AppTextField(label: 'Add a note', controller: _noteCtrl, maxLines: 2),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _savingNote ? null : _addNote, child: _savingNote ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Note'))),
              const SizedBox(height: 6),
              if (_loadingNotes)
                const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_notes.isEmpty)
                Text('No notes yet.', style: TextStyle(fontSize: 12, color: s.textMuted))
              else
                ..._notes.map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['content'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(timeAgo(DateTime.tryParse(n['createdAt'] as String? ?? '')), style: TextStyle(fontSize: 10, color: s.textMuted)),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
