import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import '../videos/video_screen.dart';
import 'teacher_journal_screen.dart';
import 'teacher_repository.dart';

class TeacherMethodologyScreen extends StatefulWidget {
  const TeacherMethodologyScreen({super.key});

  @override
  State<TeacherMethodologyScreen> createState() => _TeacherMethodologyScreenState();
}

class _TeacherMethodologyScreenState extends State<TeacherMethodologyScreen> {
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
    return AppShell(
      title: 'Methodology',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.notebookPen),
          tooltip: 'Teaching Journal',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherJournalScreen())),
        ),
        IconButton(
          icon: const Icon(LucideIcons.tv),
          tooltip: 'Training Videos',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppShell(title: 'Training Videos', showAiFab: false, body: VideoResourcesScreen()))),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
              loader: () => _repo.getMethodology(date: _dateStr),
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 40),
                child: GenericSkeleton(blockHeights: [70, 70, 70, 70, 70, 70]),
              ),
              builder: (context, items, refresh) => _Body(items: items, repo: _repo, dateStr: _dateStr),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final TeacherRepository repo;
  final String dateStr;
  const _Body({required this.items, required this.repo, required this.dateStr});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final Set<String> _togglingNames = {};

  Future<void> _toggle(Map<String, dynamic> item) async {
    final name = item['methodology'] as String;
    if (_togglingNames.contains(name)) return;
    final next = !(item['implemented'] as bool? ?? false);
    setState(() {
      item['implemented'] = next;
      _togglingNames.add(name);
    });
    try {
      await widget.repo.setMethodology(methodology: name, date: widget.dateStr, implemented: next);
    } catch (e) {
      if (mounted) {
        setState(() => item['implemented'] = !next);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _togglingNames.remove(name));
    }
  }

  Future<void> _editRemarks(Map<String, dynamic> item) async {
    final ctrl = TextEditingController(text: item['remarks'] as String? ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item['methodology'] as String),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Add remarks...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
    if (saved != null) {
      final previous = item['remarks'] as String?;
      setState(() => item['remarks'] = saved);
      try {
        await widget.repo.setMethodology(methodology: item['methodology'] as String, date: widget.dateStr, remarks: saved);
      } catch (e) {
        if (mounted) {
          setState(() => item['remarks'] = previous);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      itemCount: widget.items.length,
      itemBuilder: (context, i) {
        final item = widget.items[i];
        final implemented = item['implemented'] as bool? ?? false;
        final evidenceCount = item['evidenceCount'] as int? ?? 0;
        final aiScore = item['aiScore'] as int?;
        final aiMaxScore = item['aiMaxScore'] as int?;
        final toggling = _togglingNames.contains(item['methodology']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item['methodology'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary))),
                    if (toggling)
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    else
                      Switch(value: implemented, activeThumbColor: AppColors.saffron500, onChanged: (_) => _toggle(item)),
                  ],
                ),
                Row(
                  children: [
                    if (evidenceCount > 0) _MiniBadge(label: '$evidenceCount evidence', color: AppColors.saffron600),
                    if (aiScore != null) ...[const SizedBox(width: 6), _MiniBadge(label: 'AI $aiScore/$aiMaxScore', color: const Color(0xFF6366F1))],
                    const Spacer(),
                    TextButton(onPressed: () => _editRemarks(item), child: Text((item['remarks'] as String?)?.isNotEmpty == true ? 'Edit remarks' : 'Add remarks', style: const TextStyle(fontSize: 11))),
                  ],
                ),
                if ((item['remarks'] as String?)?.isNotEmpty == true)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(item['remarks'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary, fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
