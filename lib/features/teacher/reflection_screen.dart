import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

class TeacherReflectionScreen extends StatefulWidget {
  const TeacherReflectionScreen({super.key});

  @override
  State<TeacherReflectionScreen> createState() => _TeacherReflectionScreenState();
}

class _TeacherReflectionScreenState extends State<TeacherReflectionScreen> {
  final _repo = TeacherRepository();
  final _contentCtrl = TextEditingController();
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;
  String? _savedMsg;

  late final DateTime _weekStart = _mondayOf(DateTime.now());
  String get _weekStartStr => DateFormat('yyyy-MM-dd').format(_weekStart);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_repo.getReflection(_weekStartStr), _repo.getReflections()]);
      _contentCtrl.text = (results[0] as Map<String, dynamic>)['content'] as String? ?? '';
      _history = (results[1] as List<Map<String, dynamic>>).where((r) => r['weekStartDate'] != _weekStartStr).toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _savedMsg = null;
    });
    try {
      await _repo.saveReflection(weekStartDate: _weekStartStr, content: _contentCtrl.text.trim());
      setState(() => _savedMsg = 'Reflection saved!');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
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
    return AppShell(
      title: 'Weekly Reflection',
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            const Icon(LucideIcons.notebookPen, size: 17, color: AppColors.saffron500),
                            const SizedBox(width: 8),
                            Expanded(child: Text('This Week — ${_formatWeek(_weekStartStr)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary))),
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
                          const SizedBox(height: 14),
                          GradientButton(label: 'Save Reflection', icon: Icons.check_rounded, loading: _saving, onPressed: _save, height: 46),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Past Reflections', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
                    const SizedBox(height: 10),
                    if (_history.isEmpty)
                      const EmptyView(title: 'No past reflections yet', icon: LucideIcons.notebookPen)
                    else
                      ..._history.asMap().entries.map((entry) => Padding(
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
                ),
    );
  }
}
