import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'parent_repository.dart';
import 'selected_child_provider.dart';
import 'widgets/child_switcher.dart';
import 'widgets/link_child_panel.dart';

const _categories = [
  {'value': 'home-learning', 'label': 'Home Learning'},
  {'value': 'progress', 'label': 'Progress'},
  {'value': 'general', 'label': 'General'},
];

class ParentActivitiesScreen extends StatefulWidget {
  const ParentActivitiesScreen({super.key});

  @override
  State<ParentActivitiesScreen> createState() => _ParentActivitiesScreenState();
}

class _ParentActivitiesScreenState extends State<ParentActivitiesScreen> {
  final _repo = ParentRepository();
  Map<String, dynamic>? _homeLearning;
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  String? _error;
  int? _lastChildId;
  bool _childrenLoaded = false;

  Future<void> _load(int? childId) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_repo.getHomeLearning(childId), _repo.getFeedback(childId)]);
      _homeLearning = results[0] as Map<String, dynamic>;
      _feedbacks = results[1] as List<Map<String, dynamic>>;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<SelectedChildProvider>();
    if (!childProvider.loading && !_childrenLoaded) {
      _childrenLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(childProvider.selectedChildId));
    }
    if (_childrenLoaded && childProvider.selectedChildId != _lastChildId) {
      _lastChildId = childProvider.selectedChildId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(childProvider.selectedChildId));
    }

    return AppShell(
      title: 'Activities',
      body: childProvider.loading || _loading
          ? const LoadingView(message: 'Loading activities...')
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load(childProvider.selectedChildId))
              : (_homeLearning?['linked'] == false)
                  ? const NotLinkedState(message: 'Link your child to see their activities')
                  : _Body(
                      homeLearning: _homeLearning!,
                      feedbacks: _feedbacks,
                      childId: childProvider.selectedChildId,
                      repo: _repo,
                      onFeedbackSent: () => _load(childProvider.selectedChildId),
                    ),
    );
  }
}

class _Body extends StatefulWidget {
  final Map<String, dynamic> homeLearning;
  final List<Map<String, dynamic>> feedbacks;
  final int? childId;
  final ParentRepository repo;
  final VoidCallback onFeedbackSent;

  const _Body({required this.homeLearning, required this.feedbacks, required this.childId, required this.repo, required this.onFeedbackSent});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _contentCtrl = TextEditingController();
  String _category = 'home-learning';
  int _rating = 5;
  bool _submitting = false;
  String? _formError;

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) {
      setState(() => _formError = 'Please write your feedback before sending');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      await widget.repo.submitFeedback(childId: widget.childId, category: _category, content: _contentCtrl.text.trim(), rating: _rating);
      _contentCtrl.clear();
      setState(() => _rating = 5);
      widget.onFeedbackSent();
    } catch (e) {
      setState(() => _formError = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final thisWeek = (widget.homeLearning['thisWeek'] as List? ?? []).cast<Map<String, dynamic>>();
    final pending = thisWeek.where((a) => a['done'] != true).toList();
    final doneThisWeek = widget.homeLearning['doneThisWeek'] as num? ?? 0;
    final totalThisWeek = widget.homeLearning['totalThisWeek'] as num? ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const ChildSwitcher(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _MiniStat(label: "This Week's Plan", value: '$totalThisWeek', color: AppColors.saffron600, bg: AppColors.saffron50)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: 'Completed', value: '$doneThisWeek', color: const Color(0xFF059669), bg: const Color(0xFFD1FAE5))),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(label: 'Pending', value: '${pending.length}', color: const Color(0xFF4F46E5), bg: const Color(0xFFE0E7FF))),
          ],
        ),
        const SizedBox(height: 22),
        Text('Still To Do This Week', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        Text('Ghar Ek Pathshala activities not yet completed', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
        const SizedBox(height: 10),
        pending.isEmpty
            ? SectionCard(child: Center(child: Padding(padding: const EdgeInsets.all(12), child: Text('🎉 All caught up for this week!', style: TextStyle(color: const Color(0xFF059669), fontWeight: FontWeight.w700)))))
            : SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: pending.map((a) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(11)), child: const Icon(LucideIcons.clock, size: 15, color: Color(0xFF4F46E5))),
                        title: Text(a['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                      )).toList(),
                ),
              ),
        const SizedBox(height: 22),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [const Icon(LucideIcons.heart, size: 16, color: AppColors.saffron500), const SizedBox(width: 8), Text('Leave Feedback', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary))]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _categories.map((c) {
                  final active = c['value'] == _category;
                  return ChoiceChip(
                    label: Text(c['label']!),
                    selected: active,
                    onSelected: (_) => setState(() => _category = c['value']!),
                    selectedColor: AppColors.saffron500,
                    labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? Colors.white : s.textSecondary),
                    backgroundColor: s.border.withValues(alpha: 0.4),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              AppTextField(label: 'Your feedback', controller: _contentCtrl, maxLines: 3, hint: 'How is your child doing at home?'),
              const SizedBox(height: 8),
              Row(children: List.generate(5, (i) => IconButton(onPressed: () => setState(() => _rating = i + 1), icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.saffron500, size: 24)))),
              if (_formError != null) Text(_formError!, style: const TextStyle(color: AppColors.danger, fontSize: 11.5)),
              const SizedBox(height: 8),
              GradientButton(label: 'Submit Feedback', icon: Icons.send_rounded, loading: _submitting, onPressed: _submit, height: 46),
              if (widget.feedbacks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: s.border),
                const SizedBox(height: 10),
                ...widget.feedbacks.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text((f['category'] as String).toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.saffron600, letterSpacing: 0.4)),
                              const Spacer(),
                              Text(timeAgo(DateTime.tryParse(f['createdAt'] as String? ?? '')), style: TextStyle(fontSize: 10, color: s.textMuted)),
                            ]),
                            const SizedBox(height: 4),
                            Text(f['content'] as String, style: TextStyle(fontSize: 12.5, color: s.textSecondary)),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _MiniStat({required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
