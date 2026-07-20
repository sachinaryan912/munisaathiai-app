import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';
import 'widgets/log_peer_teaching_sheet.dart';

class StudentPeerTeachingScreen extends StatelessWidget {
  const StudentPeerTeachingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Peer Teaching',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getPeerTeaching,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [100, 100, 100]),
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
  void _openLog() => showLogPeerTeachingSheet(context, widget.repo, widget.refresh);

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Stack(
      children: [
        widget.list.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No peer teaching logged yet', subtitle: 'Teach a friend and log it here to earn stars!', icon: LucideIcons.graduationCap)])
            : AnimationLimiter(
                child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final t = widget.list[i];
                  final stars = t['stars'] as int?;
                  final card = Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(13)),
                            child: const Icon(LucideIcons.graduationCap, size: 18, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${t['studentCount']} friends · ${t['date']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                if ((t['reflection'] as String?)?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 6),
                                  Text('"${t['reflection']}"', style: TextStyle(fontSize: 11.5, color: s.textSecondary, fontStyle: FontStyle.italic)),
                                ],
                                if ((t['teacherFeedback'] as String?)?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(LucideIcons.userCheck, size: 10, color: s.textMuted),
                                    const SizedBox(width: 4),
                                    Text('Teacher feedback', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: s.textMuted, letterSpacing: 0.3)),
                                  ]),
                                  const SizedBox(height: 3),
                                  Text(t['teacherFeedback'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary, fontStyle: FontStyle.italic)),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(LucideIcons.clock, size: 10, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text('Pending teacher review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.warning, letterSpacing: 0.3)),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                          if (stars != null)
                            Row(children: List.generate(stars, (_) => const Icon(Icons.star_rounded, size: 15, color: AppColors.saffron500))),
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
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(heroTag: 'log_peer_teaching', backgroundColor: AppColors.saffron500, onPressed: _openLog, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }
}
