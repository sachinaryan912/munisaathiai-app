import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'evaluation_sheet_repository.dart';

const _raterLabels = {
  'SELF': 'Self',
  'BUDDY_1': 'Buddy 1',
  'BUDDY_2': 'Buddy 2',
  'TEACHER_1': 'Teacher 1',
  'TEACHER_2': 'Teacher 2',
  'PARENT': 'Parent',
  'COMMUNITY_1': 'Community 1',
  'COMMUNITY_2': 'Community 2',
};

const _raterOrder = ['SELF', 'BUDDY_1', 'BUDDY_2', 'TEACHER_1', 'TEACHER_2', 'PARENT', 'COMMUNITY_1', 'COMMUNITY_2'];

/// Reusable 360-degree "Evaluation Sheet" — [editableRoles] controls which rater columns the
/// current viewer (Student/Teacher/Parent) can fill in; everything else shows read-only.
class EvaluationSheetScreen extends StatefulWidget {
  final int? studentId;
  final String studentLabel;
  final List<String> editableRoles;
  const EvaluationSheetScreen({super.key, this.studentId, required this.studentLabel, required this.editableRoles});

  @override
  State<EvaluationSheetScreen> createState() => _EvaluationSheetScreenState();
}

class _EvaluationSheetScreenState extends State<EvaluationSheetScreen> {
  final _repo = EvaluationSheetRepository();
  late String _termLabel = _defaultTerm();

  static String _defaultTerm() {
    final now = DateTime.now();
    final term = now.month <= 6 ? 1 : 2;
    return 'Term $term ${now.year}';
  }

  Future<void> _editTerm() async {
    final ctrl = TextEditingController(text: _termLabel);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Term'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'e.g. Term 1 2026')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (saved != null && saved.isNotEmpty) {
      setState(() => _termLabel = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Evaluation Sheet',
      showAiFab: false,
      actions: [IconButton(icon: const Icon(LucideIcons.calendar), tooltip: 'Change term', onPressed: _editTerm)],
      body: AsyncScreen<Map<String, dynamic>>(
        // Remounts AsyncScreen's internal state (and re-runs `loader`) whenever the term
        // changes — its own `_future` is only fetched once per State lifetime otherwise.
        key: ValueKey(_termLabel),
        loader: () => _repo.getEvaluationSheet(studentId: widget.studentId, termLabel: _termLabel),
        builder: (context, sheet, refresh) => _Body(
          sheet: sheet,
          repo: _repo,
          studentId: widget.studentId,
          studentLabel: widget.studentLabel,
          termLabel: _termLabel,
          editableRoles: widget.editableRoles,
          refresh: refresh,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> sheet;
  final EvaluationSheetRepository repo;
  final int? studentId;
  final String studentLabel;
  final String termLabel;
  final List<String> editableRoles;
  final Future<void> Function() refresh;

  const _Body({
    required this.sheet,
    required this.repo,
    required this.studentId,
    required this.studentLabel,
    required this.termLabel,
    required this.editableRoles,
    required this.refresh,
  });

  Future<void> _rate(BuildContext context, String criterion, String role) async {
    final ctrl = TextEditingController();
    final rows = (sheet['criteria'] as List? ?? []).cast<Map<String, dynamic>>();
    final row = rows.firstWhere((r) => r['criterion'] == criterion, orElse: () => {});
    final existing = (row['scores'] as Map?)?[role];
    ctrl.text = existing?.toString() ?? '';
    String? raterName;
    final nameCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_raterLabels[role]} — $criterion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (role != 'SELF' && role != 'PARENT')
              Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Rater name (optional)'))),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score (0-5)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final score = int.tryParse(ctrl.text.trim());
    if (score == null || score < 0 || score > 5) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a score between 0 and 5.')));
      return;
    }
    raterName = nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim();
    try {
      await repo.submitRating(
        studentId: studentId ?? (sheet['studentId'] as int),
        termLabel: termLabel,
        criterion: criterion,
        raterRole: role,
        raterName: raterName,
        score: score,
      );
      await refresh();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                    Text(termLabel, style: TextStyle(fontSize: 11, color: s.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${sheet['percentage']}%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.saffron600)),
                  Text('${sheet['total']}/${sheet['maxPossible']}', style: TextStyle(fontSize: 10, color: s.textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('This rubric contributes 1/6 of the report card marks.', style: TextStyle(fontSize: 10.5, color: s.textMuted, fontStyle: FontStyle.italic))),
        const SizedBox(height: 16),
        ...((sheet['criteria'] as List).cast<Map<String, dynamic>>()).map((row) {
          final scores = (row['scores'] as Map?) ?? {};
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row['criterion'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _raterOrder.map((role) {
                      final editable = editableRoles.contains(role);
                      final score = scores[role];
                      return GestureDetector(
                        onTap: editable ? () => _rate(context, row['criterion'] as String, role) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color: score != null ? AppColors.saffron500.withValues(alpha: 0.12) : s.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: editable ? Border.all(color: AppColors.saffron400, width: 1) : null,
                          ),
                          child: Column(
                            children: [
                              Text(_raterLabels[role]!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: s.textMuted)),
                              Text(score?.toString() ?? '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: score != null ? AppColors.saffron600 : s.textMuted)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
