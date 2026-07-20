import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

/// "Self Competitor" — students log how much faster/better they did a topic vs. last time.
class ProgressChartScreen extends StatelessWidget {
  const ProgressChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Progress Chart',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getProgressChart,
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
  Future<void> _openLog() async {
    final topicCtrl = TextEditingController();
    final prevCtrl = TextEditingController();
    final currCtrl = TextEditingController();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Log Self-Competition', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Compete with your own previous performance, not others.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Topic', controller: topicCtrl, hint: 'e.g. Multiplication tables'),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Previous time (minutes)', controller: prevCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Current time (minutes)', controller: currCtrl, keyboardType: TextInputType.number),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Save',
                    loading: submitting,
                    onPressed: () async {
                      final prev = int.tryParse(prevCtrl.text.trim());
                      final curr = int.tryParse(currCtrl.text.trim());
                      if (topicCtrl.text.trim().isEmpty || prev == null || curr == null) {
                        setSheetState(() => error = 'Please fill all fields with valid numbers.');
                        return;
                      }
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await widget.repo.logProgressChart(topic: topicCtrl.text.trim(), previousTime: prev, currentTime: curr);
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No progress logged yet', subtitle: 'Beat your own previous time on a topic and log it here.', icon: LucideIcons.trendingUp)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  final prev = e['previousTime'] as int;
                  final curr = e['currentTime'] as int;
                  final improved = curr < prev;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: (improved ? AppColors.success : AppColors.warning).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                            child: Icon(improved ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 18, color: improved ? AppColors.success : AppColors.warning),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${e['date']} · $prev min → $curr min', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_progress_chart', backgroundColor: AppColors.saffron500, onPressed: _openLog, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
