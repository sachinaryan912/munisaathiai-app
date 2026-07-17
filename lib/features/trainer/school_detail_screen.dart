import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/section_card.dart';
import 'trainer_repository.dart';
import 'widgets/school_status.dart';

const _statusColors = {
  'Active': Color(0xFF10B981), 'Needs Support': Color(0xFFF59E0B), 'Inactive': Color(0xFFEF4444),
};

class SchoolDetailScreen extends StatelessWidget {
  final Map<String, dynamic> school;
  const SchoolDetailScreen({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    final schoolId = school['id'] as int;
    return Scaffold(
      appBar: AppBar(title: Text(school['name'] as String)),
      body: AsyncScreen<List<dynamic>>(
        loader: () => Future.wait([repo.getMethodology(schoolId: schoolId), repo.getTeachers(schoolId: schoolId)]),
        builder: (context, results, refresh) {
          final methodology = (results[0] as List).cast<Map<String, dynamic>>();
          final teachers = (results[1] as List).cast<Map<String, dynamic>>();
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
                          Text('${school['district']} · ${school['phase']}', style: TextStyle(fontSize: 12, color: s.textMuted)),
                          const SizedBox(height: 6),
                          Text('${school['teacherCount']} teachers · ${school['studentCount']} students · ${school['classCount']} classes', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                          if (school['lastVisit'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Last visit: ${school['lastVisit']}', style: TextStyle(fontSize: 11, color: s.textMuted))),
                        ],
                      ),
                    ),
                    SchoolStatusBadge(mii: school['miiScore'] as int? ?? 0),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Methodology Scores', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  children: methodology.map((m) {
                    final score = m['score'] as int? ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(m['name'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: const AlwaysStoppedAnimation(AppColors.saffron400)))),
                          const SizedBox(width: 8),
                          Text('$score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: s.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
              Text('Teachers', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: teachers.map((t) {
                    final status = t['status'] as String? ?? 'Active';
                    final color = _statusColors[status] ?? s.textMuted;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: CircleAvatar(radius: 16, backgroundColor: AppColors.roleColor('TRAINER'), child: Text((t['name'] as String).isNotEmpty ? (t['name'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                      title: Text(t['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                      subtitle: Text('Score ${t['score']} · Evidence ${t['evidenceCount']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color))),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
