import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';
import 'widgets/upload_assignment_sheet.dart';

const _gradeColors = {
  'A+': Color(0xFF059669),
  'A': Color(0xFF10B981),
  'B+': Color(0xFF3B82F6),
  'B': Color(0xFF6366F1),
  'C': Color(0xFFF59E0B),
  'D': Color(0xFFEF4444),
};

class StudentAssignmentsScreen extends StatelessWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Assignments',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getAssignments,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [150, 150, 150]),
        builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _openingId;

  void _openUpload() => showUploadAssignmentSheet(context, widget.repo, widget.refresh);

  Future<void> _viewAssignment(int id, String fileName) async {
    setState(() => _openingId = id);
    try {
      final bytes = await widget.repo.getAssignmentFile(id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.list
        : widget.list.where((a) {
            return (a['title'] as String? ?? '').toLowerCase().contains(q) ||
                (a['subject'] as String? ?? '').toLowerCase().contains(q) ||
                (a['grade'] as String? ?? '').toLowerCase().contains(q);
          }).toList();
    return Stack(
      children: [
        Column(
          children: [
            if (widget.list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListSearchField(controller: _searchCtrl, hint: 'Search by title, subject or grade', onChanged: (v) => setState(() => _query = v)),
              ),
            Expanded(
              child: list.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      EmptyView(
                        title: widget.list.isEmpty ? 'No assignments submitted yet' : 'No assignments match your search',
                        subtitle: widget.list.isEmpty ? 'Tap the + button to submit your first one.' : null,
                        icon: LucideIcons.fileCheck,
                      ),
                    ])
                  : AnimationLimiter(
                child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final a = list[i];
                  final grade = a['grade'] as String? ?? '';
                  final color = _gradeColors[grade] ?? s.textMuted;
                  final strengths = (a['strengths'] as String? ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
                  final improvements = (a['improvements'] as String? ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
                  final id = a['id'] as int;
                  final opening = _openingId == id;
                  final hasFile = a['storagePath'] != null;
                  final card = Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      onTap: !hasFile || opening ? null : () => _viewAssignment(id, a['fileName'] as String? ?? 'assignment'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                                child: opening
                                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                                    : Text(grade, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                    Text('${a['subject']} · ${a['marks']}/100', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                                  ],
                                ),
                              ),
                              if (hasFile) Icon(LucideIcons.fileText, size: 15, color: s.textMuted),
                            ],
                          ),
                          if ((a['feedback'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(a['feedback'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.5)),
                          ],
                          if (strengths.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...strengths.map((line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.circleCheck, size: 13, color: AppColors.success), const SizedBox(width: 6), Expanded(child: Text(line.trim(), style: TextStyle(fontSize: 11.5, color: s.textSecondary)))]),
                                )),
                          ],
                          if (improvements.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...improvements.map((line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(LucideIcons.arrowUpRight, size: 13, color: AppColors.warning), const SizedBox(width: 6), Expanded(child: Text(line.trim(), style: TextStyle(fontSize: 11.5, color: s.textSecondary)))]),
                                )),
                          ],
                        ],
                      ),
                    ),
                  );
                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 380),
                    child: SlideAnimation(verticalOffset: 24, curve: Curves.easeOutCubic, child: FadeInAnimation(child: card)),
                  );
                },
              ),
            ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(heroTag: 'upload_assignment', backgroundColor: AppColors.saffron500, onPressed: _openUpload, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }
}
