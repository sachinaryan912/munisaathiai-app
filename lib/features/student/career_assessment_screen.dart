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

class CareerAssessmentScreen extends StatelessWidget {
  const CareerAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'IPDS Career Assessment',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getCareerAssessments,
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
  Future<void> _openForm() async {
    final interestsCtrl = TextEditingController();
    final strengthsCtrl = TextEditingController();
    final wishlistCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
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
                    Text('Discover Your Path', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Vidya will suggest a few directions based on what you share.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'What are you interested in?', controller: interestsCtrl, maxLines: 3, hint: 'Subjects, hobbies, things you enjoy...'),
                    const SizedBox(height: 12),
                    AppTextField(label: 'What are you good at?', controller: strengthsCtrl, maxLines: 3),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Dream career (optional)', controller: wishlistCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Family background (optional)', controller: familyCtrl, maxLines: 2),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Get Suggestions',
                      icon: Icons.auto_awesome,
                      loading: submitting,
                      onPressed: () async {
                        if (interestsCtrl.text.trim().isEmpty || strengthsCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please share your interests and strengths.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.submitCareerAssessment(
                            interests: interestsCtrl.text.trim(),
                            strengths: strengthsCtrl.text.trim(),
                            wishlist: wishlistCtrl.text.trim().isEmpty ? null : wishlistCtrl.text.trim(),
                            familyBackground: familyCtrl.text.trim().isEmpty ? null : familyCtrl.text.trim(),
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No assessments yet', subtitle: 'Discover directions that suit your passions and strengths.', icon: LucideIcons.compass)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(LucideIcons.sparkles, size: 14, color: AppColors.saffron600),
                            const SizedBox(width: 6),
                            Text(e['date'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textMuted)),
                          ]),
                          const SizedBox(height: 8),
                          Text(e['aiSuggestion'] as String, style: TextStyle(fontSize: 12.5, color: s.textSecondary, height: 1.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'new_career_assessment', backgroundColor: AppColors.saffron500, onPressed: _openForm, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
