import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';

const _roleLabels = {
  'MP': 'Member of Parliament',
  'MLA': 'MLA',
  'JUDICIARY': 'Judiciary Member',
  'COUNSELOR': 'Counselor',
  'PRESIDENT': 'President',
  'PRIME_MINISTER': 'Prime Minister',
};

class PrincipalParliamentScreen extends StatelessWidget {
  const PrincipalParliamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Child Parliament',
      body: AsyncScreen<List<dynamic>>(
        loader: () => Future.wait([repo.getParliamentTerms(), repo.getClasses(), repo.getParliamentSummaryReport()]),
        builder: (context, results, refresh) => _Body(
          terms: (results[0] as List).cast<Map<String, dynamic>>(),
          classes: (results[1] as List).cast<Map<String, dynamic>>(),
          summary: results[2] as Map<String, dynamic>,
          repo: repo,
          refresh: refresh,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> terms;
  final List<Map<String, dynamic>> classes;
  final Map<String, dynamic> summary;
  final PrincipalRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.terms, required this.classes, required this.summary, required this.repo, required this.refresh});

  Future<void> _newTerm(BuildContext context) async {
    if (classes.isEmpty) return;
    Map<String, dynamic> selectedClass = classes.first;
    final created = await showModalBottomSheet<bool>(
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
                  Text('Start This Month\'s Term', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: selectedClass,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c['displayName'] as String, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedClass = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Create Term',
                    onPressed: () async {
                      await repo.createParliamentTerm(className: selectedClass['className'] as String, section: selectedClass['section'] as String?);
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
    if (created == true) await refresh();
  }

  void _openTerm(BuildContext context, Map<String, dynamic> term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TermDetailSheet(term: term, classes: classes, repo: repo, onChanged: refresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatPill(label: 'Terms', value: '${summary['termsCount'] ?? 0}'),
                  _StatPill(label: 'Roles Filled', value: '${summary['totalRolesFilled'] ?? 0}'),
                  _StatPill(label: 'Meetings', value: '${summary['totalMeetings'] ?? 0}'),
                  _StatPill(label: 'Activities', value: '${summary['totalActivities'] ?? 0}'),
                ],
              ),
              const SizedBox(height: 14),
              PdfDownloadButton(fileName: 'parliament_summary_report.pdf', download: repo.downloadParliamentSummaryReportPdf),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text('Class Terms', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const Spacer(),
            TextButton.icon(onPressed: () => _newTerm(context), icon: const Icon(LucideIcons.plus, size: 15), label: const Text('New Term')),
          ],
        ),
        if (terms.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 20), child: EmptyView(title: 'No Child Parliament terms yet', icon: LucideIcons.landmark))
        else
          ...terms.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => _openTerm(context, t),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t['className']}${t['section'] != null ? ' ${t['section']}' : ''}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                            Text('${t['monthStart']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(99)),
                        child: Text('${t['roleCount']} roles', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron600)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: s.textMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TermDetailSheet extends StatefulWidget {
  final Map<String, dynamic> term;
  final List<Map<String, dynamic>> classes;
  final PrincipalRepository repo;
  final Future<void> Function() onChanged;
  const _TermDetailSheet({required this.term, required this.classes, required this.repo, required this.onChanged});

  @override
  State<_TermDetailSheet> createState() => _TermDetailSheetState();
}

class _TermDetailSheetState extends State<_TermDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _detail = await widget.repo.getParliamentTerm(widget.term['id'] as int);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _roster {
    final match = widget.classes.firstWhere(
      (c) => c['className'] == widget.term['className'] && c['section'] == widget.term['section'],
      orElse: () => const {},
    );
    return (match['students'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> _assignRole() async {
    if (_roster.isEmpty) return;
    Map<String, dynamic> selectedStudent = _roster.first;
    String selectedRole = _roleLabels.keys.first;
    final ministryCtrl = TextEditingController();

    final assigned = await showModalBottomSheet<bool>(
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
                  Text('Assign a Role', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: selectedStudent,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Student', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: _roster.map((st) => DropdownMenuItem(value: st, child: Text(st['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedStudent = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    items: _roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Ministry (optional)', controller: ministryCtrl),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Assign',
                    onPressed: () async {
                      await widget.repo.assignParliamentRole(
                        termId: widget.term['id'] as int,
                        studentId: selectedStudent['id'] as int,
                        roleType: selectedRole,
                        ministry: ministryCtrl.text.trim().isEmpty ? null : ministryCtrl.text.trim(),
                      );
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
    if (assigned == true) {
      await _load();
      await widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final roles = (_detail?['roles'] as List? ?? []).cast<Map<String, dynamic>>();

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
              Text('${widget.term['className']}${widget.term['section'] != null ? ' ${widget.term['section']}' : ''} — ${widget.term['monthStart']}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
                if (roles.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('No roles assigned yet.', style: TextStyle(fontSize: 12.5, color: s.textMuted)))
                else
                  ...roles.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['studentName'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.textPrimary)),
                                  Text(_roleLabels[r['roleType']] ?? r['roleType'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                                ],
                              ),
                            ),
                            if (r['ministry'] != null) Text(r['ministry'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.saffron600)),
                          ],
                        ),
                      )),
                const SizedBox(height: 16),
                GradientButton(label: 'Assign Role', icon: Icons.person_add_alt_1, onPressed: _assignRole, height: 46),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
