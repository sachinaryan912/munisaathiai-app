import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';
import 'training_screen.dart';

const _statusColors = {
  'Active': Color(0xFF10B981),
  'Needs Support': Color(0xFFF59E0B),
  'Inactive': Color(0xFFEF4444),
};

class PrincipalTeachersScreen extends StatefulWidget {
  const PrincipalTeachersScreen({super.key});

  @override
  State<PrincipalTeachersScreen> createState() => _PrincipalTeachersScreenState();
}

class _PrincipalTeachersScreenState extends State<PrincipalTeachersScreen> {
  final _repo = PrincipalRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Teachers',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bookOpen),
          tooltip: 'Training',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrincipalTrainingScreen())),
        ),
      ],
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: _repo.getTeachers,
        builder: (context, allTeachers, refresh) {
          final s = context.surface;
          if (allTeachers.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No teachers found', icon: LucideIcons.users)]);
          }
          final q = _query.trim().toLowerCase();
          final teachers = q.isEmpty
              ? allTeachers
              : allTeachers.where((t) {
                  return (t['name'] as String? ?? '').toLowerCase().contains(q) ||
                      (t['className'] as String? ?? '').toLowerCase().contains(q) ||
                      (t['status'] as String? ?? '').toLowerCase().contains(q);
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ListSearchField(controller: _searchCtrl, hint: 'Search by name, class or status', onChanged: (v) => setState(() => _query = v)),
              ),
              Expanded(
                child: teachers.isEmpty
                    ? const EmptyView(title: 'No teachers match your search', icon: LucideIcons.users)
                    : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: teachers.length,
            itemBuilder: (context, i) {
              final t = teachers[i];
              final status = t['status'] as String? ?? 'Active';
              final color = _statusColors[status] ?? s.textMuted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: AppColors.roleColor('PRINCIPAL'), child: Text((t['name'] as String).isNotEmpty ? (t['name'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                            const SizedBox(height: 3),
                            Text('${t['className'] ?? '—'} ${t['section'] ?? ''} · Score ${t['score']} · ${t['methodsActiveToday']} methods today', style: TextStyle(fontSize: 11, color: s.textMuted)),
                          ],
                        ),
                      ),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
                    ],
                  ),
                ),
              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            },
          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
