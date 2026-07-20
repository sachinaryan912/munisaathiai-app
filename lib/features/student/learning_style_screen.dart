import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

const _dimensions = [
  ('kinesthetic', 'Kinesthetic', 'I learn best by moving, building, and doing hands-on activities.'),
  ('audio', 'Audio', 'I learn best by listening — discussions, lectures, audio.'),
  ('video', 'Video', 'I learn best by watching — diagrams, videos, demonstrations.'),
  ('linguistic', 'Linguistic', 'I learn best by reading and writing words.'),
  ('musical', 'Musical', 'I learn best through rhythm, songs, and patterns.'),
];

class LearningStyleScreen extends StatelessWidget {
  const LearningStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Learning Style',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getLearningStyleResults,
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
  Future<void> _openQuiz() async {
    final scores = {for (final d in _dimensions) d.$1: 5.0};
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
                    Text('Rate yourself 0–10', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 12),
                    for (final d in _dimensions) ...[
                      Text(d.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.textPrimary)),
                      Text(d.$3, style: TextStyle(fontSize: 11, color: s.textMuted)),
                      Slider(
                        value: scores[d.$1]!,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: AppColors.saffron500,
                        label: scores[d.$1]!.round().toString(),
                        onChanged: (v) => setSheetState(() => scores[d.$1] = v),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (error != null) ...[Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)), const SizedBox(height: 10)],
                    GradientButton(
                      label: 'See My Result',
                      loading: submitting,
                      onPressed: () async {
                        setSheetState(() => submitting = true);
                        try {
                          await widget.repo.submitLearningStyleQuiz(
                            kinesthetic: scores['kinesthetic']!.round(),
                            audio: scores['audio']!.round(),
                            video: scores['video']!.round(),
                            linguistic: scores['linguistic']!.round(),
                            musical: scores['musical']!.round(),
                          );
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
    return Stack(
      children: [
        widget.list.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No results yet', subtitle: 'Take the quiz to find your best way to learn.', icon: LucideIcons.lightbulb)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Row(
                        children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)), child: const Icon(LucideIcons.lightbulb, size: 18, color: Color(0xFFEC4899))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dominant: ${e['dominantStyle']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'take_learning_style_quiz', backgroundColor: AppColors.saffron500, onPressed: _openQuiz, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
