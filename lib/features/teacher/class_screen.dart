import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../auth/data/auth_provider.dart';
import '../shared/evaluation_sheet_screen.dart';
import '../shared/ptm_file_screen.dart';
import '../shared/timetable_screen.dart';
import '../shell/app_shell.dart';
import 'peer_teaching_review_screen.dart';
import 'teacher_repository.dart';

class TeacherClassScreen extends StatefulWidget {
  const TeacherClassScreen({super.key});

  @override
  State<TeacherClassScreen> createState() => _TeacherClassScreenState();
}

class _TeacherClassScreenState extends State<TeacherClassScreen> {
  final _repo = TeacherRepository();
  DateTime _date = DateTime.now();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final authUser = context.watch<AuthProvider>().user;
    return AppShell(
      title: 'My Class',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.calendarClock),
          tooltip: 'Timetable',
          onPressed: authUser?.className == null
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimetableScreen(
                    className: authUser!.className,
                    section: authUser.section,
                    editable: true,
                    title: 'Class Timetable',
                  ))),
        ),
        IconButton(
          icon: const Icon(LucideIcons.graduationCap),
          tooltip: 'Peer Teaching Review',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherPeerTeachingReviewScreen())),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 16, color: AppColors.saffron600),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEEE, d MMM yyyy').format(_date), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary)),
                    const Spacer(),
                    Icon(LucideIcons.chevronDown, size: 16, color: s.textMuted),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncScreen<List<Map<String, dynamic>>>(
              // Remounts (and refetches) whenever the picked date changes — AsyncScreen only
              // runs its loader once per State lifetime otherwise.
              key: ValueKey(_dateStr),
              loader: () => _repo.getClass(date: _dateStr),
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: GenericSkeleton(blockHeights: [64, 64, 64, 64, 64]),
              ),
              builder: (context, roster, refresh) => _Body(roster: roster, repo: _repo, refresh: refresh, dateStr: _dateStr),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> roster;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  final String dateStr;
  const _Body({required this.roster, required this.repo, required this.refresh, required this.dateStr});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<int> _markingIds = {};

  Future<void> _toggleAttendance(BuildContext context, Map<String, dynamic> student) async {
    final id = student['id'] as int;
    if (_markingIds.contains(id)) return;
    setState(() => _markingIds.add(id));
    final present = !(student['presentToday'] as bool? ?? false);
    try {
      await widget.repo.markAttendance(studentId: id, present: present, date: widget.dateStr);
      await widget.refresh();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _markingIds.remove(id));
    }
  }

  void _openDetail(BuildContext context, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _StudentDetailSheet(student: student, roster: widget.roster, repo: widget.repo, refresh: widget.refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (widget.roster.isEmpty) {
      return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No students assigned to your class yet', icon: LucideIcons.school)]);
    }
    final q = _query.trim().toLowerCase();
    final roster = q.isEmpty ? widget.roster : widget.roster.where((st) => (st['name'] as String? ?? '').toLowerCase().contains(q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListSearchField(controller: _searchCtrl, hint: 'Search by name', onChanged: (v) => setState(() => _query = v)),
        ),
        Expanded(
          child: roster.isEmpty
              ? const EmptyView(title: 'No students match your search', icon: LucideIcons.school)
              : ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: roster.length,
      itemBuilder: (context, i) {
        final st = roster[i];
        final present = st['presentToday'] as bool?;
        final id = st['id'] as int;
        final marking = _markingIds.contains(id);
        final groupmates = (st['groupmates'] as List? ?? []).cast<Map<String, dynamic>>();
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
                        ],
                      ),
                      if (groupmates.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Group: ${groupmates.map((g) => g['name']).join(', ')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.saffron600, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: marking ? null : () => _toggleAttendance(context, st),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: present == true ? const Color(0xFFD1FAE5) : present == false ? const Color(0xFFFEE2E2) : s.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: marking
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
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
          ),
        ),
      ],
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
  bool _savingGroup = false;

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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _manageGroup() async {
    final groupId = widget.student['buddyGroupId'] as int?;
    final currentMates = (widget.student['groupmates'] as List? ?? []).cast<Map<String, dynamic>>();
    final currentIds = currentMates.map((m) => m['id'] as int).toSet();
    final others = widget.roster.where((s) => s['id'] != widget.student['id']).toList();
    final selected = Set<int>.from(currentIds);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Buddy / GRS Group', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 4),
                  Text('GRS and Buddy System are small groups, not just pairs — pick everyone who sits and studies with ${widget.student['name']}.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: others.map((o) {
                        final id = o['id'] as int;
                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: (v) => setSheetState(() => v == true ? selected.add(id) : selected.remove(id)),
                          activeColor: AppColors.saffron500,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(o['name'] as String, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GradientButton(label: 'Save Group', icon: Icons.check_rounded, onPressed: () => Navigator.pop(sheetContext, true), height: 46),
                ],
              ),
            ),
          );
        });
      },
    );

    if (saved != true) return;
    final toAdd = selected.difference(currentIds);
    final toRemove = currentIds.difference(selected);
    if (toAdd.isEmpty && toRemove.isEmpty) return;

    setState(() => _savingGroup = true);
    try {
      var effectiveGroupId = groupId;
      if (effectiveGroupId == null && toAdd.isNotEmpty) {
        final result = await widget.repo.createBuddyGroup([widget.student['id'] as int, ...toAdd]);
        effectiveGroupId = result['id'] as int;
      } else {
        for (final id in toAdd) {
          await widget.repo.addToBuddyGroup(groupId: effectiveGroupId!, studentId: id);
        }
      }
      for (final id in toRemove) {
        await widget.repo.removeFromBuddyGroup(groupId: groupId!, studentId: id);
      }
      if (mounted) Navigator.pop(context);
      await widget.refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _savingGroup = false);
    }
  }

  Future<void> _logCommunityVisit() async {
    final habitsCtrl = TextEditingController();
    final understandingCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Community Assessment Visit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: habitsCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Habits observed')),
              const SizedBox(height: 12),
              TextField(controller: understandingCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Understanding observed')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await widget.repo.logCommunityAssessmentVisit(
          studentId: widget.student['id'] as int,
          habitsNotes: habitsCtrl.text.trim().isEmpty ? null : habitsCtrl.text.trim(),
          understandingNotes: understandingCtrl.text.trim().isEmpty ? null : understandingCtrl.text.trim(),
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit logged.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
      }
    }
  }

  Future<void> _logPeerExamEval() async {
    final examCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    var pattern = 'EKADIK';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: const Text('Peer Exam Evaluation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: examCtrl, decoration: const InputDecoration(labelText: 'Exam name')),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: ['EKADIK', 'PANCHADIK', 'DASHADIK'].map((p) {
                  final active = pattern == p;
                  return ChoiceChip(label: Text(p), selected: active, onSelected: (_) => setDialogState(() => pattern = p));
                }).toList()),
                const SizedBox(height: 12),
                TextField(controller: scoreCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Average score (0-100)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        );
      }),
    );
    if (saved == true) {
      final score = double.tryParse(scoreCtrl.text.trim());
      if (examCtrl.text.trim().isEmpty || score == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid exam name and score.')));
        return;
      }
      try {
        await widget.repo.logPeerExamEvaluation(studentId: widget.student['id'] as int, examName: examCtrl.text.trim(), pattern: pattern, avgScore: score);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation logged.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final groupmates = (widget.student['groupmates'] as List? ?? []).cast<Map<String, dynamic>>();
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
              if (groupmates.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: groupmates.map((g) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(99)),
                        child: Text(g['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.saffron600)),
                      )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: _savingGroup ? null : _manageGroup,
                icon: _savingGroup ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.users, size: 15),
                label: Text(groupmates.isEmpty ? 'Assign to a Group' : 'Manage Group'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _logCommunityVisit, icon: const Icon(LucideIcons.house, size: 15), label: const Text('Community Visit', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _logPeerExamEval, icon: const Icon(LucideIcons.clipboardCheck, size: 15), label: const Text('Peer Exam Eval', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EvaluationSheetScreen(
                            studentId: widget.student['id'] as int,
                            studentLabel: widget.student['name'] as String,
                            editableRoles: const ['BUDDY_1', 'BUDDY_2', 'TEACHER_1', 'TEACHER_2', 'COMMUNITY_1', 'COMMUNITY_2'],
                          ))),
                      icon: const Icon(LucideIcons.clipboardList, size: 15),
                      label: const Text('Evaluation Sheet', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PtmFileScreen(studentId: widget.student['id'] as int))),
                      icon: const Icon(LucideIcons.fileText, size: 15),
                      label: const Text('PTM File', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
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
