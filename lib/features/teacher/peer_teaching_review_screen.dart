import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

class TeacherPeerTeachingReviewScreen extends StatelessWidget {
  const TeacherPeerTeachingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: 'Peer Teaching Review',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getPeerTeachingForReview,
        builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Future<void> _openReview(Map<String, dynamic> log) async {
    final feedbackCtrl = TextEditingController(text: log['teacherFeedback'] as String? ?? '');
    int stars = (log['stars'] as int?) ?? 5;
    var submitting = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('${log['studentName']} — ${log['topic']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    Text('Taught ${log['studentCount']} friends on ${log['date']}', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    if ((log['reflection'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Text('"${log['reflection']}"', style: TextStyle(fontSize: 12, color: s.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 16),
                    Text('Stars', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < stars;
                        return IconButton(
                          onPressed: () => setSheetState(() => stars = i + 1),
                          icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.saffron500, size: 28),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(label: 'Feedback', controller: feedbackCtrl, maxLines: 3, hint: 'Tell them how the session went...'),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Submit Review',
                      loading: submitting,
                      onPressed: () async {
                        if (feedbackCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please add some feedback.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.reviewPeerTeaching(id: log['id'] as int, feedback: feedbackCtrl.text.trim(), stars: stars);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await widget.refresh();
                        } catch (e) {
                          setSheetState(() {
                            submitting = false;
                            error = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    if (widget.list.isEmpty) {
      return const EmptyView(title: 'No peer teaching sessions logged yet', subtitle: 'Your students\' peer-teaching logs will show up here for review.', icon: LucideIcons.graduationCap);
    }
    final pending = widget.list.where((l) => l['teacherFeedback'] == null).toList();
    final reviewed = widget.list.where((l) => l['teacherFeedback'] != null).toList();
    final ordered = [...pending, ...reviewed];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: ordered.length,
      itemBuilder: (context, i) {
        final log = ordered[i];
        final isPending = log['teacherFeedback'] == null;
        final stars = log['stars'] as int?;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SectionCard(
            onTap: () => _openReview(log),
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
                      Text('${log['studentName']} · ${log['topic']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                      const SizedBox(height: 2),
                      Text('${log['studentCount']} friends · ${log['date']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                      const SizedBox(height: 6),
                      if (isPending)
                        Row(children: [
                          const Icon(LucideIcons.clock, size: 11, color: AppColors.warning),
                          const SizedBox(width: 4),
                          const Text('Tap to review', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.warning)),
                        ])
                      else
                        Row(children: [
                          if (stars != null) ...List.generate(stars, (_) => const Icon(Icons.star_rounded, size: 13, color: AppColors.saffron500)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(log['teacherFeedback'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted), overflow: TextOverflow.ellipsis)),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
