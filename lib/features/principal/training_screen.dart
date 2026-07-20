import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import '../videos/video_screen.dart';
import 'principal_repository.dart';

/// Read-only view of the school's training sessions, certifications and
/// shared training videos — Principals monitor but don't manage training.
class PrincipalTrainingScreen extends StatefulWidget {
  const PrincipalTrainingScreen({super.key});

  @override
  State<PrincipalTrainingScreen> createState() => _PrincipalTrainingScreenState();
}

class _PrincipalTrainingScreenState extends State<PrincipalTrainingScreen> with SingleTickerProviderStateMixin {
  final _repo = PrincipalRepository();
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AppShell(
      title: 'Training',
      showAiFab: false,
      body: AsyncScreen<List<dynamic>>(
        loader: () => Future.wait([_repo.getTrainingSessions(), _repo.getCertifications()]),
        builder: (context, results, refresh) {
          final sessions = (results[0] as List).cast<Map<String, dynamic>>();
          final certs = (results[1] as List).cast<Map<String, dynamic>>();
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.saffron600,
                unselectedLabelColor: s.textMuted,
                indicatorColor: AppColors.saffron500,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                tabs: const [Tab(text: 'Sessions'), Tab(text: 'Certifications'), Tab(text: 'Videos')],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    sessions.isEmpty
                        ? const EmptyView(title: 'No training sessions yet', icon: Icons.book_outlined)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                            itemCount: sessions.length,
                            itemBuilder: (context, i) {
                              final sess = sessions[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SectionCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(sess['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                            Text('${sess['trainerName']} · ${sess['date']} · ${sess['mode']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Text('${sess['attendedCount']}/${sess['attendeeCount']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)),
                                    ],
                                  ),
                                ),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                            },
                          ),
                    certs.isEmpty
                        ? const EmptyView(title: 'No certifications issued yet', icon: Icons.workspace_premium_outlined)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                            itemCount: certs.length,
                            itemBuilder: (context, i) {
                              final c = certs[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SectionCard(
                                  child: Row(
                                    children: [
                                      CircleAvatar(radius: 16, backgroundColor: AppColors.saffron100, child: Text((c['teacherName'] as String).isNotEmpty ? (c['teacherName'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.saffron700, fontWeight: FontWeight.w800, fontSize: 12))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c['teacherName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                            Text(c['topic'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                                          ],
                                        ),
                                      ),
                                      if (c['postTestScore'] != null) Text('${c['postTestScore']}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.success)),
                                    ],
                                  ),
                                ),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                            },
                          ),
                    const VideoResourcesScreen(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
