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

class LifeApplicationScreen extends StatelessWidget {
  const LifeApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Mai Shikshit Hokar',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getLifeApplicationLogs,
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
    final healthCtrl = TextEditingController();
    final prosperityCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final participationCtrl = TextEditingController();
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
                    Text('Mai Shikshit Hokar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Organize what you learned across 4 levels of life.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Chapter / Topic', controller: topicCtrl),
                    const SizedBox(height: 12),
                    AppTextField(label: 'To stay healthy', controller: healthCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    AppTextField(label: 'To live with prosperity', controller: prosperityCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    AppTextField(label: 'To feel fulfilled in relations', controller: relationCtrl, maxLines: 2),
                    const SizedBox(height: 12),
                    AppTextField(label: 'To participate in order', controller: participationCtrl, maxLines: 2),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        if (topicCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter the topic.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.logLifeApplication(
                            topic: topicCtrl.text.trim(),
                            healthNote: healthCtrl.text.trim().isEmpty ? null : healthCtrl.text.trim(),
                            prosperityNote: prosperityCtrl.text.trim().isEmpty ? null : prosperityCtrl.text.trim(),
                            relationNote: relationCtrl.text.trim().isEmpty ? null : relationCtrl.text.trim(),
                            participationNote: participationCtrl.text.trim().isEmpty ? null : participationCtrl.text.trim(),
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
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No entries yet', subtitle: 'Apply a chapter\'s learning to your life.', icon: LucideIcons.heartHandshake)])
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
                          Text(e['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                          Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                          if ((e['healthNote'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 6), Text('Health: ${e['healthNote']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                          if ((e['prosperityNote'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 3), Text('Prosperity: ${e['prosperityNote']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                          if ((e['relationNote'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 3), Text('Relations: ${e['relationNote']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                          if ((e['participationNote'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 3), Text('Order: ${e['participationNote']}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))],
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'log_life_application', backgroundColor: AppColors.saffron500, onPressed: _openLog, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
