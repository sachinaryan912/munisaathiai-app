import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';
import 'widgets/log_buddy_session_sheet.dart';

class StudentBuddyScreen extends StatelessWidget {
  const StudentBuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'My Group',
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getBuddy,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [110, 54, 140, 220]),
        builder: (context, data, refresh) => _Body(data: data, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> data;
  final StudentRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.data, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final Set<int> _togglingIds = {};

  void _openLogSession() => showLogBuddySessionSheet(context, widget.repo, widget.refresh);

  Future<void> _toggleActivity(int id) async {
    if (_togglingIds.contains(id)) return;
    setState(() => _togglingIds.add(id));
    try {
      await widget.repo.toggleActivity(id);
      await widget.refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _togglingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final data = widget.data;
    final groupmates = (data['groupmates'] as List? ?? []).cast<Map<String, dynamic>>();
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final ratedCount = data['ratedCount'] as num? ?? 0;
    final sessionsCount = data['sessionsCount'] as int? ?? 0;
    final sessions = (data['sessions'] as List? ?? []).cast<Map<String, dynamic>>();
    final activities = (data['activities'] as List? ?? []).cast<Map<String, dynamic>>();

    final sections = <Widget>[
      SectionCard(
        padding: const EdgeInsets.all(20),
        child: groupmates.isEmpty
            ? const EmptyView(title: 'No group assigned yet', subtitle: 'Ask your teacher to add you to a buddy/GRS group.', icon: LucideIcons.userPlus)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: groupmates.map((g) {
                      final name = g['name'] as String;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.roleColor('STUDENT'),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.saffron500, size: 15),
                      const SizedBox(width: 2),
                      Text('${rating.toStringAsFixed(1)} ($ratedCount ratings) · $sessionsCount sessions', style: TextStyle(fontSize: 11, color: s.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
      ),
      GradientButton(label: 'Log Buddy Session', icon: Icons.add_rounded, onPressed: _openLogSession),
      if (activities.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buddy Activities', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
            const SizedBox(height: 10),
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: activities.map((a) {
                  final done = a['done'] as bool? ?? false;
                  final id = a['id'] as int;
                  final toggling = _togglingIds.contains(id);
                  return CheckboxListTile(
                    value: done,
                    onChanged: toggling ? null : (_) => _toggleActivity(id),
                    activeColor: AppColors.saffron500,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    secondary: toggling ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                    title: Text(a['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, decoration: done ? TextDecoration.lineThrough : null, color: done ? s.textMuted : s.textPrimary)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            const SectionCard(child: EmptyView(title: 'No sessions logged yet', icon: LucideIcons.users))
          else
            Column(
              children: sessions.map((sess) {
                final helped = sess['helped'] as bool? ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.users, size: 16, color: AppColors.saffron600),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sess['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                              const SizedBox(height: 2),
                              Text('${sess['duration']} min · ${sess['date']} · ${helped ? "You helped" : "Buddy helped you"}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              if (sess['peerReflection'] != null && (sess['peerReflection'] as String).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('"${sess['peerReflection']}"', style: TextStyle(fontSize: 11.5, color: s.textSecondary, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                        if (sess['buddyRating'] != null)
                          Row(children: [Text('${sess['buddyRating']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)), const Icon(Icons.star_rounded, size: 14, color: AppColors.saffron500)]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ];

    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(verticalOffset: 26, curve: Curves.easeOutCubic, child: FadeInAnimation(child: sections[i])),
        ),
      ),
    );
  }
}
