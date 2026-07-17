import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/generic_skeleton.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

const _categories = ['general', 'buddy', 'study', 'teacher'];

class StudentFeedbackScreen extends StatelessWidget {
  const StudentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Feedback',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getFeedback,
        loadingBuilder: (context) => const GenericSkeleton(blockHeights: [280, 80, 80]),
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
  final _contentCtrl = TextEditingController();
  String _category = 'general';
  int _rating = 5;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.repo.submitFeedback(category: _category, content: _contentCtrl.text.trim(), rating: _rating);
      _contentCtrl.clear();
      setState(() => _rating = 5);
      await widget.refresh();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;

    final items = <Widget>[
      SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [const Icon(LucideIcons.heart, size: 17, color: AppColors.saffron500), const SizedBox(width: 8), Text('Share your feedback', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: s.textPrimary))]),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: _categories.map((c) {
                final active = c == _category;
                return ChoiceChip(
                  label: Text(c[0].toUpperCase() + c.substring(1)),
                  selected: active,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.saffron100,
                  labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? AppColors.saffron700 : s.textSecondary),
                  backgroundColor: s.border.withValues(alpha: 0.4),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.saffron500, size: 28),
                );
              }),
            ),
            AppTextField(label: 'Your thoughts', controller: _contentCtrl, maxLines: 4, hint: 'Tell us what you think...'),
            const SizedBox(height: 16),
            GradientButton(label: 'Send Feedback', icon: Icons.send_rounded, loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Feedback History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          const SizedBox(height: 10),
          if (widget.list.isEmpty)
            const SectionCard(child: EmptyView(title: 'No feedback sent yet', icon: LucideIcons.heart))
          else
            Column(
              children: widget.list.map((f) {
                final rating = f['rating'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text((f['category'] as String).toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.saffron600, letterSpacing: 0.4)),
                                const SizedBox(width: 8),
                                Text(timeAgo(DateTime.tryParse(f['createdAt'] as String? ?? '')), style: TextStyle(fontSize: 10, color: s.textMuted)),
                              ]),
                              const SizedBox(height: 4),
                              Text(f['content'] as String, style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.4)),
                            ],
                          ),
                        ),
                        Row(children: List.generate(rating, (_) => const Icon(Icons.star_rounded, size: 13, color: AppColors.saffron500))),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 22),
        itemBuilder: (context, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(verticalOffset: 26, curve: Curves.easeOutCubic, child: FadeInAnimation(child: items[i])),
        ),
      ),
    );
  }
}
