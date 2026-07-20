import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

class TeacherReflectionScreen extends StatelessWidget {
  const TeacherReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    final weekStart = _mondayOf(DateTime.now());
    final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);
    return AppShell(
      title: 'Weekly Reflection',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: () async {
          final results = await Future.wait([repo.getReflection(weekStartStr), repo.getReflections()]);
          return {
            'content': (results[0] as Map<String, dynamic>)['content'] as String? ?? '',
            'history': (results[1] as List<Map<String, dynamic>>).where((r) => r['weekStartDate'] != weekStartStr).toList(),
          };
        },
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: GenericSkeleton(blockHeights: [220, 90, 90]),
        ),
        builder: (context, data, refresh) => _Body(
          repo: repo,
          weekStartStr: weekStartStr,
          initialContent: data['content'] as String,
          history: (data['history'] as List).cast<Map<String, dynamic>>(),
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final TeacherRepository repo;
  final String weekStartStr;
  final String initialContent;
  final List<Map<String, dynamic>> history;
  const _Body({required this.repo, required this.weekStartStr, required this.initialContent, required this.history});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _contentCtrl = TextEditingController(text: widget.initialContent);
  bool _saving = false;
  String? _savedMsg;
  String? _saveError;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _savedMsg = null;
      _saveError = null;
    });
    try {
      await widget.repo.saveReflection(weekStartDate: widget.weekStartStr, content: _contentCtrl.text.trim());
      setState(() => _savedMsg = 'Reflection saved!');
    } catch (e) {
      setState(() => _saveError = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatWeek(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final end = d.add(const Duration(days: 6));
    return '${DateFormat('d MMM').format(d)} – ${DateFormat('d MMM yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Icon(LucideIcons.notebookPen, size: 17, color: AppColors.saffron500),
                const SizedBox(width: 8),
                Expanded(child: Text('This Week — ${_formatWeek(widget.weekStartStr)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary))),
              ]),
              const SizedBox(height: 4),
              Text('Reflect on what worked and what needs attention this week.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
              const SizedBox(height: 14),
              TextField(
                controller: _contentCtrl,
                maxLines: 8,
                decoration: const InputDecoration(hintText: 'What went well this week? What challenges did you face? What will you try next week?'),
              ),
              if (_savedMsg != null) ...[const SizedBox(height: 8), Text(_savedMsg!, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700))],
              if (_saveError != null) ...[const SizedBox(height: 8), Text(_saveError!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700))],
              const SizedBox(height: 14),
              GradientButton(label: 'Save Reflection', icon: Icons.check_rounded, loading: _saving, onPressed: _save, height: 46),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Past Reflections', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (widget.history.isEmpty)
          const EmptyView(title: 'No past reflections yet', icon: LucideIcons.notebookPen)
        else
          ...widget.history.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatWeek(entry.value['weekStartDate'] as String), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary)),
                      const SizedBox(height: 6),
                      Text(entry.value['content'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.5)),
                    ],
                  ),
                ),
              ).animate(delay: (entry.key * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic)),
      ],
    );
  }
}
