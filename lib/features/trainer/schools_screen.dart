import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'school_detail_screen.dart';
import 'trainer_repository.dart';
import 'widgets/school_status.dart';

class TrainerSchoolsScreen extends StatelessWidget {
  const TrainerSchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return AppShell(
      title: 'My Schools',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getSchools,
        builder: (context, schools, refresh) {
          final s = context.surface;
          if (schools.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No schools assigned yet', icon: LucideIcons.school)]);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: schools.length,
            itemBuilder: (context, i) {
              final sc = schools[i];
              final trend = sc['trend'] as int? ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchoolDetailScreen(school: sc))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sc['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                            const SizedBox(height: 3),
                            Text('${sc['district']} · ${sc['phase']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(trend >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 12, color: trend >= 0 ? AppColors.success : AppColors.danger),
                              const SizedBox(width: 3),
                              Text('${trend >= 0 ? '+' : ''}$trend this month', style: TextStyle(fontSize: 10.5, color: trend >= 0 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w700)),
                              Text(' · ${sc['teacherCount']} teachers · ${sc['studentCount']} students', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                            ]),
                          ],
                        ),
                      ),
                      SchoolStatusBadge(mii: sc['miiScore'] as int? ?? 0),
                    ],
                  ),
                ),
              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
    );
  }
}
