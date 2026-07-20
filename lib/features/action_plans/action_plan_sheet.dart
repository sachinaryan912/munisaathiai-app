import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import 'action_plan_repository.dart';

const _statusLabels = {'OPEN': 'Open', 'IN_PROGRESS': 'In Progress', 'DONE': 'Done'};
const _statusOrder = ['OPEN', 'IN_PROGRESS', 'DONE'];
const _statusColors = {
  'OPEN': AppColors.warning,
  'IN_PROGRESS': Color(0xFF6366F1),
  'DONE': AppColors.success,
};

/// Shared "My Action Plans" sheet — every role can see plans assigned to them
/// and tap one to advance it Open → In Progress → Done.
void showMyActionPlansSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _MyActionPlansSheet(),
  );
}

class _MyActionPlansSheet extends StatelessWidget {
  const _MyActionPlansSheet();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final repo = ActionPlanRepository();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
            Text('My Action Plans', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
            const SizedBox(height: 4),
            Text('Tap a plan to move it to the next status.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
            const SizedBox(height: 16),
            Flexible(
              child: AsyncScreen<List<Map<String, dynamic>>>(
                loader: repo.getMine,
                loadingBuilder: (context) => const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                builder: (context, plans, refresh) => _PlansList(plans: plans, repo: repo, refresh: refresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansList extends StatefulWidget {
  final List<Map<String, dynamic>> plans;
  final ActionPlanRepository repo;
  final Future<void> Function() refresh;
  const _PlansList({required this.plans, required this.repo, required this.refresh});

  @override
  State<_PlansList> createState() => _PlansListState();
}

class _PlansListState extends State<_PlansList> {
  final Set<int> _updatingIds = {};

  Future<void> _cycleStatus(Map<String, dynamic> plan) async {
    final id = plan['id'] as int;
    if (_updatingIds.contains(id)) return;
    final current = plan['status'] as String;
    final next = _statusOrder[(_statusOrder.indexOf(current) + 1) % _statusOrder.length];
    setState(() => _updatingIds.add(id));
    try {
      await widget.repo.updateStatus(id, next);
      await widget.refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (widget.plans.isEmpty) {
      return ListView(children: const [SizedBox(height: 20), EmptyView(title: 'No action plans assigned to you', icon: LucideIcons.clipboardList)]);
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: widget.plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = widget.plans[i];
        final status = p['status'] as String;
        final color = _statusColors[status] ?? s.textMuted;
        final updating = _updatingIds.contains(p['id'] as int);
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: updating ? null : () => _cycleStatus(p),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${p['schoolName']} · from ${p['createdByName']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                      if ((p['description'] as String?)?.isNotEmpty == true)
                        Padding(padding: const EdgeInsets.only(top: 6), child: Text(p['description'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))),
                      if (p['dueDate'] != null)
                        Padding(padding: const EdgeInsets.only(top: 4), child: Text('Due ${p['dueDate']}', style: TextStyle(fontSize: 10.5, color: s.textMuted, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                updating
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                        child: Text(_statusLabels[status] ?? status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Create Action Plan ──────────────────────────────────────────────────────

/// Opened by Management/Trainer/Principal from an alert/report/observation.
/// [assignees] is the pool of people this plan can be handed to at [schoolName]
/// (each map needs an `id` and a `name`) — callers scope this themselves
/// (e.g. that school's teachers).
Future<bool?> showCreateActionPlanSheet(
  BuildContext context, {
  required String schoolName,
  required List<Map<String, dynamic>> assignees,
}) {
  if (assignees.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No one to assign this to yet at this school.')));
    return Future.value(null);
  }
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  Map<String, dynamic> selectedAssignee = assignees.first;
  DateTime? dueDate;
  var submitting = false;
  String? error;

  return showModalBottomSheet<bool>(
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
                  Text('New Action Plan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  Text(schoolName, style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Title', controller: titleCtrl, hint: 'e.g. Re-train on Buddy System'),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Description (optional)', controller: descCtrl, maxLines: 3),
                  const SizedBox(height: 12),
                  Text('Assign to', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedAssignee,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: assignees.map((a) => DropdownMenuItem(value: a, child: Text(a['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) {
                          if (v != null) setSheetState(() => selectedAssignee = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: sheetContext, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (picked != null) setSheetState(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        const Icon(LucideIcons.calendar, size: 15, color: AppColors.saffron600),
                        const SizedBox(width: 8),
                        Text(dueDate == null ? 'Due date (optional)' : _fmtDate(dueDate!)),
                      ]),
                    ),
                  ),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Create',
                    loading: submitting,
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        setSheetState(() => error = 'Please enter a title.');
                        return;
                      }
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await ActionPlanRepository().create(
                          schoolName: schoolName,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          assignedToId: selectedAssignee['id'] as int,
                          dueDate: dueDate == null ? null : _fmtDate(dueDate!),
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext, true);
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

String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
